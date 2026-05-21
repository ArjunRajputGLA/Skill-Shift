import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/animated_list_item.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: user.id)
            .orderBy('lastUpdated', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error fetching conversations"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No conversations yet.\nHit "Connect" on a post to start chatting!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontSize: 16,
                ),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.only(
              bottom: AppSpacing.navClearance,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              
              List<dynamic> participantNames = data['participantNames'] ?? [];
              String targetName = participantNames.firstWhere(
                (name) => name != user.fullName, 
                orElse: () => 'A Skill Shift User'
              );

              List<dynamic> participants = data['participants'] ?? [];
              String targetId = participants.firstWhere(
                (id) => id != user.id,
                orElse: () => '',
              );

              return AnimatedListItem(
                index: index,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.xs,
                  ),
                  leading: AvatarWidget(
                    userId: targetId,
                    name: targetName,
                    radius: 24,
                  ),
                  title: Text(
                    targetName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    data['lastMessage'] ?? 'No messages yet', 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatDetailScreen(
                          chatId: docs[index].id,
                          targetUserName: targetName,
                          targetUserId: targetId,
                        ),
                      )
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      ),
    );
  }
}