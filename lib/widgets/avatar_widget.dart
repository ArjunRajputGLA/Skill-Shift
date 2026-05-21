import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A unified avatar component that resolves an image from:
///
/// 1. A provided [imageBase64] string (immediate, no network call).
/// 2. A Firestore `users/{userId}` document's `profileImageBase64` field.
/// 3. Initials derived from [name] as a fallback.
class AvatarWidget extends StatelessWidget {
  /// Pre-loaded base64-encoded image data.
  final String? imageBase64;

  /// Display name used for the initials fallback.
  final String name;

  /// Avatar radius (defaults to 20 logical pixels → 40×40 circle).
  final double radius;

  /// When set, the widget fetches `profileImageBase64` from Firestore if
  /// [imageBase64] is not provided.
  final String? userId;

  /// Adds a subtle primary-colored outer glow.
  final bool showGlow;

  /// Optional tap callback.
  final VoidCallback? onTap;

  const AvatarWidget({
    super.key,
    this.imageBase64,
    required this.name,
    this.radius = 20,
    this.userId,
    this.showGlow = false,
    this.onTap,
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  Widget _buildInitials() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.avatarBg,
      child: Text(
        _initials,
        style: TextStyle(
          color: AppColors.avatarFg,
          fontWeight: FontWeight.w600,
          fontSize: radius * 0.85,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildFromBase64(String data) {
    try {
      final bytes = base64Decode(data);
      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(bytes),
        backgroundColor: AppColors.avatarBg,
      );
    } catch (_) {
      return _buildInitials();
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    Widget avatar;

    if (imageBase64 != null && imageBase64!.isNotEmpty) {
      // ── Priority 1: direct base64 ─────────────────────────────────────
      avatar = _buildFromBase64(imageBase64!);
    } else if (userId != null && userId!.isNotEmpty) {
      // ── Priority 2: fetch from Firestore ──────────────────────────────
      avatar = FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircleAvatar(
              radius: radius,
              backgroundColor: AppColors.avatarBg,
              child: SizedBox(
                width: radius,
                height: radius,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.avatarFg,
                ),
              ),
            );
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final base64String = data?['profileImageBase64'] as String?;

          if (base64String != null && base64String.isNotEmpty) {
            return _buildFromBase64(base64String);
          }

          return _buildInitials();
        },
      );
    } else {
      // ── Priority 3: initials fallback ─────────────────────────────────
      avatar = _buildInitials();
    }

    // ── Glow wrapper ──────────────────────────────────────────────────────
    if (showGlow) {
      avatar = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: avatar,
      );
    }

    // ── Tap wrapper ───────────────────────────────────────────────────────
    if (onTap != null) {
      avatar = GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }
}
