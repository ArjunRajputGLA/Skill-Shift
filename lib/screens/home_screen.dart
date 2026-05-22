import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/post_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/animated_list_item.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/recommendation_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Future<List<PostModel>>? _recommendationsFuture;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  void _loadRecommendations() {
    final user = context.read<AuthService>().currentUser;
    if (user != null) {
      _recommendationsFuture = RecommendationService().getRecommendations(user);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = context.read<AuthService>().currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            // Premium Segmented Control
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9), // Slate 800 / Slate 100
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _currentIndex = 0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          color: _currentIndex == 0 ? theme.colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: _currentIndex == 0 ? [
                            BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))
                          ] : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Top Matches',
                          style: TextStyle(
                            color: _currentIndex == 0 ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _currentIndex = 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          color: _currentIndex == 1 ? theme.colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: _currentIndex == 1 ? [
                            BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))
                          ] : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Recent Posts',
                          style: TextStyle(
                            color: _currentIndex == 1 ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Tab Content
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  _buildTopMatchesTab(),
                  _buildRecentPostsTab(user),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopMatchesTab() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _loadRecommendations();
        });
        await _recommendationsFuture;
      },
      color: Theme.of(context).colorScheme.primary,
      child: FutureBuilder<List<PostModel>>(
        future: _recommendationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading matches: ${snapshot.error}'));
          }
          
          final posts = snapshot.data ?? [];
          
          if (posts.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: const EmptyStateWidget(
                  icon: Icons.auto_awesome_outlined,
                  title: 'No matches yet',
                  message: 'Update your skills and interests to get personalized recommendations!',
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: AppSpacing.navClearance, top: AppSpacing.md),
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return AnimatedListItem(
                index: index,
                child: PostCard(
                  ownerUid: post.uid,
                  userName: post.userName,
                  branchYear: '${post.branch} • ${post.year}',
                  title: post.title,
                  description: post.description,
                  tags: post.tags,
                  isExpandable: true,
                  initiallyExpanded: false,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRecentPostsTab(UserModel? user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading posts: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => Future.delayed(const Duration(milliseconds: 500)),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: const EmptyStateWidget(
                  icon: Icons.article_outlined,
                  title: 'No posts yet',
                  message: 'Be the first to share a skill or request help from the campus!',
                ),
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['uid'] != user?.id;
        }).toList();

        if (filteredDocs.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => Future.delayed(const Duration(milliseconds: 500)),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: const EmptyStateWidget(
                  icon: Icons.people_outline,
                  title: 'Quiet feed',
                  message: 'Looks like there are no active posts from others right now.',
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => Future.delayed(const Duration(milliseconds: 500)),
          color: Theme.of(context).colorScheme.primary,
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: AppSpacing.navClearance, top: AppSpacing.md),
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final doc = filteredDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final post = PostModel.fromMap(data, doc.id);

              return AnimatedListItem(
                index: index,
                child: PostCard(
                  ownerUid: post.uid,
                  userName: post.userName,
                  branchYear: '${post.branch} • ${post.year}',
                  title: post.title,
                  description: post.description,
                  tags: post.tags,
                  isExpandable: false, // Standard feed uses fully expanded cards
                  initiallyExpanded: true,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
