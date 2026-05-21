import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/chat_detail_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../services/whatsapp_service.dart';
import '../services/notification_service.dart';
import 'glass_card.dart';
import 'avatar_widget.dart';
import 'custom_chip.dart';

class PostCard extends StatelessWidget {
  final String ownerUid;
  final String userName;
  final String branchYear;
  final String title;
  final String description;
  final List<String> tags;

  const PostCard({
    super.key,
    required this.ownerUid,
    required this.userName,
    required this.branchYear,
    required this.title,
    required this.description,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GlassCard(
      margin: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: AppSpacing.lg,
      ),
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left gradient accent strip
          Container(
            width: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary,
                  AppColors.accent,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radiusMd),
                bottomLeft: Radius.circular(AppSpacing.radiusMd),
              ),
            ),
          ),
          // Card content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: User Info
                  Row(
                    children: [
                      AvatarWidget(
                        userId: ownerUid,
                        name: userName,
                        radius: 20,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              branchYear,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_horiz),
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        onPressed: () {},
                      )
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Post Body: Title & Content
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Tags
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: tags.map((tag) => CustomChip(
                      label: tag,
                      variant: ChipVariant.filled,
                    )).toList(),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Connect Button — ALL backend logic preserved exactly
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () {
                        final currentUser = context.read<AuthService>().currentUser;
                        if (currentUser == null) return;

                        if (currentUser.id == ownerUid) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('You cannot connect with your own post!')),
                          );
                          return;
                        }

                        showDialog(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            return AlertDialog(
                              title: Text('Connect with $userName?'),
                              content: const Text('How would you like to connect?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                    final String chatId = currentUser.id.compareTo(ownerUid) < 0
                                        ? '${currentUser.id}_$ownerUid'
                                        : '${ownerUid}_${currentUser.id}';

                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ChatDetailScreen(
                                          chatId: chatId,
                                          targetUserName: userName,
                                          targetUserId: ownerUid,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('Start Conversation'),
                                ),
                                FilledButton(
                                  onPressed: () async {
                                    Navigator.of(dialogContext).pop();
                                    
                                    NotificationService.showLoading(context);
                                    
                                    try {
                                      final doc = await FirebaseFirestore.instance.collection('users').doc(ownerUid).get();
                                      if (context.mounted) {
                                        NotificationService.hideLoading(context);
                                        
                                        if (doc.exists) {
                                          final data = doc.data() as Map<String, dynamic>;
                                          final targetWhatsApp = data['whatsapp'] ?? '';
                                          
                                          await WhatsAppService.openWhatsApp(
                                            context: context, 
                                            phoneNumber: targetWhatsApp,
                                            userName: userName,
                                            postTitle: title,
                                          );
                                        } else {
                                          NotificationService.showError(context, "User not found.");
                                        }
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        NotificationService.hideLoading(context);
                                        NotificationService.showError(context, "Failed to fetch user data.");
                                      }
                                    }
                                  },
                                  child: const Text('Open WhatsApp'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 20),
                      label: const Text('Connect'),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                        foregroundColor: theme.colorScheme.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
