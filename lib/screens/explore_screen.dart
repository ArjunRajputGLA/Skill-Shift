import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/post_model.dart';
import '../widgets/post_card.dart';
import '../widgets/empty_state.dart';
import '../constants/app_sizes.dart';

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
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Search Bar
            Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search skills, tags, or projects...',
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black
                      : null,
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
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 2. Horizontal Category Filter Chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                        // Optional: Clear search when switching tabs? Let's leave search intact for multi-filtering.
                      });
                    },
                    selectedColor: Colors.blueAccent,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.grey.shade200,
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 8),

          // 3. Post Listing (Firestore Integration)
          Expanded(
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
                  return const Center(child: Text('Error loading data.'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.search_off,
                    title: 'No Posts Found',
                    message: 'It looks empty here. Try adjusting your search.',
                  );
                }

                // Local Search Filtering
                final rawDocs = snapshot.data!.docs;
                final user = context.read<AuthService>().currentUser;
                
                final List<PostModel> filteredPosts = rawDocs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return PostModel.fromMap(data, doc.id);
                }).where((post) {
                  // Hide current user's own posts
                  if (user != null && post.uid == user.id) return false;

                  // --- Category Filtering ---
                  bool categoryMatch = true;
                  if (_selectedCategory != 'All') {
                    // Check if category exists either in tags, description, or title
                    final catLower = _selectedCategory.toLowerCase();
                    final inTags = post.tags.any((tag) => tag.toLowerCase() == catLower);
                    final inType = post.postType.toLowerCase() == catLower;
                    final inTitleDesc = post.title.toLowerCase().contains(catLower) || 
                                        post.description.toLowerCase().contains(catLower);
                    categoryMatch = inTags || inType || inTitleDesc;
                  }

                  if (!categoryMatch) return false;

                  // --- Search Query Filtering ---
                  if (_searchQuery.isEmpty) return true;

                  final titleMatch = post.title.toLowerCase().contains(_searchQuery);
                  final descMatch = post.description.toLowerCase().contains(_searchQuery);
                  final typeMatch = post.postType.toLowerCase().contains(_searchQuery);
                  final tagsMatch = post.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));

                  return titleMatch || descMatch || typeMatch || tagsMatch;
                }).toList();

                if (filteredPosts.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.manage_search,
                    title: 'No Matches',
                    message: 'We couldn\'t find anything for "$_searchQuery" in $_selectedCategory.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
                  itemCount: filteredPosts.length,
                  itemBuilder: (context, index) {
                    final post = filteredPosts[index];
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
        ],
      ),
      ),
    );
  }
}
