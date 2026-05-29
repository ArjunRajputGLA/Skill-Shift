import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/animated_list_item.dart';
import 'chat_detail_screen.dart';
import 'bookings_tab.dart'; 
import '../widgets/empty_state.dart';
import '../widgets/animated_watermark.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = context.watch<AuthService>().currentUser;
    final theme = Theme.of(context);
    
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            const AnimatedWatermark(),
            SafeArea(
              top: false,
              bottom: false,
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: TabBar(
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                      tabs: const [
                        Tab(text: 'Messages'),
                        Tab(text: 'My Bookings'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Expanded(
                    child: TabBarView(
                      children: [
                        _ChatsTab(),
                        BookingsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatsTab extends StatelessWidget {
  const _ChatsTab();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
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
          return RefreshIndicator(
            onRefresh: () async => Future.delayed(const Duration(milliseconds: 500)),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: EmptyStateWidget(
                  icon: Icons.chat_bubble_outline,
                  title: 'No Messages',
                  message: 'Reach out to someone to start a conversation.',
                ),
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return RefreshIndicator(
          onRefresh: () async => Future.delayed(const Duration(milliseconds: 500)),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.only(bottom: AppSpacing.navClearance),
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
                trailing: data['unread_${user.id}'] == true
                    ? Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
                onTap: () {
                  FirebaseFirestore.instance
                      .collection('chats')
                      .doc(docs[index].id)
                      .set({'unread_${user.id}': false}, SetOptions(merge: true));
                      
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
        ),
      );
    },
    );
  }
}