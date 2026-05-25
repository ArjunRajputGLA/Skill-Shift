import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
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
    int selectedRating = 5;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Rate this note', style: TextStyle(color: context.farreyTextPrimary)),
              backgroundColor: context.farreySurface,
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: Icon(
                      index < selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: context.farreyWarning,
                      size: 28,
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
                  child: Text('Cancel', style: TextStyle(color: context.farreyTextSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text('Thanks for rating!'), backgroundColor: context.farreySuccess),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: context.farreyPrimary),
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
      backgroundColor: context.farreyBackground,
      body: Stack(
        children: [
          // Main Content Area
          Column(
            children: [
              // 1. PDF / Image Viewer (Takes up space but leaves room for header)
              Expanded(
                flex: 6,
                child: Container(
                  padding: const EdgeInsets.only(top: 100), // Push below floating header
                  color: context.farreySurfaceElevated,
                  child: isPdf
                      ? SfPdfViewer.network(widget.note.fileUrl)
                      : CachedNetworkImage(
                          imageUrl: widget.note.fileUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Center(child: CircularProgressIndicator(color: context.farreyPrimary)),
                          errorWidget: (context, url, error) => Center(
                            child: Text('Failed to load image', style: TextStyle(color: context.farreyError)),
                          ),
                        ),
                ),
              ),
              
              // 2. Note Metadata Area
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.farreySurface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.note.title,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.farreyTextPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By ${widget.note.uploaderName} • ${widget.note.subject}',
                      style: TextStyle(color: context.farreyTextSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.note.description,
                      style: TextStyle(color: context.farreyTextPrimary, fontSize: 14),
                    ),
                  ],
                ),
              ),

              // 3. Comments Section Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                color: context.farreyBackground,
                child: Text(
                  'Discussion',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: context.farreyTextPrimary),
                ),
              ),

              // 4. Comments List
              Expanded(
                flex: 4,
                child: Container(
                  color: context.farreyBackground,
                  child: StreamBuilder<List<FarreyCommentModel>>(
                    stream: _dbService.getNoteComments(widget.note.noteId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: context.farreyPrimary));
                      }
                      
                      final comments = snapshot.data ?? [];
                      
                      if (comments.isEmpty) {
                        return Center(
                          child: Text('No comments yet. Be the first to start a discussion!', style: TextStyle(color: context.farreyTextSecondary)),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(24),
                        physics: const BouncingScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: context.farreyPrimary.withValues(alpha: 0.1),
                                  child: Icon(Icons.person_rounded, size: 18, color: context.farreyPrimary),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: context.farreySurface,
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(16),
                                        bottomLeft: Radius.circular(16),
                                        bottomRight: Radius.circular(16),
                                      ),
                                      border: Border.all(color: context.farreyBorder),
                                    ),
                                    child: Text(
                                      comment.text,
                                      style: TextStyle(color: context.farreyTextPrimary, height: 1.4),
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
              ),

              // 5. Add Comment Input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: context.farreySurface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: TextStyle(color: context.farreyTextPrimary),
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: TextStyle(color: context.farreyTextSecondary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: context.farreyBackground,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: context.farreyPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.white),
                          onPressed: _postComment,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Floating Header
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.farreySurface.withValues(alpha: context.isDark ? 0.7 : 0.8),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: context.isDark 
                              ? Colors.white.withValues(alpha: 0.05) 
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back_rounded, color: context.farreyTextPrimary, size: 20),
                            onPressed: () => Navigator.pop(context),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                            splashRadius: 20,
                          ),
                          Container(
                            constraints: const BoxConstraints(maxWidth: 120),
                            child: Text(
                              widget.note.title,
                              style: TextStyle(
                                color: context.farreyTextPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(_isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, 
                              color: _isSaved ? context.farreyPrimary : context.farreyTextSecondary, size: 20),
                            onPressed: _toggleSave,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                            splashRadius: 20,
                          ),
                          IconButton(
                            icon: Icon(Icons.star_rounded, color: context.farreyWarning, size: 20),
                            onPressed: _showRatingDialog,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                            splashRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
