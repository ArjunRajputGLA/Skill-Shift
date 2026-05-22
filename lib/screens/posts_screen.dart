import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/post_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/glass_card.dart';
import '../widgets/animated_list_item.dart';
import '../widgets/custom_chip.dart';
import 'main_layout.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        top: false,
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md), // Very slight push down below header
            
            // Premium Segmented Control
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9), // Slate 800 / Slate 100
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _tabController.animateTo(0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          color: _tabController.index == 0 ? theme.colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: _tabController.index == 0 ? [
                            BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))
                          ] : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Create Post',
                          style: TextStyle(
                            color: _tabController.index == 0 ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _tabController.animateTo(1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          color: _tabController.index == 1 ? theme.colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: _tabController.index == 1 ? [
                            BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))
                          ] : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'My Posts',
                          style: TextStyle(
                            color: _tabController.index == 1 ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: NotificationListener<ScrollUpdateNotification>(
                onNotification: (notification) {
                  if (notification.metrics.axis == Axis.horizontal) {
                    final metrics = notification.metrics;
                    final mainState = context.findAncestorStateOfType<MainLayoutState>();
                    if (mainState != null && mainState.pageController.hasClients) {
                      if (metrics.pixels < metrics.minScrollExtent - 20) {
                        mainState.pageController.animateToPage(
                          1,
                          duration: AppSpacing.durationNormal,
                          curve: Curves.ease,
                        );
                      } else if (metrics.pixels > metrics.maxScrollExtent + 20) {
                        mainState.pageController.animateToPage(
                          3,
                          duration: AppSpacing.durationNormal,
                          curve: Curves.ease,
                        );
                      }
                    }
                  }
                  return false;
                },
                child: TabBarView(
                  controller: _tabController,
                  physics: const BouncingScrollPhysics(),
                  children: const [
                    _CreatePostTab(),
                    _MyPostsTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 1. Create Post Tab
// ----------------------------------------------------------------------
class _CreatePostTab extends StatefulWidget {
  const _CreatePostTab();

  @override
  State<_CreatePostTab> createState() => _CreatePostTabState();
}

class _CreatePostTabState extends State<_CreatePostTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _tagsController = TextEditingController();
  final _availabilityController = TextEditingController();

  bool _isLoading = false;

  String _selectedPostType = 'Teach';
  final List<String> _postTypes = [
    'Teach',
    'Learn',
    'Collaborate',
    'Project Partner',
    'Hackathon Team',
    'Internship Referral'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _tagsController.dispose();
    _availabilityController.dispose();
    super.dispose();
  }

  // ALL backend logic preserved exactly as-is
  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = context.read<AuthService>().currentUser;
      if (user == null) throw Exception("User not found locally");

      final postRef = FirebaseFirestore.instance.collection('posts').doc();

      final List<String> parsedTags = _tagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final newPost = PostModel(
        id: postRef.id,
        uid: user.id,
        userName: user.fullName,
        branch: user.branch,
        year: user.year,
        postType: _selectedPostType,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        tags: parsedTags,
        availability: _availabilityController.text.trim(),
        createdAt: DateTime.now(),
      );

      try {
        debugPrint("ATTEMPTING TO SAVE POST TO FIRESTORE: ${postRef.id}");
        await postRef.set(newPost.toMap());
        debugPrint("POST SAVED SUCCESSFULLY");
      } catch (e) {
        debugPrint("FIRESTORE WRITE FAILED: $e");
        rethrow;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Post published successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      _formKey.currentState!.reset();
      _titleController.clear();
      _descController.clear();
      _tagsController.clear();
      _availabilityController.clear();
      setState(() => _selectedPostType = 'Teach');

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to publish: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final dynamicBottomPadding = bottomInset > 0 ? AppSpacing.md : AppSpacing.navClearance;

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: dynamicBottomPadding,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'What do you want to share?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<String>(
              initialValue: _selectedPostType,
              decoration: const InputDecoration(
                labelText: 'Post Type',
              ),
              items: _postTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedPostType = val);
                }
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Need help with DSA',
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Explain what you need or what you can offer...',
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Description is required' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma separated)',
                hintText: 'Flutter, UI/UX, DSA',
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'At least one tag is required' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _availabilityController,
              decoration: const InputDecoration(
                labelText: 'Availability (Optional)',
                hintText: 'e.g. Weekends / Evenings',
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _submitPost,
                child: const Text('Post to Feed', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 2. My Posts Tab
// ----------------------------------------------------------------------
class _MyPostsTab extends StatelessWidget {
  const _MyPostsTab();

  // ALL backend logic preserved exactly
  Future<void> _deletePost(BuildContext context, String postId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Post deleted!'), backgroundColor: AppColors.error),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _editPost(BuildContext context, PostModel post) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EditPostScreen(post: post),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final dynamicBottomPadding = bottomInset > 0 ? AppSpacing.md : AppSpacing.navClearance;

    if (user == null) return const Center(child: CircularProgressIndicator());

    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: user.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint("Current user UID: ${user.id}");
          debugPrint("Firestore error: ${snapshot.error}");
          return const Center(child: Text('Error loading my posts.'));
        }

        if (snapshot.hasData) {
          debugPrint("Documents found: ${snapshot.data?.docs.length}");
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => Future.delayed(const Duration(milliseconds: 500)),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                child: Center(
                  child: Text(
                    "You haven't made any posts yet.",
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        var posts = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return PostModel.fromMap(data, doc.id);
        }).toList();

        posts.sort((a, b) {
          final aDate = a.createdAt ?? DateTime.now();
          final bDate = b.createdAt ?? DateTime.now();
          return bDate.compareTo(aDate);
        });

        return RefreshIndicator(
          onRefresh: () async => Future.delayed(const Duration(milliseconds: 500)),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: EdgeInsets.only(
              top: AppSpacing.sm,
              bottom: dynamicBottomPadding,
            ),
            itemCount: posts.length,
            itemBuilder: (context, index) {
            final post = posts[index];

            return AnimatedListItem(
              index: index,
              child: GlassCard(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomChip(
                          label: post.postType,
                          variant: ChipVariant.filled,
                          isSelected: true,
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit_outlined,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                size: 20,
                              ),
                              onPressed: () => _editPost(context, post),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                              onPressed: () => _deletePost(context, post.id),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      post.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      post.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
    );
  }
}

// ----------------------------------------------------------------------
// 3. Edit Post Screen
// ----------------------------------------------------------------------
class EditPostScreen extends StatefulWidget {
  final PostModel post;
  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _tagsController;
  late TextEditingController _availabilityController;

  late String _selectedPostType;
  bool _isLoading = false;

  final List<String> _postTypes = [
    'Teach', 'Learn', 'Collaborate', 'Project Partner', 'Hackathon Team', 'Internship Referral'
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post.title);
    _descController = TextEditingController(text: widget.post.description);
    _tagsController = TextEditingController(text: widget.post.tags.join(', '));
    _availabilityController = TextEditingController(text: widget.post.availability);
    
    _selectedPostType = _postTypes.contains(widget.post.postType) 
        ? widget.post.postType 
        : 'Teach';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _tagsController.dispose();
    _availabilityController.dispose();
    super.dispose();
  }

  // ALL backend logic preserved exactly
  Future<void> _updatePost() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final List<String> parsedTags = _tagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      await FirebaseFirestore.instance.collection('posts').doc(widget.post.id).update({
        'postType': _selectedPostType,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'tags': parsedTags,
        'availability': _availabilityController.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Post updated!'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Post')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedPostType,
                    decoration: const InputDecoration(labelText: 'Post Type'),
                    items: _postTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedPostType = val);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Description is required' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _tagsController,
                    decoration: const InputDecoration(labelText: 'Tags (comma separated)'),
                    validator: (val) => val == null || val.trim().isEmpty ? 'At least one tag is required' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _availabilityController,
                    decoration: const InputDecoration(labelText: 'Availability (Optional)'),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _updatePost,
                      child: const Text('Save Changes', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
