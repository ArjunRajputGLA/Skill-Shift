import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/post_model.dart';
import 'main_layout.dart';

class PostsScreen extends StatelessWidget {
  const PostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: Column(
            children: [
              const TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: [
                  Tab(text: 'Create Post'),
                  Tab(text: 'My Posts'),
                ],
              ),
              Expanded(
                child: NotificationListener<ScrollUpdateNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.axis == Axis.horizontal) {
                      final metrics = notification.metrics;
                      final mainState = context.findAncestorStateOfType<MainLayoutState>();
                      if (mainState != null && mainState.pageController.hasClients) {
                        // User is heavily swiping past the edges
                        if (metrics.pixels < metrics.minScrollExtent - 20) {
                          // Swiped right at left edge (Create Post -> Explore)
                          mainState.pageController.animateToPage(
                            1, // Explore is index 1
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.ease,
                          );
                        } else if (metrics.pixels > metrics.maxScrollExtent + 20) {
                          // Swiped left at right edge (My Posts -> Messages)
                          mainState.pageController.animateToPage(
                            3, // Messages is index 3
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.ease,
                          );
                        }
                      }
                    }
                    return false;
                  },
                  child: const TabBarView(
                    physics: BouncingScrollPhysics(),
                    children: [
                      _CreatePostTab(),
                      _MyPostsTab(),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
      );

      await postRef.set(newPost.toMap());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post published successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset form
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
          backgroundColor: Colors.red,
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
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'What do you want to share?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPostType,
              decoration: const InputDecoration(
                labelText: 'Post Type',
                border: OutlineInputBorder(),
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Need help with DSA',
                border: OutlineInputBorder(),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Explain what you need or what you can offer...',
                border: OutlineInputBorder(),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Description is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma separated)',
                hintText: 'Flutter, UI/UX, DSA',
                border: OutlineInputBorder(),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'At least one tag is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _availabilityController,
              decoration: const InputDecoration(
                labelText: 'Availability (Optional)',
                hintText: 'e.g. Weekends / Evenings',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _submitPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted!'), backgroundColor: Colors.red),
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
    if (user == null) return const Center(child: CircularProgressIndicator());

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: user.id) // Only my posts
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading my posts.'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "You haven't made any posts yet.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final post = PostModel.fromMap(data, docs[index].id);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            post.postType,
                            style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                              onPressed: () => _editPost(context, post),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                              onPressed: () => _deletePost(context, post.id),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(post.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(post.description, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                  ],
                ),
              ),
            );
          },
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
        const SnackBar(content: Text('Post updated!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Go back

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
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedPostType,
                    decoration: const InputDecoration(labelText: 'Post Type', border: OutlineInputBorder()),
                    items: _postTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedPostType = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Description is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tagsController,
                    decoration: const InputDecoration(labelText: 'Tags (comma separated)', border: OutlineInputBorder()),
                    validator: (val) => val == null || val.trim().isEmpty ? 'At least one tag is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _availabilityController,
                    decoration: const InputDecoration(labelText: 'Availability (Optional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _updatePost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
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
