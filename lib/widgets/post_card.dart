import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/chat_detail_screen.dart';
import '../constants/app_sizes.dart';

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
    
    return Card(
      margin: const EdgeInsets.only(
        left: AppSizes.p16,
        right: AppSizes.p16,
        bottom: AppSizes.p16,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: User Info
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  foregroundColor: theme.colorScheme.primary,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: AppSizes.p12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
                      ),
                      Text(
                        branchYear,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                  onPressed: () {}, // Options like report/save
                )
              ],
            ),
            const SizedBox(height: AppSizes.p16),

            // Post Body: Title & Content
            Text(
              title,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.p8),
            Text(
              description,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
            const SizedBox(height: AppSizes.p16),

            // Tags
            Wrap(
              spacing: AppSizes.p8,
              runSpacing: AppSizes.p8,
              children: tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.p12,
                      vertical: 6.0,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    ),
                    child: Text(
                      tag,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  )).toList(),
            ),
            const SizedBox(height: AppSizes.p24),

            // Connect Button
            SizedBox(
              width: double.infinity,
              height: AppSizes.buttonHeight - 4, // slightly shorter for card internal
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

                  final String chatId = currentUser.id.compareTo(ownerUid) < 0
                      ? '${currentUser.id}_$ownerUid'
                      : '${ownerUid}_${currentUser.id}';

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatDetailScreen(
                        chatId: chatId,
                        targetUserName: userName,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline, size: 20),
                label: const Text('Connect'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  foregroundColor: theme.colorScheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
