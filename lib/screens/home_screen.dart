import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/theme_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/empty_state.dart';
import '../models/post_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: SafeArea(
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
            return Center(child: Text('Error loading posts: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          if (snapshot.hasData && snapshot.data!.metadata.isFromCache) {
            // This tells us if Firebase is failing to reach the cloud and silently falling back to the local database
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
            return data['uid'] != user?.id; // Filter out own posts
          }).toList();

          if (filteredDocs.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.people_outline,
              title: 'Quiet feed',
              message: 'Looks like there are no active posts from others right now.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final data = filteredDocs[index].data() as Map<String, dynamic>;
              final post = PostModel.fromMap(data, filteredDocs[index].id);

              return PostCard(
                ownerUid: post.uid,
                userName: post.userName,
                branchYear: '${post.branch} • ${post.year}',
                title: post.title,
                description: post.description,
                tags: post.tags,
              );
            },
          );
        },
      ),
      ),
    );
  }
}

