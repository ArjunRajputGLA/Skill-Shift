import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/farrey_models.dart';
import '../theme/farrey_colors.dart';
import '../services/farrey_database_service.dart';
import '../../services/auth_service.dart';

class NotePreviewScreen extends StatefulWidget {
  final FarreyNoteModel note;

  const NotePreviewScreen({super.key, required this.note});

  @override
  State<NotePreviewScreen> createState() => _NotePreviewScreenState();
}

class _NotePreviewScreenState extends State<NotePreviewScreen> {
  final FarreyDatabaseService _dbService = FarreyDatabaseService();
  final TextEditingController _commentController = TextEditingController();
  
  bool _isSaved = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthService>().currentUser;
      if (user != null) {
        setState(() => _currentUserId = user.id);
        _checkIfSaved(user.id);
      }
    });
    
    // In a real app, we would also increment the totalViews here.
  }

  void _checkIfSaved(String uid) {
    _dbService.isNoteSaved(uid, widget.note.noteId).listen((isSaved) {
      if (mounted) {
        setState(() => _isSaved = isSaved);
      }
    });
  }

  void _toggleSave() {
    if (_currentUserId == null) return;
    _dbService.toggleSaveNote(_currentUserId!, widget.note.noteId, !_isSaved);
  }

  void _postComment() async {
    if (_commentController.text.trim().isEmpty || _currentUserId == null) return;

    final comment = FarreyCommentModel(
      commentId: DateTime.now().millisecondsSinceEpoch.toString(),
      noteId: widget.note.noteId,
      senderUid: _currentUserId!,
      text: _commentController.text.trim(),
      timestamp: DateTime.now(),
    );

    final error = await _dbService.addComment(comment);
    if (error == null) {
      _commentController.clear();
      FocusScope.of(context).unfocus();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $error')));
      }
    }
  }

  void _showRatingDialog() {
    // A simple rating dialog (1-5 stars)
    int selectedRating = 5;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Rate this note', style: TextStyle(color: FarreyColors.textPrimary)),
              backgroundColor: FarreyColors.surface,
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      color: FarreyColors.warning,
                      size: 32,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        selectedRating = index + 1;
                      });
                    },
                  );
                }),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: FarreyColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    // In a full implementation, this would save to Firestore and update average
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thanks for rating!'), backgroundColor: FarreyColors.success),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: FarreyColors.primary),
                  child: const Text('Submit', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isPdf = widget.note.fileType.toLowerCase() == 'pdf';

    return Scaffold(
      backgroundColor: FarreyColors.background,
      appBar: AppBar(
        backgroundColor: FarreyColors.surface,
        elevation: 1,
        title: Text(widget.note.title, style: const TextStyle(color: FarreyColors.textPrimary, fontSize: 16)),
        iconTheme: const IconThemeData(color: FarreyColors.textPrimary),
        actions: [
          IconButton(
            icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border, color: _isSaved ? FarreyColors.primary : FarreyColors.textSecondary),
            onPressed: _toggleSave,
          ),
          IconButton(
            icon: const Icon(Icons.star_rate, color: FarreyColors.warning),
            onPressed: _showRatingDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. PDF / Image Viewer
          Expanded(
            flex: 6,
            child: Container(
              color: FarreyColors.surfaceElevated,
              child: isPdf
                  ? SfPdfViewer.network(widget.note.fileUrl)
                  : Image.network(
                      widget.note.fileUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator(color: FarreyColors.primary));
                      },
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Text('Failed to load image', style: TextStyle(color: FarreyColors.error)),
                      ),
                    ),
            ),
          ),
          
          // 2. Note Metadata Area
          Container(
            padding: const EdgeInsets.all(16),
            color: FarreyColors.surface,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.note.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FarreyColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'By ${widget.note.uploaderName} • ${widget.note.subject}',
                  style: const TextStyle(color: FarreyColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.note.description,
                  style: const TextStyle(color: FarreyColors.textPrimary, fontSize: 14),
                ),
              ],
            ),
          ),

          // 3. Comments Section Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: FarreyColors.surfaceElevated,
            child: const Text(
              'Discussion',
              style: TextStyle(fontWeight: FontWeight.bold, color: FarreyColors.textPrimary),
            ),
          ),

          // 4. Comments List
          Expanded(
            flex: 4,
            child: StreamBuilder<List<FarreyCommentModel>>(
              stream: _dbService.getNoteComments(widget.note.noteId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: FarreyColors.primary));
                }
                
                final comments = snapshot.data ?? [];
                
                if (comments.isEmpty) {
                  return const Center(
                    child: Text('No comments yet. Be the first to start a discussion!', style: TextStyle(color: FarreyColors.textSecondary)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: FarreyColors.primary.withValues(alpha: 0.2),
                            child: const Icon(Icons.person, size: 16, color: FarreyColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: FarreyColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: FarreyColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comment.text,
                                    style: const TextStyle(color: FarreyColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 5. Add Comment Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: FarreyColors.surface,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(color: FarreyColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: const TextStyle(color: FarreyColors.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: FarreyColors.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: FarreyColors.primary),
                    onPressed: _postComment,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
