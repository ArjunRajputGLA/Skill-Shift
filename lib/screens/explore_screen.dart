import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/post_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/post_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/animated_list_item.dart';
import '../widgets/custom_chip.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Coding',
    'Design',
    'Academics',
    'Fitness',
    'Language Learning',
    'Public Speaking',
    'Placement Prep',
    'Startup/Business'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            Widget sliverList;
            
            if (snapshot.connectionState == ConnectionState.waiting) {
              sliverList = const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasError) {
              sliverList = const SliverFillRemaining(
                child: Center(child: Text('Error loading data.')),
              );
            } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              sliverList = const SliverFillRemaining(
                child: EmptyStateWidget(
                  icon: Icons.search_off,
                  title: 'No Posts Found',
                  message: 'It looks empty here. Try adjusting your search.',
                ),
              );
            } else {
              // Local Search Filtering — ALL backend logic preserved
              final rawDocs = snapshot.data!.docs;
              final user = context.read<AuthService>().currentUser;
              
              final List<PostModel> filteredPosts = rawDocs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return PostModel.fromMap(data, doc.id);
              }).where((post) {
                if (user != null && post.uid == user.id) return false;

                bool categoryMatch = true;
                if (_selectedCategory != 'All') {
                  final catLower = _selectedCategory.toLowerCase();
                  final inTags = post.tags.any((tag) => tag.toLowerCase() == catLower);
                  final inType = post.postType.toLowerCase() == catLower;
                  final inTitleDesc = post.title.toLowerCase().contains(catLower) || 
                                      post.description.toLowerCase().contains(catLower);
                  categoryMatch = inTags || inType || inTitleDesc;
                }

                if (!categoryMatch) return false;

                if (_searchQuery.isEmpty) return true;

                final titleMatch = post.title.toLowerCase().contains(_searchQuery);
                final descMatch = post.description.toLowerCase().contains(_searchQuery);
                final typeMatch = post.postType.toLowerCase().contains(_searchQuery);
                final tagsMatch = post.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));

                return titleMatch || descMatch || typeMatch || tagsMatch;
              }).toList();

              if (filteredPosts.isEmpty) {
                sliverList = SliverFillRemaining(
                  child: EmptyStateWidget(
                    icon: Icons.manage_search,
                    title: 'No Matches',
                    message: 'We couldn\'t find anything for "$_searchQuery" in $_selectedCategory.',
                  ),
                );
              } else {
                sliverList = SliverPadding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.sm,
                    bottom: AppSpacing.navClearance,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = filteredPosts[index];
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
                      childCount: filteredPosts.length,
                    ),
                  ),
                );
              }
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Search Bar & Categories in SliverAppBar
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  floating: true,
                  snap: true,
                  toolbarHeight: 0, // No default toolbar
                  expandedHeight: 140, // Enough for search bar + tags
                  collapsedHeight: 140,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Column(
                      children: [
                        // Search Bar
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md,
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val.toLowerCase();
                              });
                            },
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search skills, tags, or projects...',
                              prefixIcon: Icon(
                                Icons.search,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: isDark
                                  ? AppColors.darkSurfaceElevated
                                  : AppColors.lightSurfaceElevated,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        // Horizontal Category Filter Chips
                        SizedBox(
                          height: 50,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              final isSelected = _selectedCategory == category;
                              
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: CustomChip(
                                  label: category,
                                  isSelected: isSelected,
                                  variant: ChipVariant.filled,
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = category;
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 2. Post Listing
                sliverList,
              ],
            );
          },
        ),
      ),
    );
  }
}
