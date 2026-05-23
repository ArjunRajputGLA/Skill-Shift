import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'gradient_background.dart';

class SharedVideoController {
  static final SharedVideoController _instance = SharedVideoController._internal();
  factory SharedVideoController() => _instance;
  SharedVideoController._internal();

  VideoPlayerController? controller;
  bool isInitialized = false;
  int _usageCount = 0;

  Future<void> initialize() async {
    _usageCount++;
    if (controller == null) {
      controller = VideoPlayerController.asset('assets/auth.mp4');
      await controller!.initialize();
      controller!.setLooping(true);
      controller!.setVolume(0.0);
      controller!.play();
      isInitialized = true;
    }
  }

  void dispose() {
    _usageCount--;
    if (_usageCount <= 0) {
      controller?.dispose();
      controller = null;
      isInitialized = false;
      _usageCount = 0;
    }
  }
}

class VideoBackground extends StatefulWidget {
  final Widget child;
  final Color accentColor1;
  final Color accentColor2;

  const VideoBackground({
    super.key,
    required this.child,
    required this.accentColor1,
    required this.accentColor2,
  });

  @override
  State<VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<VideoBackground> {
  final SharedVideoController _sharedController = SharedVideoController();

  @override
  void initState() {
    super.initState();
    _sharedController.initialize().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sharedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black, // Fallback color behind everything
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Base gradient layer (forced to expand)
          GradientBackground(
            accentColor1: widget.accentColor1,
            accentColor2: widget.accentColor2,
            child: const SizedBox.expand(),
          ),

          // Shared Video Layer
          if (_sharedController.isInitialized && _sharedController.controller != null)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _sharedController.controller!.value.size.width,
                  height: _sharedController.controller!.value.size.height,
                  child: VideoPlayer(_sharedController.controller!),
                ),
              ),
            ),

          // Dimming Overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.65), // Dim the video heavily so form is readable
            ),
          ),

          // Main Content Layer
          widget.child,
        ],
      ),
    );
  }
}
