import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../theme/farrey_colors.dart';
import '../services/farrey_database_service.dart';
import '../services/farrey_storage_service.dart';
import '../models/farrey_models.dart';
import 'note_preview_screen.dart';

class FarreyEditNoteScreen extends StatefulWidget {
  final FarreyNoteModel note;

  const FarreyEditNoteScreen({super.key, required this.note});

  @override
  State<FarreyEditNoteScreen> createState() => _FarreyEditNoteScreenState();
}

class _FarreyEditNoteScreenState extends State<FarreyEditNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _subjectController;
  late TextEditingController _semesterController;
  late TextEditingController _tagsController;
  late TextEditingController _branchController;

  bool _isSaving = false;
  final FarreyDatabaseService _dbService = FarreyDatabaseService();
  final FarreyStorageService _storageService = FarreyStorageService();

  List<String> _existingFileUrls = [];
  List<String> _existingFileTypes = [];
  List<String> _existingFileNames = [];
  
  List<PlatformFile> _newSelectedFiles = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _descController = TextEditingController(text: widget.note.description);
    _subjectController = TextEditingController(text: widget.note.subject);
    _semesterController = TextEditingController(text: widget.note.semester);
    _tagsController = TextEditingController(text: widget.note.tags.join(', '));
    _branchController = TextEditingController(text: widget.note.branch);
    
    _existingFileUrls = List.from(widget.note.fileUrls);
    _existingFileTypes = List.from(widget.note.fileTypes);
    _existingFileNames = List.from(widget.note.fileNames);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx'],
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _newSelectedFiles.addAll(result.files.where((f) => f.path != null));
      });
    }
  }

  Future<void> _updateNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      List<String> finalFileUrls = List.from(_existingFileUrls);
      List<String> finalFileTypes = List.from(_existingFileTypes);
      List<String> finalFileNames = List.from(_existingFileNames);

      for (var pFile in _newSelectedFiles) {
        final file = File(pFile.path!);
        final ext = pFile.extension ?? 'unknown';
        final name = pFile.name;
        
        final downloadUrl = await _storageService.uploadNoteFile(file, ext);
        finalFileUrls.add(downloadUrl);
        finalFileTypes.add(ext);
        finalFileNames.add(name);
      }

      final tagsList = _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      final updatedNote = FarreyNoteModel(
        noteId: widget.note.noteId,
        uploaderUid: widget.note.uploaderUid,
        uploaderName: widget.note.uploaderName,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        subject: _subjectController.text.trim(),
        semester: _semesterController.text.trim(),
        tags: tagsList,
        branch: _branchController.text.trim(),
        fileUrl: finalFileUrls.isNotEmpty ? finalFileUrls.first : '',
        fileType: finalFileTypes.isNotEmpty ? finalFileTypes.first : '',
        fileUrls: finalFileUrls,
        fileTypes: finalFileTypes,
        fileNames: finalFileNames,
        uploadTime: widget.note.uploadTime,
        totalDownloads: widget.note.totalDownloads,
        totalComments: widget.note.totalComments,
        averageRating: widget.note.averageRating,
        totalRatings: widget.note.totalRatings,
      );

      final error = await _dbService.updateNoteMetadata(updatedNote);

      if (error == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Note updated successfully!'), backgroundColor: context.farreySuccess),
          );
          Navigator.pop(context, true); // Pop true to indicate it was updated
        }
      } else {
        throw Exception(error);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: context.farreyError),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _subjectController.dispose();
    _semesterController.dispose();
    _tagsController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.farreyBackground,
      appBar: AppBar(
        title: Text('Edit Note', style: TextStyle(color: context.farreyTextPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: context.farreyTextPrimary),
      ),
      body: _isSaving
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: context.farreyPrimary),
                  const SizedBox(height: 16),
                  Text('Saving changes...', style: TextStyle(color: context.farreyTextSecondary)),
                ],
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(context, _titleController, 'Title', 'E.g., Operating Systems Unit 1'),
                    const SizedBox(height: 16),
                    _buildTextField(context, _descController, 'Description', 'What is this note about?', maxLines: 3),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(context, _subjectController, 'Subject', 'E.g., OS')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(context, _semesterController, 'Semester', 'E.g., 5th')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(context, _branchController, 'Branch', 'E.g., Computer Science'),
                    const SizedBox(height: 16),
                    _buildTextField(context, _tagsController, 'Tags (Comma separated)', 'E.g., scheduling, threads, memory'),
                    const SizedBox(height: 24),
                    
                    Text('Files Attached', style: TextStyle(color: context.farreyTextPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    if (_existingFileUrls.isEmpty && _newSelectedFiles.isEmpty)
                      Text('No files attached.', style: TextStyle(color: context.farreyTextSecondary)),
                    
                    // Existing files list
                    if (_existingFileUrls.isNotEmpty)
                      ReorderableListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) {
                              newIndex -= 1;
                            }
                            final url = _existingFileUrls.removeAt(oldIndex);
                            _existingFileUrls.insert(newIndex, url);
                            
                            if (oldIndex < _existingFileTypes.length) {
                              final type = _existingFileTypes.removeAt(oldIndex);
                              if (newIndex <= _existingFileTypes.length) {
                                _existingFileTypes.insert(newIndex, type);
                              }
                            }
                            
                            if (oldIndex < _existingFileNames.length) {
                              final name = _existingFileNames.removeAt(oldIndex);
                              if (newIndex <= _existingFileNames.length) {
                                _existingFileNames.insert(newIndex, name);
                              }
                            }
                          });
                        },
                        children: _existingFileUrls.asMap().entries.map((entry) {
                          int idx = entry.key;
                          String name = _existingFileNames.length > idx ? _existingFileNames[idx] : 'Document ${idx + 1}';
                          String type = _existingFileTypes.length > idx ? _existingFileTypes[idx] : 'unknown';
                          String url = entry.value;
                          return GestureDetector(
                            key: ValueKey(url),
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => FilePreviewScreen(url: url, type: type, name: name, noteId: widget.note.noteId)));
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: context.farreySurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.farreyBorder),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.drag_indicator, color: context.farreyTextSecondary, size: 20),
                                  const SizedBox(width: 8),
                                  Icon(type.toLowerCase() == 'pdf' ? Icons.picture_as_pdf_rounded : Icons.image_rounded, color: context.farreyPrimary, size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: TextStyle(color: context.farreyTextPrimary, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, color: context.farreyError, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _existingFileUrls.removeAt(idx);
                                        if (_existingFileTypes.length > idx) _existingFileTypes.removeAt(idx);
                                        if (_existingFileNames.length > idx) _existingFileNames.removeAt(idx);
                                      });
                                    },
                                  )
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    // New selected files list
                    if (_newSelectedFiles.isNotEmpty)
                      ReorderableListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) {
                              newIndex -= 1;
                            }
                            final file = _newSelectedFiles.removeAt(oldIndex);
                            _newSelectedFiles.insert(newIndex, file);
                          });
                        },
                        children: _newSelectedFiles.asMap().entries.map((entry) {
                          int idx = entry.key;
                          PlatformFile file = entry.value;
                          return Container(
                            key: ValueKey(file),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.farreyPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.farreyPrimary.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.drag_indicator, color: context.farreyTextSecondary, size: 20),
                                const SizedBox(width: 8),
                                Icon(Icons.insert_drive_file_rounded, color: context.farreyPrimary, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    file.name,
                                    style: TextStyle(color: context.farreyTextPrimary, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: context.farreyError, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _newSelectedFiles.removeAt(idx);
                                    });
                                  },
                                )
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Files'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.farreyPrimary,
                        side: BorderSide(color: context.farreyPrimary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _updateNote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.farreyPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(BuildContext context, TextEditingController controller, String label, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: context.farreyTextPrimary, fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: context.farreyTextPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: context.farreyTextSecondary.withValues(alpha: 0.5)),
            filled: true,
            fillColor: context.farreySurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.farreyPrimary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (value) => value == null || value.trim().isEmpty ? '$label is required' : null,
        ),
      ],
    );
  }
}
