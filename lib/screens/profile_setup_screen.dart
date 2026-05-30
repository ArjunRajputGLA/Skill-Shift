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
import '../services/phone_auth_service.dart';
import 'otp_verification_screen.dart';
import '../widgets/duolingo_button.dart';

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

  String _selectedRole = 'Bachelor\'s Student';
  final List<String> _roles = [
    'Bachelor\'s Student',
    'Master\'s Student',
    'PhD Student',
    'Professional',
    'Other'
  ];

  final _specializationController = TextEditingController();
  final _researchAreaController = TextEditingController();
  final _organizationController = TextEditingController();
  final _designationController = TextEditingController();
  final _experienceController = TextEditingController();

  bool _isLoading = false;
  bool _isWhatsAppVerified = false;
  String _originalWhatsApp = '';

  @override
  void dispose() {
    _collegeController.dispose();
    _branchController.dispose();
    _yearController.dispose();
    _skillsController.dispose();
    _interestsController.dispose();
    _bioController.dispose();
    _whatsappController.dispose();
    _specializationController.dispose();
    _researchAreaController.dispose();
    _organizationController.dispose();
    _designationController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  void _verifyPhoneNumber() async {
    String phone = _whatsappController.text.replaceAll(' ', '');
    if (!phone.startsWith('+')) {
      NotificationService.showError(context, 'Please include country code (e.g. +91)');
      return;
    }

    setState(() => _isLoading = true);
    NotificationService.showLoading(context);

    try {
      final currentUser = context.read<AuthService>().currentUser;
      final existingUsers = await FirebaseFirestore.instance
          .collection('users')
          .where('whatsapp', isEqualTo: phone)
          .get();

      for (var doc in existingUsers.docs) {
        if (doc.id != currentUser?.id) {
          NotificationService.hideLoading(context);
          setState(() => _isLoading = false);
          NotificationService.showError(context, 'This phone number is already registered to another account.');
          return;
        }
      }
    } catch (e) {
      debugPrint("Error checking phone uniqueness: $e");
    }

    final phoneAuth = PhoneAuthService();

    await phoneAuth.sendOtp(
      phoneNumber: phone,
      codeSent: (verificationId, resendToken) async {
        NotificationService.hideLoading(context);
        setState(() => _isLoading = false);
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              phoneNumber: phone,
              verificationId: verificationId,
              resendToken: resendToken,
            ),
          ),
        );
        if (result == true) {
          setState(() {
            _originalWhatsApp = phone;
            _isWhatsAppVerified = true;
          });
        }
      },
      verificationFailed: (error) {
        NotificationService.hideLoading(context);
        setState(() => _isLoading = false);
        NotificationService.showError(context, error.message ?? 'Verification failed');
      },
      verificationCompleted: (cred) {},
      codeAutoRetrievalTimeout: (id) {},
    );
  }

  // ALL backend logic preserved exactly
  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    final currentWhatsapp = _whatsappController.text.replaceAll(' ', '');
    if (currentWhatsapp != _originalWhatsApp || !_isWhatsAppVerified) {
      NotificationService.showError(context, 'Please verify your WhatsApp number first.');
      return;
    }

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

    UserModel updatedUser = UserModel(
      id: currentUser.id,
      fullName: currentUser.fullName,
      email: currentUser.email,
      userType: _selectedRole,
      collegeName: _collegeController.text.trim(),
      branch: _branchController.text.trim(),
      year: _yearController.text.trim(),
      specialization: _specializationController.text.trim(),
      researchArea: _researchAreaController.text.trim(),
      organization: _organizationController.text.trim(),
      designation: _designationController.text.trim(),
      experience: _experienceController.text.trim(),
      skills: skillsList,
      interests: interestsList,
      bio: _bioController.text.trim(),
      whatsapp: _originalWhatsApp,
      whatsappVerified: _isWhatsAppVerified,
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Setup Your Profile'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                  
                  // Role Selection
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      labelText: 'I am a...',
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: _roles.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedRole = value);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Dynamic Fields
                  if (_selectedRole == 'Bachelor\'s Student') ...[
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
                  ],

                  if (_selectedRole == 'Master\'s Student') ...[
                    CustomTextField(
                      controller: _collegeController,
                      label: 'College/University Name',
                      hint: 'e.g. GLA University',
                      prefixIcon: const Icon(Icons.school_outlined),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _specializationController,
                            label: 'Specialization',
                            hint: 'e.g. AI & ML',
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: CustomTextField(
                            controller: _yearController,
                            label: 'Year',
                            hint: 'e.g. 1st Year',
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (_selectedRole == 'PhD Student') ...[
                    CustomTextField(
                      controller: _collegeController,
                      label: 'University Name',
                      hint: 'e.g. GLA University',
                      prefixIcon: const Icon(Icons.school_outlined),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _researchAreaController,
                            label: 'Research Area',
                            hint: 'e.g. Quantum Computing',
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: CustomTextField(
                            controller: _yearController,
                            label: 'Year of Study',
                            hint: 'e.g. 2nd Year',
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (_selectedRole == 'Professional' || _selectedRole == 'Other') ...[
                    CustomTextField(
                      controller: _organizationController,
                      label: 'Organization / Company',
                      hint: 'e.g. Google',
                      prefixIcon: const Icon(Icons.business_outlined),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _designationController,
                            label: 'Role / Designation',
                            hint: 'e.g. Software Engineer',
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: CustomTextField(
                            controller: _experienceController,
                            label: 'Experience',
                            hint: 'e.g. 3 Years',
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
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
                    label: 'WhatsApp Number',
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone_outlined),
                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    onChanged: (val) {
                      if (val.replaceAll(' ', '') != _originalWhatsApp) {
                        setState(() => _isWhatsAppVerified = false);
                      }
                    },
                  ),
                  if (!_isWhatsAppVerified && _whatsappController.text.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 180,
                        child: DuolingoButton(
                          title: 'Verify Number',
                          icon: Icons.verified_user_outlined,
                          color: AppColors.primary,
                          loading: _isLoading,
                          onPressed: _verifyPhoneNumber,
                        ),
                      ),
                    ),
                  ],
                  if (_isWhatsAppVerified && _whatsappController.text.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.verifiedGreen, size: 16),
                          const SizedBox(width: 4),
                          Text('Verified', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.verifiedGreen, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                  
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
