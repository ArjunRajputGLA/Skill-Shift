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
import 'dart:math' as math;
import '../services/recommendation_service.dart';
import '../models/recommendations/recommended_item.dart';
import '../models/recommendations/recommended_post.dart';
import '../models/recommendations/recommended_user.dart';
import '../models/recommendations/recommended_session.dart';
import '../widgets/recommended_item_card.dart';
import '../farrey/theme/farrey_colors.dart';
import '../widgets/booking_form_sheet.dart';
import 'public_profile_screen.dart';
import 'chat_detail_screen.dart';
import '../services/whatsapp_service.dart';
import '../services/notification_service.dart';
import '../widgets/connect_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  int _currentIndex = 0;
  Future<List<RecommendedItem>>? _recommendationsFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  void _loadRecommendations() {
    final user = context.read<AuthService>().currentUser;
    if (user != null) {
      _recommendationsFuture = RecommendationService().getMixedRecommendations(user);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = context.read<AuthService>().currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        top: false,
        bottom: false,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: _buildRecommendationsSection(isDark),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  minHeight: 80.0,
                  maxHeight: 80.0,
                  child: Container(
                    color: context.farreyBackground, // Opaque background so posts hide behind it
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    alignment: Alignment.center,
                    child: Container(
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
                                    BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))
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
                                    BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))
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
                  ),
                ),
              ),
            ];
          },
          body: IndexedStack(
            index: _currentIndex,
            children: [
              _buildTopMatchesTab(),
              _buildRecentPostsTab(user),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopMatchesTab() {
    // Currently, Top Matches is disabled or rather replaced by the new Recommended For You horizontal bar.
    // However, to keep this tab functional, we can show a list of PostModel from the new recommendation engine if they are posts.
    // But since the new engine mixes everything, let's just show standard recent posts here or filter only posts from recommendations.
    return FutureBuilder<List<RecommendedItem>>(
      future: _recommendationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final items = snapshot.data ?? [];
        // Filter only posts to display in the vertical list if we want to keep the old UI working
        final posts = items.where((i) => i.recommendationType == 'Post').toList();
        
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
            final rec = posts[index];
            final post = (rec as dynamic).post as PostModel;
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
    );
  }

  Widget _buildRecommendationsSection(bool isDark) {
    return FutureBuilder<List<RecommendedItem>>(
      future: _recommendationsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); // Hide if no recommendations
        }

        final items = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.lg, top: AppSpacing.lg, bottom: AppSpacing.sm),
              child: Text(
                'Recommended For You',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return RecommendedItemCard(
                    item: items[index],
                    onTap: () {
                      _showRecommendedActionModal(context, items[index], isDark);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
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

  void _showRecommendedActionModal(BuildContext context, RecommendedItem item, bool isDark) {
    String hostId = '';
    String hostName = '';
    String title = '';
    String role = '';
    String? imageUrl;

    if (item is RecommendedUser) {
      hostId = item.user.id;
      hostName = item.user.fullName;
      title = item.user.fullName;
      role = '${item.user.branch} • ${item.user.year}';
      imageUrl = item.user.profileImageUrl;
    } else if (item is RecommendedPost) {
      hostId = item.post.uid;
      hostName = item.post.userName;
      title = item.post.userName;
      role = 'Post Author';
    } else if (item is RecommendedSession) {
      hostId = item.session.ownerUid;
      hostName = item.session.ownerName;
      title = item.session.ownerName;
      role = 'Session Host';
    } else {
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).padding.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF18181B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: context.farreyPrimary.withOpacity(0.2),
                    backgroundImage: imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                    child: (imageUrl == null || imageUrl.isEmpty) 
                        ? Icon(Icons.person, color: context.farreyPrimary) 
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          role,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              _buildModalAction(
                context,
                isDark,
                icon: Icons.person_add_rounded,
                title: 'Connect',
                subtitle: 'Send a connection request to network',
                color: const Color(0xFF3B82F6),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  final currentUser = context.read<AuthService>().currentUser;
                  if (currentUser == null) return;
                  if (currentUser.id == hostId) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You cannot connect with yourself!')),
                    );
                    return;
                  }
                  
                  showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return ConnectDialog(
                        targetUserId: hostId,
                        targetUserName: hostName,
                        sourceTitle: title,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildModalAction(
                context,
                isDark,
                icon: Icons.calendar_month_rounded,
                title: 'Request Session',
                subtitle: 'Book a 1-on-1 session to learn together',
                color: context.farreyPrimary,
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => BookingFormSheet(mentorUid: hostId, mentorName: hostName),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildModalAction(
                context,
                isDark,
                icon: Icons.person_search_rounded,
                title: 'View Profile',
                subtitle: 'See more details about $hostName',
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: hostId)));
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalAction(BuildContext context, bool isDark, {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white54 : Colors.black38),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => math.max(maxHeight, minHeight);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
