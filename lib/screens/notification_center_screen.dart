import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'chat_detail_screen.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  IconData _getIconForType(String type) {
    switch (type) {
      case 'message': return Icons.chat_bubble_outline_rounded;
      case 'session': return Icons.calendar_month_rounded;
      case 'endorsement': return Icons.workspace_premium_rounded;
      case 'recommendation': return Icons.auto_awesome_rounded;
      case 'connection': return Icons.person_add_alt_1_rounded;
      default: return Icons.notifications_active_outlined;
    }
  }

  Color _getColorForType(String type, BuildContext context) {
    final theme = Theme.of(context);
    switch (type) {
      case 'message': return AppColors.messagesAccent1;
      case 'session': return AppColors.exploreAccent1;
      case 'endorsement': return AppColors.homeAccent1;
      case 'recommendation': return AppColors.postsAccent1;
      case 'connection': return AppColors.profileAccent1;
      default: return theme.colorScheme.primary;
    }
  }

  void _handleNotificationTap(BuildContext context, Map<String, dynamic> data) async {
    final String id = data['notificationId'];
    final String type = data['type'];
    final payload = data['payload'] as Map<String, dynamic>? ?? {};

    // Mark as read
    if (data['isRead'] == false) {
      await NotificationService.markAsRead(id);
    }

    if (!context.mounted) return;

    // Routing
    if (type == 'message' || type == 'reaction') {
      final chatId = payload['chatId'];
      if (chatId != null) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ChatDetailScreen(chatId: chatId, targetUserId: 'Unknown', targetUserName: 'Chat'),
        ));
      }
    } else if (type == 'session') {
      Navigator.pop(context); // Go back and maybe select Bookings tab (index 1) but main_layout doesn't expose it easily. Just pop for now.
    } else if (type == 'endorsement' || type == 'connection') {
      // Could open profile
      Navigator.pop(context);
    } else {
      // Default: just stay here or pop
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Mark All Read',
            icon: const Icon(Icons.done_all_rounded, size: 24),
            onPressed: () {
              NotificationService.markAllAsRead();
              NotificationService.showSuccess(context, 'All marked as read');
            },
          ),
          IconButton(
            tooltip: 'Delete All',
            icon: const Icon(Icons.delete_sweep_rounded, size: 24),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('Delete All Notifications'),
                    content: const Text('Are you sure you want to clear all notifications? This cannot be undone.'),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Delete All'),
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          NotificationService.deleteAllNotifications();
                          NotificationService.showSuccess(context, 'All notifications deleted');
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: NotificationService.getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: theme.iconTheme.color?.withValues(alpha: 0.3)),
                  const SizedBox(height: AppSpacing.md),
                  Text('No notifications yet', style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.bodySmall?.color)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final bool isRead = data['isRead'] ?? false;
              final Timestamp? ts = data['timestamp'] as Timestamp?;
              final timeString = ts != null ? timeago.format(ts.toDate()) : 'Just now';

              return Dismissible(
                key: Key(data['notificationId']),
                direction: DismissDirection.horizontal,
                background: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                secondaryBackground: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) {
                  NotificationService.deleteNotification(data['notificationId']);
                },
                child: Material(
                  color: isRead 
                      ? (isDark ? AppColors.darkSurfaceElevated : Colors.white)
                      : theme.colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  elevation: isRead ? 0 : 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _handleNotificationTap(context, data),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getColorForType(data['type'], context).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getIconForType(data['type']),
                              color: _getColorForType(data['type'], context),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        data['title'] ?? 'Notification',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      timeString,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: isRead ? null : theme.colorScheme.primary,
                                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  data['body'] ?? '',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (!isRead) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(top: 6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
