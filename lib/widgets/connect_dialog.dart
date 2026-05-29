import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/whatsapp_service.dart';
import '../screens/chat_detail_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class ConnectDialog extends StatelessWidget {
  final String targetUserId;
  final String targetUserName;
  final String sourceTitle;

  const ConnectDialog({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    this.sourceTitle = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Icon
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.handshake_rounded,
                size: 32,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Title
            Text(
              'Connect with $targetUserName',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            
            // Subtitle
            Text(
              'How would you like to connect?',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            
            // Action 1: In-App Chat
            _buildActionButton(
              context: context,
              icon: Icons.chat_bubble_rounded,
              title: 'Start Conversation',
              subtitle: 'Chat instantly in the app',
              color: const Color(0xFF3B82F6), // Blue
              onTap: () {
                _startInAppChat(context);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Action 2: WhatsApp
            _buildActionButton(
              context: context,
              icon: Icons.phone_android_rounded, // or custom icon if possible, phone is good
              title: 'Open WhatsApp',
              subtitle: 'Connect via WhatsApp',
              color: const Color(0xFF25D366), // WhatsApp Green
              onTap: () {
                _openWhatsApp(context);
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Cancel Button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startInAppChat(BuildContext context) {
    final currentUser = context.read<AuthService>().currentUser;
    if (currentUser == null) return;
    
    final String chatId = currentUser.id.compareTo(targetUserId) < 0
        ? '${currentUser.id}_$targetUserId'
        : '${targetUserId}_${currentUser.id}';

    Navigator.of(context).pop(); // Close ConnectDialog

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          chatId: chatId,
          targetUserName: targetUserName,
          targetUserId: targetUserId,
        ),
      ),
    );
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    NotificationService.showLoading(context);
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(targetUserId).get();
      if (!context.mounted) return;
      NotificationService.hideLoading(context);
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final targetWhatsApp = data['whatsapp'] ?? '';
        
        await WhatsAppService.openWhatsApp(
          context: context, 
          phoneNumber: targetWhatsApp,
          userName: targetUserName,
          postTitle: sourceTitle,
        );
      } else {
        NotificationService.showError(context, "User not found.");
      }
    } catch (e) {
      if (context.mounted) {
        NotificationService.hideLoading(context);
        NotificationService.showError(context, "Failed to fetch user data.");
      }
    } finally {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close ConnectDialog
      }
    }
  }
}
