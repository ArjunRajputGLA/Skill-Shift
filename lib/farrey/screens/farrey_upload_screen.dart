import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../theme/farrey_colors.dart';
import '../services/farrey_database_service.dart';
import '../services/farrey_storage_service.dart';
import '../models/farrey_models.dart';
import '../models/farrey_models.dart';
import '../../services/auth_service.dart';
import '../../theme/theme_provider.dart';

class FarreyUploadScreen extends StatefulWidget {
  const FarreyUploadScreen({super.key});

  @override
  State<FarreyUploadScreen> createState() => _FarreyUploadScreenState();
}

class _FarreyUploadScreenState extends State<FarreyUploadScreen> with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _subjectController = TextEditingController();
  final _semesterController = TextEditingController();
  final _tagsController = TextEditingController();
  final _branchController = TextEditingController();

  List<PlatformFile> _selectedFiles = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  final FarreyDatabaseService _dbService = FarreyDatabaseService();
  final FarreyStorageService _storageService = FarreyStorageService();

  @override
  bool get wantKeepAlive => true;

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx'],
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFiles.addAll(result.files.where((f) => f.path != null));
      });
    }
  }

  Future<void> _uploadNote() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please select at least one file to upload.', style: TextStyle(color: Colors.white)), backgroundColor: context.farreyError),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");
      
      List<String> uploadedUrls = [];
      List<String> uploadedTypes = [];
      List<String> uploadedNames = [];

      for (var pFile in _selectedFiles) {
        final file = File(pFile.path!);
        final ext = pFile.extension ?? 'unknown';
        final name = pFile.name;
        
        final int index = _selectedFiles.indexOf(pFile);
        
        final downloadUrl = await _storageService.uploadNoteFile(
          file, 
          ext,
          onProgress: (progress) {
            if (mounted) {
              setState(() {
                _uploadProgress = (index + progress) / _selectedFiles.length;
              });
            }
          }
        );
        uploadedUrls.add(downloadUrl);
        uploadedTypes.add(ext);
        uploadedNames.add(name);
      }

      final newNote = FarreyNoteModel(
        noteId: DateTime.now().millisecondsSinceEpoch.toString(),
        uploaderUid: user.uid,
        uploaderName: user.displayName ?? 'Unknown',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        subject: _subjectController.text.trim(),
        semester: _semesterController.text.trim(),
        branch: _branchController.text.trim(),
        tags: _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        fileUrl: uploadedUrls.isNotEmpty ? uploadedUrls.first : '',
        fileType: uploadedTypes.isNotEmpty ? uploadedTypes.first : '',
        fileUrls: uploadedUrls,
        fileTypes: uploadedTypes,
        fileNames: uploadedNames,
        uploadTime: DateTime.now(),
      );

      final error = await _dbService.uploadNoteMetadata(newNote);

      if (error == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Note uploaded successfully!'), backgroundColor: context.farreySuccess),
          );
          _clearForm();
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
        setState(() => _isUploading = false);
      }
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descController.clear();
    _subjectController.clear();
    _semesterController.clear();
    _tagsController.clear();
    _branchController.clear();
    setState(() {
      _selectedFiles.clear();
    });
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
    super.build(context);
    return Scaffold(
      backgroundColor: context.farreyBackground,
      body: RefreshIndicator(
        color: context.farreyPrimary,
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
          setState(() {});
        },
        child: _isUploading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: _uploadProgress,
                            color: context.farreyPrimary,
                            backgroundColor: context.farreySurface,
                            strokeWidth: 6,
                          ),
                        ),
                        Text(
                          '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: context.farreyPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Uploading your note to Notes Ecosystem...', style: TextStyle(color: context.farreyTextSecondary)),
                  ],
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 120),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // File Picker Area
                      GestureDetector(
                        onTap: _pickFile,
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: context.farreySurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedFiles.isEmpty ? context.farreyPrimary.withValues(alpha: 0.3) : context.farreySuccess,
                              style: BorderStyle.solid,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 40,
                                  color: context.farreyPrimary,
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text(
                                    'Tap to browse files',
                                    style: TextStyle(
                                      color: context.farreyPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_selectedFiles.isNotEmpty) const SizedBox(height: 16),
                      if (_selectedFiles.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _selectedFiles.asMap().entries.map((entry) {
                            int idx = entry.key;
                            PlatformFile file = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: context.farreyPrimary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.farreyPrimary.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
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
                                        _selectedFiles.removeAt(idx);
                                      });
                                    },
                                  )
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 24),
                      
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
                      const SizedBox(height: 32),

                      ElevatedButton(
                        onPressed: _uploadNote,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.farreyPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Upload to Ecosystem',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context,
    TextEditingController controller,
    String label,
    String hint, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: context.farreyTextPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: context.farreyTextSecondary),
        hintStyle: TextStyle(color: context.farreyTextSecondary.withValues(alpha: 0.5)),
        filled: true,
        fillColor: context.farreySurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: context.farreyBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: context.farreyBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: context.farreyPrimary, width: 2),
        ),
      ),
      validator: (value) => value == null || value.isEmpty ? 'This field is required' : null,
    );
  }
}
