import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/gradient_background.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _collegeController = TextEditingController();
  final _branchController = TextEditingController();
  final _yearController = TextEditingController();
  final _skillsController = TextEditingController();
  final _interestsController = TextEditingController();
  final _bioController = TextEditingController();
  final _whatsappController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _collegeController.dispose();
    _branchController.dispose();
    _yearController.dispose();
    _skillsController.dispose();
    _interestsController.dispose();
    _bioController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  // ALL backend logic preserved exactly
  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    NotificationService.showLoading(context);

    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      NotificationService.hideLoading(context);
      return;
    }

    final skillsList = _skillsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
        
    final interestsList = _interestsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final whatsapp = _whatsappController.text.trim();
    if (whatsapp.isNotEmpty) {
      try {
        final existingUsers = await FirebaseFirestore.instance
            .collection('users')
            .where('whatsapp', isEqualTo: whatsapp)
            .get();

        for (var doc in existingUsers.docs) {
          if (doc.id != currentUser.id) {
            NotificationService.hideLoading(context);
            setState(() => _isLoading = false);
            NotificationService.showError(context, 'This phone number is already registered to another account.');
            return;
          }
        }
      } catch (e) {
        debugPrint("Error checking phone uniqueness: $e");
      }
    }

    UserModel updatedUser = UserModel(
      id: currentUser.id,
      fullName: currentUser.fullName,
      email: currentUser.email,
      collegeName: _collegeController.text.trim(),
      branch: _branchController.text.trim(),
      year: _yearController.text.trim(),
      skills: skillsList,
      interests: interestsList,
      bio: _bioController.text.trim(),
      whatsapp: _whatsappController.text.trim(),
      profileCompleted: true,
      createdAt: currentUser.createdAt ?? DateTime.now(),
    );

    final error = await authService.updateProfile(updatedUser);

    if (mounted) {
      NotificationService.hideLoading(context);
      setState(() => _isLoading = false);
      if (error != null) {
        NotificationService.showError(context, 'Error saving profile: $error');
      } else {
        NotificationService.showSuccess(context, 'Profile Setup Complete! Welcome!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Your Profile'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Provider.of<AuthService>(context, listen: false).signOut();
          },
        ),
      ),
      body: GradientBackground(
        accentColor1: AppColors.primary,
        accentColor2: AppColors.accent,
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tell us about yourself so peers can find and connect with you.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  
                  // College Information
                  CustomTextField(
                    controller: _collegeController,
                    label: 'College Name',
                    hint: 'e.g. GLA University',
                    prefixIcon: const Icon(Icons.school_outlined),
                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _branchController,
                          label: 'Branch',
                          hint: 'e.g. CSE',
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: CustomTextField(
                          controller: _yearController,
                          label: 'Year',
                          hint: 'e.g. 3rd Year',
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: Divider(),
                  ),
                  
                  // Skills & Interests
                  CustomTextField(
                    controller: _skillsController,
                    label: 'Your Skills (comma separated)',
                    hint: 'e.g. Flutter, DSA, Public Speaking',
                    prefixIcon: const Icon(Icons.star_outline),
                    validator: (value) => value == null || value.isEmpty ? 'Please add at least one skill' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  CustomTextField(
                    controller: _interestsController,
                    label: 'Things you want to learn/do',
                    hint: 'e.g. Backend Dev, Find Co-founder',
                    prefixIcon: const Icon(Icons.lightbulb_outline),
                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Bio & Contact
                  CustomTextField(
                    controller: _bioController,
                    maxLines: 3,
                    label: 'Short Bio',
                    hint: 'I help with Flutter and DSA. Looking for hackathon teammates.',
                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  CustomTextField(
                    controller: _whatsappController,
                    label: 'WhatsApp Number (Optional)',
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                  
                  const SizedBox(height: AppSpacing.xxxl),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Complete Profile', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
