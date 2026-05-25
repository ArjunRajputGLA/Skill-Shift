import 'dart:io';
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

class _FarreyUploadScreenState extends State<FarreyUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _subjectController = TextEditingController();
  final _semesterController = TextEditingController();
  final _tagsController = TextEditingController();
  final _branchController = TextEditingController();

  File? _selectedFile;
  String? _fileExtension;
  bool _isUploading = false;

  final FarreyDatabaseService _dbService = FarreyDatabaseService();
  final FarreyStorageService _storageService = FarreyStorageService();

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileExtension = result.files.single.extension;
      });
    }
  }

  Future<void> _uploadNote() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please select a file to upload.', style: TextStyle(color: Colors.white)), backgroundColor: context.farreyError),
      );
      return;
    }

    setState(() => _isUploading = true);

    final currentUser = context.read<AuthService>().currentUser;
    if (currentUser == null) {
      setState(() => _isUploading = false);
      return;
    }

    try {
      final fileUrl = await _storageService.uploadNoteFile(_selectedFile!, _fileExtension ?? 'pdf');

      final noteId = DateTime.now().millisecondsSinceEpoch.toString();
      final tagsList = _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      final newNote = FarreyNoteModel(
        noteId: noteId,
        uploaderUid: currentUser.id,
        uploaderName: currentUser.fullName,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        subject: _subjectController.text.trim(),
        semester: _semesterController.text.trim(),
        tags: tagsList,
        branch: _branchController.text.trim(),
        fileUrl: fileUrl,
        fileType: _fileExtension ?? 'pdf',
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
      _selectedFile = null;
      _fileExtension = null;
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
                    CircularProgressIndicator(color: context.farreyPrimary),
                    const SizedBox(height: 16),
                    Text('Uploading your note to Notes Ecosystem...', style: TextStyle(color: context.farreyTextSecondary)),
                  ],
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.only(top: 110, left: 24, right: 24, bottom: 120),
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
                              color: _selectedFile == null ? context.farreyPrimary.withValues(alpha: 0.3) : context.farreySuccess,
                              style: BorderStyle.solid,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _selectedFile == null ? Icons.cloud_upload_outlined : Icons.check_circle_outline,
                                  size: 40,
                                  color: _selectedFile == null ? context.farreyPrimary : context.farreySuccess,
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text(
                                    _selectedFile == null ? 'Tap to browse files' : 'File selected: ${_selectedFile!.path.split(RegExp(r'[/\\]')).last}',
                                    style: TextStyle(
                                      color: _selectedFile == null ? context.farreyPrimary : context.farreySuccess,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
