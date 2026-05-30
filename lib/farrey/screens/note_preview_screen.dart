import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/farrey_models.dart';
import '../theme/farrey_colors.dart';
import '../theme/farrey_colors.dart';
import '../services/farrey_database_service.dart';
import '../../services/auth_service.dart';
import 'farrey_edit_note_screen.dart';
import '../../screens/public_profile_screen.dart';
import '../services/ai_notes_service.dart';
import '../services/gemini_ai_service.dart';
import '../services/flashcard_service.dart';
import '../models/farrey_ai_analysis.dart';
import '../widgets/ai_summary_card.dart';
import 'flashcard_study_screen.dart';
import 'quiz_screen.dart';
import 'doubt_solver_screen.dart';
class NotePreviewScreen extends StatefulWidget {
  final FarreyNoteModel note;

  const NotePreviewScreen({super.key, required this.note});

  @override
  State<NotePreviewScreen> createState() => _NotePreviewScreenState();
}

class _NotePreviewScreenState extends State<NotePreviewScreen> with SingleTickerProviderStateMixin {
  final FarreyDatabaseService _dbService = FarreyDatabaseService();
  final TextEditingController _commentController = TextEditingController();
  
  bool _isSaved = false;
  bool _hasRated = false;
  String? _currentUserId;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  FarreyAiAnalysis? _aiAnalysis;
  bool _isLoadingAi = false;
  String? _aiError;

  bool _hasStudyMaterial = false;
  bool _isGeneratingStudyMaterial = false;
  String? _studyMaterialError;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthService>().currentUser;
      if (user != null) {
        setState(() => _currentUserId = user.id);
        _checkIfSaved(user.id);
        
        _dbService.hasUserRated(widget.note.noteId, user.id).listen((hasRated) {
          if (mounted) {
            setState(() => _hasRated = hasRated);
            if (hasRated) _glowController.stop();
          }
        });
      }
    });

    _loadAiAnalysis();
    _checkStudyMaterial();
  }

  Future<void> _checkStudyMaterial() async {
    try {
      final flashcards = await FlashcardService().getFlashcards(widget.note.noteId);
      if (mounted && flashcards.isNotEmpty) {
        setState(() => _hasStudyMaterial = true);
      }
    } catch (e) {
      debugPrint("Error checking study material: $e");
    }
  }

  Future<void> _generateStudyMaterial() async {
    if (widget.note.fileUrls.isEmpty) return;
    
    setState(() {
      _isGeneratingStudyMaterial = true;
      _studyMaterialError = null;
    });

    try {
      await GeminiAiService().generateStudyMaterial(
        widget.note.noteId, 
        widget.note.fileUrls, 
        widget.note.fileTypes
      );
      
      if (mounted) {
        setState(() => _hasStudyMaterial = true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Study material generated successfully!'),
          backgroundColor: context.farreySuccess,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _studyMaterialError = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingStudyMaterial = false);
      }
    }
  }

  Future<void> _loadAiAnalysis() async {
    if (widget.note.fileUrls.isEmpty) return;
    
    setState(() => _isLoadingAi = true);
    try {
      final analysis = await AiNotesService().getAnalysis(
        widget.note.noteId, 
        widget.note.fileUrls, 
        widget.note.fileTypes
      );
      if (mounted) setState(() => _aiAnalysis = analysis);
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains('503 Service Unavailable') || errorMsg.contains('high demand')) {
          errorMsg = "The AI is currently experiencing high demand. Please try again in a few moments.";
        } else if (errorMsg.contains('internal') || errorMsg.contains('firebase_functions')) {
          errorMsg = "Failed to generate AI analysis. The server might be overloaded. Please try again later.";
        } else {
          // Fallback, limit length to not bloat UI
          errorMsg = errorMsg.length > 100 ? errorMsg.substring(0, 100) + '...' : errorMsg;
        }
        setState(() => _aiError = errorMsg);
      }
    } finally {
      if (mounted) setState(() => _isLoadingAi = false);
    }
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

  Future<void> _showRatingDialog() async {
    int selectedRating = 0;
    String reviewText = '';
    bool isSubmitting = false;
    bool isLoading = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            
            if (isLoading) {
              if (_hasRated && _currentUserId != null) {
                _dbService.getUserReview(widget.note.noteId, _currentUserId!).then((review) {
                  if (context.mounted) {
                    setDialogState(() {
                      if (review != null) {
                        selectedRating = review.rating.toInt();
                        reviewText = review.reviewText;
                      }
                      isLoading = false;
                    });
                  }
                });
              } else {
                isLoading = false;
              }
            }

            int wordCount = reviewText.trim().isEmpty ? 0 : reviewText.trim().split(RegExp(r'\s+')).length;
            bool isValid = selectedRating > 0 && wordCount >= 8;

            return AlertDialog(
              title: Text(_hasRated ? 'Edit Review' : 'Write a Review', style: TextStyle(color: context.farreyTextPrimary)),
              backgroundColor: context.farreySurface,
              content: isLoading || isSubmitting
                  ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 4,
                            children: List.generate(5, (index) {
                              final isSelected = index < selectedRating;
                              return InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () {
                                  setDialogState(() {
                                    selectedRating = index + 1;
                                  });
                                },
                                child: AnimatedScale(
                                  scale: isSelected ? 1.2 : 1.0,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutBack,
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Icon(
                                      isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                                      color: context.farreyWarning,
                                      size: 36,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: reviewText,
                            maxLines: 3,
                            style: TextStyle(color: context.farreyTextPrimary),
                            decoration: InputDecoration(
                              hintText: 'Share your thoughts on this note...',
                              hintStyle: TextStyle(color: context.farreyTextSecondary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.farreyBorder)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.farreyPrimary)),
                            ),
                            onChanged: (val) {
                              setDialogState(() {
                                reviewText = val;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '$wordCount / 8 words min',
                              style: TextStyle(
                                color: wordCount >= 8 ? context.farreySuccess : context.farreyWarning,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              actions: [
                if (!isLoading && !isSubmitting)
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text('Cancel', style: TextStyle(color: context.farreyTextSecondary)),
                  ),
                if (!isLoading && !isSubmitting)
                  ElevatedButton(
                    onPressed: isValid ? () async {
                      setDialogState(() {
                        isSubmitting = true;
                      });
                      
                      if (_currentUserId != null && context.mounted) {
                        final user = context.read<AuthService>().currentUser;
                        final name = user?.fullName ?? 'Anonymous';
                        final photo = user?.profileImageUrl; // using profileImageUrl if available
                        
                        final error = await _dbService.submitRating(
                          widget.note.noteId, 
                          _currentUserId!, 
                          name,
                          photo,
                          selectedRating.toDouble(),
                          reviewText.trim(),
                        );
                        
                        if (context.mounted) {
                          Navigator.pop(dialogContext); // Close dialog
                          if (error == null) {
                            setState(() {
                              _hasRated = true;
                              _glowController.stop();
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: const Text('Review saved successfully!'), backgroundColor: context.farreySuccess),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error), backgroundColor: context.farreyError),
                            );
                          }
                        }
                      }
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.farreyPrimary,
                      disabledBackgroundColor: context.farreyBorder,
                    ),
                    child: const Text('Submit', style: TextStyle(color: Colors.white)),
                  ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _downloadFile() async {
    final Uri url = Uri.parse(widget.note.fileUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      _dbService.incrementDownloads(widget.note.noteId);
      if (mounted) {
        setState(() {
          widget.note.totalDownloads += 1;
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch download link', style: TextStyle(color: context.farreyError))));
      }
    }
  }

  Future<void> _deleteNote() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: context.farreySurface,
        title: Text('Delete Note?', style: TextStyle(color: context.farreyError)),
        content: Text('This action cannot be undone.', style: TextStyle(color: context.farreyTextPrimary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('Cancel', style: TextStyle(color: context.farreyTextSecondary))),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: context.farreyError), child: const Text('Delete', style: TextStyle(color: Colors.white))),
        ],
      )
    );
    if (confirm == true) {
      final error = await _dbService.deleteNote(widget.note.noteId, widget.note.fileUrl);
      if (error == null && mounted) {
        Navigator.pop(context); // Go back to previous screen
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Note deleted'), backgroundColor: context.farreySuccess));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $error'), backgroundColor: context.farreyError));
      }
    }
  }

  Future<void> _reportNote() async {
    if (_currentUserId == null) return;
    
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.farreySurface,
        title: Text('Report Note', style: TextStyle(color: context.farreyError)),
        content: Text('Are you sure you want to report this note for inappropriate content?', style: TextStyle(color: context.farreyTextPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: context.farreyTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: context.farreyError),
            child: const Text('Report', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    final error = await _dbService.reportNote(widget.note.noteId, _currentUserId!);
    if (mounted) {
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Note reported. Thank you for keeping the community safe.'), backgroundColor: context.farreySuccess),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: context.farreyError),
        );
      }
    }
  }

  void _shareNote() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.farreySurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.farreyBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Share Note',
                style: TextStyle(
                  color: context.farreyTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.farreyPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.link_rounded, color: context.farreyPrimary),
                ),
                title: Text('Share Note Info', style: TextStyle(color: context.farreyTextPrimary)),
                subtitle: Text('Share title and uploader details', style: TextStyle(color: context.farreyTextSecondary, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  Share.share(
                    'Check out "${widget.note.title}" by ${widget.note.uploaderName} on Skill Shift!\n\nSubject: ${widget.note.subject}\n\nDownload the app to explore more notes and study materials!'
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.farreySecondary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.file_copy_rounded, color: context.farreySecondary),
                ),
                title: Text('Share Document Links', style: TextStyle(color: context.farreyTextPrimary)),
                subtitle: Text('Share direct links to all attached files', style: TextStyle(color: context.farreyTextSecondary, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  
                  String docsText = 'Here are the documents for "${widget.note.title}":\n\n';
                  for (int i = 0; i < widget.note.fileUrls.length; i++) {
                    final name = widget.note.fileNames.length > i ? widget.note.fileNames[i] : 'File ${i + 1}';
                    final url = widget.note.fileUrls[i];
                    docsText += '${i + 1}. $name:\n$url\n\n';
                  }
                  docsText += 'Shared via Skill Shift App';
                  
                  Share.share(docsText);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editNote() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => FarreyEditNoteScreen(note: widget.note)));
    if (result == true && mounted) {
      setState((){});
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.farreyBackground,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoubtSolverScreen(note: widget.note),
            ),
          );
        },
        backgroundColor: context.farreyPrimary,
        icon: const Icon(Icons.psychology, color: Colors.white),
        label: const Text('Ask AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      appBar: AppBar(
        title: Text(widget.note.title, style: TextStyle(color: context.farreyTextPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: context.farreyBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: context.farreyTextPrimary),
        actions: [
          if (_currentUserId != null && _currentUserId == widget.note.uploaderUid) ...[
            IconButton(
              icon: Icon(Icons.edit_rounded, color: context.farreySecondary),
              onPressed: _editNote,
              tooltip: 'Edit Note',
            ),
            IconButton(
              icon: Icon(Icons.delete_rounded, color: context.farreyError),
              onPressed: _deleteNote,
              tooltip: 'Delete Note',
            ),
          ] else if (_currentUserId != null && _currentUserId != widget.note.uploaderUid) ...[
            IconButton(
              icon: Icon(Icons.report_rounded, color: context.farreyError),
              onPressed: _reportNote,
              tooltip: 'Report Note',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Metadata Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: context.farreySurface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.note.title,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.farreyTextPrimary),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: widget.note.uploaderUid)));
                          },
                          child: Text(
                            'By ${widget.note.uploaderName} • ${widget.note.subject}',
                            style: TextStyle(color: context.farreyPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.note.description,
                          style: TextStyle(color: context.farreyTextPrimary, fontSize: 15, height: 1.5),
                        ),
                        const SizedBox(height: 20),
                        
                        // Action Buttons (Rating, Save, Share)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              GestureDetector(
                              onTap: _showRatingDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: context.farreyWarning.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _hasRated 
                                      ? Icon(Icons.star_rounded, color: context.farreyWarning, size: 20)
                                      : FadeTransition(
                                          opacity: _glowAnimation,
                                          child: Icon(Icons.star_rounded, color: context.farreyWarning, size: 20),
                                        ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${widget.note.averageRating.toStringAsFixed(1)} (${widget.note.totalRatings})',
                                      style: TextStyle(color: context.farreyWarning, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: _toggleSave,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _isSaved ? context.farreyPrimary.withValues(alpha: 0.1) : context.farreyBackground,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _isSaved ? context.farreyPrimary.withValues(alpha: 0.3) : context.farreyBorder),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                      color: _isSaved ? context.farreyPrimary : context.farreyTextSecondary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isSaved ? 'Saved' : 'Save',
                                      style: TextStyle(
                                        color: _isSaved ? context.farreyPrimary : context.farreyTextSecondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: _shareNote,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: context.farreyPrimary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: context.farreyPrimary.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.share_rounded, color: context.farreyPrimary, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Share',
                                      style: TextStyle(
                                        color: context.farreyPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ],
                    ),
                  ),
                  
                  // AI Section Injection
                  if (_isLoadingAi)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: context.farreyPrimary),
                            const SizedBox(height: 12),
                            Text("✨ AI is analyzing this document...", style: TextStyle(color: context.farreyTextSecondary, fontWeight: FontWeight.w600)),
                          ]
                        )
                      ),
                    )
                  else if (_aiError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                      child: Text("AI Analysis unavailable: $_aiError", style: TextStyle(color: context.farreyError, fontSize: 13)),
                    )
                  else if (_aiAnalysis != null)
                    AiSummaryCard(analysis: _aiAnalysis!),

                  // Study Material Section
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.farreySurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.farreyPrimary.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.school_rounded, color: context.farreyPrimary),
                              const SizedBox(width: 8),
                              Text("Study Material", style: TextStyle(color: context.farreyTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_hasStudyMaterial) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FlashcardStudyScreen(noteId: widget.note.noteId))),
                                    icon: const Icon(Icons.flip_to_front_rounded, color: Colors.white),
                                    label: const Text("Flashcards", style: TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: context.farreyPrimary,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(noteId: widget.note.noteId))),
                                    icon: const Icon(Icons.quiz_rounded, color: Colors.white),
                                    label: const Text("Take Quiz", style: TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: context.farreySecondary,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else if (_isGeneratingStudyMaterial) ...[
                            const Center(child: CircularProgressIndicator()),
                            const SizedBox(height: 8),
                            Center(child: Text("Generating Flashcards & Quizzes...", style: TextStyle(color: context.farreyTextSecondary))),
                          ] else ...[
                            if (_studyMaterialError != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text("Error: $_studyMaterialError", style: TextStyle(color: context.farreyError, fontSize: 12)),
                              ),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _generateStudyMaterial,
                                icon: const Icon(Icons.auto_awesome, color: Colors.white),
                                label: const Text("Generate Flashcards & Quiz with AI", style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: context.farreyPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  
                  // Files Attached Section
                  if (widget.note.fileUrls.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                      child: Row(
                        children: [
                          Icon(Icons.folder_open_rounded, color: context.farreyTextSecondary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Attached Files (${widget.note.fileUrls.length})',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: context.farreyTextPrimary),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: widget.note.fileUrls.length,
                        itemBuilder: (context, index) {
                          final url = widget.note.fileUrls[index];
                          final type = widget.note.fileTypes.length > index ? widget.note.fileTypes[index] : 'unknown';
                          final name = widget.note.fileNames.length > index ? widget.note.fileNames[index] : 'File ${index + 1}';
                          
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => FilePreviewScreen(url: url, type: type, name: name, noteId: widget.note.noteId)));
                            },
                            child: Container(
                              width: 120,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: context.farreySurface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: context.farreyBorder),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    type.toLowerCase() == 'pdf' ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                                    size: 40,
                                    color: type.toLowerCase() == 'pdf' ? context.farreyError : context.farreySecondary,
                                  ),
                                  const SizedBox(height: 12),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text(
                                      name,
                                      style: TextStyle(color: context.farreyTextPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // Reviews Section Header
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Row(
                      children: [
                        Icon(Icons.reviews_rounded, color: context.farreyTextSecondary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Reviews',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: context.farreyTextPrimary),
                        ),
                      ],
                    ),
                  ),

                  // Reviews List
                  StreamBuilder<List<FarreyReviewModel>>(
                    stream: _dbService.getNoteReviews(widget.note.noteId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: Padding(padding: const EdgeInsets.all(24.0), child: CircularProgressIndicator(color: context.farreyPrimary)));
                      }
                      
                      final reviews = snapshot.data ?? [];
                      
                      if (reviews.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Center(
                            child: Text('No reviews yet. Be the first to leave one!', style: TextStyle(color: context.farreyTextSecondary)),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          final review = reviews[index];
                          final isMe = review.userId == _currentUserId;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: review.userId)));
                                  },
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: context.farreyPrimary.withValues(alpha: 0.1),
                                    backgroundImage: review.userPhotoUrl != null ? CachedNetworkImageProvider(review.userPhotoUrl!) : null,
                                    child: review.userPhotoUrl == null ? Icon(Icons.person_rounded, size: 20, color: context.farreyPrimary) : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () {
                                                Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: review.userId)));
                                              },
                                              child: Text(
                                                review.userName + (isMe ? ' (You)' : ''),
                                                style: TextStyle(fontWeight: FontWeight.bold, color: context.farreyTextPrimary, fontSize: 13),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Row(
                                            children: [
                                              if (review.isEdited)
                                                Text('(edited) ', style: TextStyle(color: context.farreyTextSecondary, fontSize: 11, fontStyle: FontStyle.italic)),
                                              Icon(Icons.star_rounded, color: context.farreyWarning, size: 14),
                                              const SizedBox(width: 2),
                                              Text(
                                                review.rating.toStringAsFixed(1),
                                                style: TextStyle(color: context.farreyWarning, fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                              if (isMe) ...[
                                                const SizedBox(width: 8),
                                                PopupMenuButton<String>(
                                                  padding: EdgeInsets.zero,
                                                  iconSize: 18,
                                                  icon: Icon(Icons.more_vert_rounded, color: context.farreyTextSecondary),
                                                  onSelected: (value) async {
                                                    if (value == 'edit') {
                                                      _showRatingDialog();
                                                    } else if (value == 'delete') {
                                                      final confirm = await showDialog<bool>(
                                                        context: context,
                                                        builder: (c) => AlertDialog(
                                                          backgroundColor: context.farreySurface,
                                                          title: Text('Delete Review?', style: TextStyle(color: context.farreyError)),
                                                          content: Text('Are you sure you want to delete your review?', style: TextStyle(color: context.farreyTextPrimary)),
                                                          actions: [
                                                            TextButton(onPressed: () => Navigator.pop(c, false), child: Text('Cancel', style: TextStyle(color: context.farreyTextSecondary))),
                                                            ElevatedButton(
                                                              onPressed: () => Navigator.pop(c, true),
                                                              style: ElevatedButton.styleFrom(backgroundColor: context.farreyError),
                                                              child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                      
                                                      if (confirm == true && mounted) {
                                                        final error = await _dbService.deleteReview(widget.note.noteId, _currentUserId!);
                                                        if (mounted) {
                                                          if (error == null) {
                                                            setState(() {
                                                              _hasRated = false;
                                                              if (_glowController.isAnimating == false) {
                                                                _glowController.repeat(reverse: true);
                                                              }
                                                            });
                                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Review deleted.'), backgroundColor: context.farreySuccess));
                                                          } else {
                                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: context.farreyError));
                                                          }
                                                        }
                                                      }
                                                    }
                                                  },
                                                  itemBuilder: (context) => [
                                                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: context.farreySurfaceElevated,
                                          borderRadius: const BorderRadius.only(
                                            topRight: Radius.circular(16),
                                            bottomLeft: Radius.circular(16),
                                            bottomRight: Radius.circular(16),
                                          ),
                                          border: Border.all(color: context.farreyBorder.withValues(alpha: 0.5)),
                                        ),
                                        child: Text(
                                          review.reviewText,
                                          style: TextStyle(color: context.farreyTextPrimary, height: 1.4, fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24), // padding at bottom of scroll
                ],
              ),
            ),
          ),
          
          const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class FilePreviewScreen extends StatelessWidget {
  final String url;
  final String type;
  final String name;
  final String noteId;

  const FilePreviewScreen({super.key, required this.url, required this.type, required this.name, required this.noteId});

  Future<void> _download(BuildContext context) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      FarreyDatabaseService().incrementDownloads(noteId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch download link', style: TextStyle(color: context.farreyError))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPdf = type.toLowerCase() == 'pdf';
    final isImage = type.toLowerCase() == 'jpg' || type.toLowerCase() == 'jpeg' || type.toLowerCase() == 'png' || type.toLowerCase() == 'gif' || type.toLowerCase() == 'webp';

    return Scaffold(
      backgroundColor: context.farreyBackground,
      appBar: AppBar(
        backgroundColor: context.farreyBackground,
        title: Text(name, style: TextStyle(color: context.farreyTextPrimary, fontSize: 16)),
        iconTheme: IconThemeData(color: context.farreyTextPrimary),
        actions: [
          IconButton(
            icon: Icon(Icons.download_rounded, color: context.farreySecondary),
            onPressed: () => _download(context),
            tooltip: 'Download',
          ),
        ],
      ),
      body: isPdf
          ? SfPdfViewer.network(url)
          : isImage
              ? Center(
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Center(child: CircularProgressIndicator(color: context.farreyPrimary)),
                    errorWidget: (context, url, error) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: context.farreyError, size: 48),
                        const SizedBox(height: 16),
                        Text('Failed to load image.', style: TextStyle(color: context.farreyTextPrimary)),
                      ],
                    ),
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.insert_drive_file_outlined, size: 64, color: context.farreySecondary),
                      const SizedBox(height: 24),
                      Text(
                        'Preview not available for this file type.',
                        style: TextStyle(color: context.farreyTextPrimary, fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _download(context),
                        icon: const Icon(Icons.download, color: Colors.white),
                        label: const Text('Download to View', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.farreyPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
