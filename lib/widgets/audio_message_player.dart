import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AudioMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final bool isMine;

  const AudioMessagePlayer({
    super.key,
    required this.audioUrl,
    required this.isMine,
  });

  @override
  State<AudioMessagePlayer> createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<AudioMessagePlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) {
        setState(() => _duration = d);
      }
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) {
        setState(() => _position = p);
      }
    });
    // Set the source early to fetch duration
    try {
      if (widget.audioUrl.startsWith('http')) {
        _audioPlayer.setSourceUrl(widget.audioUrl);
      } else {
        _audioPlayer.setSourceBytes(base64Decode(widget.audioUrl));
      }
    } catch (e) {
      // Handle invalid source safely
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      try {
        if (widget.audioUrl.startsWith('http')) {
          await _audioPlayer.play(UrlSource(widget.audioUrl));
        } else {
          await _audioPlayer.play(BytesSource(base64Decode(widget.audioUrl)));
        }
      } catch (e) {
        // Handle play error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final fgColor = widget.isMine 
        ? Colors.white 
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);
        
    final activeColor = widget.isMine ? Colors.white : theme.colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
          color: activeColor,
          iconSize: 36,
          onPressed: _togglePlay,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  activeTrackColor: activeColor,
                  inactiveTrackColor: activeColor.withValues(alpha: 0.3),
                  thumbColor: activeColor,
                ),
                child: Slider(
                  value: _position.inMilliseconds.toDouble(),
                  min: 0,
                  max: _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 100,
                  onChanged: (val) {
                    _audioPlayer.seek(Duration(milliseconds: val.toInt()));
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  _formatDuration(_position.inMilliseconds > 0 ? _position : _duration),
                  style: TextStyle(
                    color: fgColor.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
