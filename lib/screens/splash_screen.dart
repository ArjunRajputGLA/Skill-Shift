import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../services/auth_service.dart';
import '../main.dart'; // To get AuthWrapper

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isVideoFinished = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/app_loading_animation.mp4')
      ..initialize().then((_) {
        if (mounted) {
          setState(() {}); // Update to show first frame
          _controller.setPlaybackSpeed(2.0); // Speed up the animation
          _controller.play();
          
          // Listen for video completion
          _controller.addListener(_videoListener);
        }
      }).catchError((e) {
        debugPrint('Error loading splash video: $e');
        // Fallback if video fails
        if (mounted) {
          _isVideoFinished = true;
          _checkAndNavigate();
        }
      });
  }

  void _videoListener() {
    if (!_controller.value.isPlaying &&
        _controller.value.position >= _controller.value.duration &&
        !_isVideoFinished) {
      _isVideoFinished = true;
      _checkAndNavigate();
    }
  }

  void _checkAndNavigate() {
    if (_isNavigating || !mounted) return;
    
    // Check if auth is finished
    final authService = context.read<AuthService>();
    if (!authService.isLoading && _isVideoFinished) {
      _isNavigating = true;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AuthWrapper(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Also listen to auth changes in case auth finishes AFTER the video finishes
    final authService = context.watch<AuthService>();
    if (!authService.isLoading && _isVideoFinished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndNavigate();
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: _controller.value.isInitialized
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          : const Center(child: CircularProgressIndicator(color: Colors.black)),
    );
  }
}
