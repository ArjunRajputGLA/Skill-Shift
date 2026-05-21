import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/post_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/animated_list_item.dart';
import '../models/post_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading posts: ${snapshot.error}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data!.metadata.isFromCache) {
            debugPrint("WARNING: Firestore data is coming from the OFFLINE CACHE, not the live server!");
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.article_outlined,
              title: 'No posts yet',
              message: 'Be the first to share a skill or request help from the campus!',
            );
          }

          final docs = snapshot.data!.docs;
          final user = context.read<AuthService>().currentUser;

          final filteredDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['uid'] != user?.id;
          }).toList();

          if (filteredDocs.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.people_outline,
              title: 'Quiet feed',
              message: 'Looks like there are no active posts from others right now.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // StreamBuilder auto-refreshes, but the gesture feels premium
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: Theme.of(context).colorScheme.primary,
            child: ListView.builder(
              padding: const EdgeInsets.only(
              bottom: AppSpacing.navClearance,
              ),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              itemCount: filteredDocs.length,
              itemBuilder: (context, index) {
                final data = filteredDocs[index].data() as Map<String, dynamic>;
                final post = PostModel.fromMap(data, filteredDocs[index].id);

                return AnimatedListItem(
                  index: index,
                  child: PostCard(
                    ownerUid: post.uid,
                    userName: post.userName,
                    branchYear: '${post.branch} • ${post.year}',
                    title: post.title,
                    description: post.description,
                    tags: post.tags,
                  ),
                );
              },
            ),
          );
        },
      ),
      ),
    );
  }
}
