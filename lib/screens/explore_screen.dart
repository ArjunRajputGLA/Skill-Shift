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

class _ExploreScreenState extends State<ExploreScreen> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  final List<String> _selectedCategories = ['All'];

  @override
  bool get wantKeepAlive => true;

  final List<String> _categories = [
    'All', 'Coding', 'Design', 'Academics', 'Fitness', 
    'Language Learning', 'Public Speaking', 'Placement Prep', 
    'Startup/Business', 'Photography', 'Video Editing', 
    'Music', 'Web Dev', 'App Dev', 'Machine Learning', 
    'Data Science', 'Marketing', 'UI/UX', 'Content Creation'
  ];

  List<double> _tagWidths = [];
  List<double> _cumulativeOffsets = [];
  double _totalWidth = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateTagWidths();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _calculateTagWidths() {
    double currentOffset = 0.0;
    for (String tag in _categories) {
      final TextPainter textPainter = TextPainter(
        text: TextSpan(text: tag, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();
      
      final double width = textPainter.width + 36.0; 
      _tagWidths.add(width);
      _cumulativeOffsets.add(currentOffset);
      currentOffset += width;
    }
    _totalWidth = currentOffset;
  }

  void _startAutoScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    if (_searchQuery.isNotEmpty) return;
    
    final currentPosition = _scrollController.position.pixels;
    final maxExtent = _scrollController.position.maxScrollExtent;
    final remainingDistance = maxExtent - currentPosition;
    
    if (remainingDistance > 0) {
      final durationInSeconds = (remainingDistance / 30).round();
      if (durationInSeconds > 0) {
        _scrollController.animateTo(
          maxExtent,
          duration: Duration(seconds: durationInSeconds),
          curve: Curves.linear,
        );
      }
    }
  }

  void _checkAndCenterTag(String query) {
    if (query.isEmpty) {
      _startAutoScroll();
      return;
    }
    
    int matchedIndex = -1;
    for (int i = 0; i < _categories.length; i++) {
      if (_categories[i].toLowerCase().contains(query)) {
        matchedIndex = i;
        break;
      }
    }
    
    if (matchedIndex != -1 && _scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.offset);
      
      final double currentOffset = _scrollController.offset;
      if (_totalWidth == 0.0) return;
      final int currentLoop = (currentOffset / _totalWidth).floor();
      final double screenWidth = MediaQuery.of(context).size.width;
      final double screenCenter = currentOffset + screenWidth / 2;
      
      final double pos1 = 12.0 + ((currentLoop - 1) * _totalWidth) + _cumulativeOffsets[matchedIndex] + (_tagWidths[matchedIndex] / 2);
      final double pos2 = 12.0 + (currentLoop * _totalWidth) + _cumulativeOffsets[matchedIndex] + (_tagWidths[matchedIndex] / 2);
      final double pos3 = 12.0 + ((currentLoop + 1) * _totalWidth) + _cumulativeOffsets[matchedIndex] + (_tagWidths[matchedIndex] / 2);
      
      List<double> candidates = [pos1, pos2, pos3].where((p) => (p - screenWidth / 2) >= 0).toList();
      if (candidates.isEmpty) candidates = [pos2, pos3]; 
      
      double bestPos = candidates.reduce((a, b) => (a - screenCenter).abs() < (b - screenCenter).abs() ? a : b);
      
      double centerOffset = bestPos - screenWidth / 2;
      centerOffset = centerOffset.clamp(0.0, _scrollController.position.maxScrollExtent);
      
      _scrollController.animateTo(
        centerOffset,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        top: false,
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
                if (!_selectedCategories.contains('All')) {
                  final inTags = post.tags.any((tag) => _selectedCategories.any((sc) => sc.toLowerCase() == tag.toLowerCase()));
                  final inType = _selectedCategories.any((sc) => sc.toLowerCase() == post.postType.toLowerCase());
                  final inTitleDesc = _selectedCategories.any((sc) {
                    final catLower = sc.toLowerCase();
                    return post.title.toLowerCase().contains(catLower) || 
                           post.description.toLowerCase().contains(catLower);
                  });
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
                    message: 'We couldn\'t find anything for "$_searchQuery" in ${_selectedCategories.join(", ")}.',
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

            return RefreshIndicator(
              onRefresh: () async => Future.delayed(const Duration(milliseconds: 500)),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                // 1. Search Bar & Categories in SliverAppBar
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  floating: true,
                  snap: true,
                  toolbarHeight: 0, // No default toolbar
                  expandedHeight: 120, // Enough for search bar + tags
                  collapsedHeight: 120,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Column(
                      children: [
                        // Search Bar
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md,
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val.toLowerCase();
                              });
                              _checkAndCenterTag(_searchQuery);
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
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification is ScrollEndNotification) {
                                Future.delayed(const Duration(milliseconds: 800), () {
                                  if (mounted && _searchQuery.isEmpty) _startAutoScroll();
                                });
                              }
                              return false;
                            },
                            child: ListView.builder(
                              controller: _scrollController,
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                              itemCount: _categories.length * 1000,
                              itemBuilder: (context, index) {
                                 final category = _categories[index % _categories.length];
                                 final isSelected = _selectedCategories.contains(category);
                                 
                                 double startX = 0;
                                 double startY = 0;

                                 void toggleCategory() {
                                   setState(() {
                                     if (category == 'All') {
                                       _selectedCategories.clear();
                                       _selectedCategories.add('All');
                                     } else {
                                       if (_selectedCategories.contains('All')) {
                                         _selectedCategories.remove('All');
                                       }
                                       if (_selectedCategories.contains(category)) {
                                         _selectedCategories.remove(category);
                                         if (_selectedCategories.isEmpty) _selectedCategories.add('All');
                                       } else {
                                         _selectedCategories.add(category);
                                       }
                                     }
                                   });
                                 }

                                 return Padding(
                                   padding: const EdgeInsets.symmetric(horizontal: 4),
                                   child: Listener(
                                     onPointerDown: (e) {
                                       startX = e.position.dx;
                                       startY = e.position.dy;
                                     },
                                     onPointerUp: (e) {
                                       final distance = (e.position.dx - startX).abs() + (e.position.dy - startY).abs();
                                       if (distance < 10) {
                                         toggleCategory();
                                         Future.delayed(const Duration(milliseconds: 100), () {
                                           if (mounted && _searchQuery.isEmpty) _startAutoScroll();
                                         });
                                       }
                                     },
                                     child: CustomChip(
                                       label: category,
                                       isSelected: isSelected,
                                       variant: ChipVariant.filled,
                                       onTap: () {
                                         // Handled by Listener above to distinguish from scrolling
                                       },
                                     ),
                                   ),
                                 );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 2. Post Listing
                sliverList,
              ],
              ),
            );
          },
        ),
      ),
    );
  }
}
