import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../models/message_model.dart';

class MessageActionSheet extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final Function(String) onReact;
  final VoidCallback onReply;
  final VoidCallback onEdit;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  const MessageActionSheet({
    super.key,
    required this.message,
    required this.isMine,
    required this.onReact,
    required this.onReply,
    required this.onEdit,
    required this.onCopy,
    required this.onDelete,
  });

  static const List<String> _emojis = ['❤️', '😂', '🔥', '👍', '😮', '😢'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.md),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
            ),
            
            // Reactions Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Row(
                children: _emojis.map((emoji) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        onReact(emoji);
                      },
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isDark 
                            ? AppColors.darkBorder.withValues(alpha: 0.3)
                            : AppColors.lightBorder.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const Divider(),
            
            // Actions
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                onReply();
              },
            ),
            if (isMine && message.text.isNotEmpty && message.timestamp != null && DateTime.now().difference(message.timestamp!).inMinutes < 15)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit message'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit();
                },
              ),
            if (message.text.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy text'),
                onTap: () {
                  Navigator.pop(context);
                  onCopy();
                },
              ),
            if (isMine)
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.error),
                title: Text('Delete for everyone', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
