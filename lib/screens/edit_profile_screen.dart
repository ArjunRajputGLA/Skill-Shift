import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/glass_card.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/custom_chip.dart';
import '../widgets/duolingo_button.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../services/phone_auth_service.dart';
import 'otp_verification_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _collegeNameController;
  late TextEditingController _branchController;
  late TextEditingController _yearController;
  late TextEditingController _bioController;
  late TextEditingController _whatsappController;
  
  late List<String> _skills;
  late List<String> _interests;

  String _selectedRole = 'Bachelor\'s Student';
  final List<String> _roles = [
    'Bachelor\'s Student',
    'Master\'s Student',
    'PhD Student',
    'Professional',
    'Other'
  ];

  late TextEditingController _specializationController;
  late TextEditingController _researchAreaController;
  late TextEditingController _organizationController;
  late TextEditingController _designationController;
  late TextEditingController _experienceController;

  final TextEditingController _skillController = TextEditingController();
  final TextEditingController _interestController = TextEditingController();

  bool _isLoading = false;
  String? _profileImageBase64;
  
  bool _isWhatsAppVerified = false;
  String _originalWhatsApp = '';

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    _collegeNameController = TextEditingController(text: user?.collegeName ?? '');
    _branchController = TextEditingController(text: user?.branch ?? '');
    _yearController = TextEditingController(text: user?.year ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _whatsappController = TextEditingController(text: user?.whatsapp ?? '');
    
    _selectedRole = user?.userType ?? 'Bachelor\'s Student';
    if (!_roles.contains(_selectedRole)) _selectedRole = 'Bachelor\'s Student';
    
    _specializationController = TextEditingController(text: user?.specialization ?? '');
    _researchAreaController = TextEditingController(text: user?.researchArea ?? '');
    _organizationController = TextEditingController(text: user?.organization ?? '');
    _designationController = TextEditingController(text: user?.designation ?? '');
    _experienceController = TextEditingController(text: user?.experience ?? '');
    
    _skills = List<String>.from(user?.skills ?? []);
    _interests = List<String>.from(user?.interests ?? []);
    _profileImageBase64 = user?.profileImageBase64;
    _originalWhatsApp = user?.whatsapp ?? '';
    _isWhatsAppVerified = user?.whatsappVerified ?? false;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _collegeNameController.dispose();
    _branchController.dispose();
    _yearController.dispose();
    _bioController.dispose();
    _whatsappController.dispose();
    _specializationController.dispose();
    _researchAreaController.dispose();
    _organizationController.dispose();
    _designationController.dispose();
    _experienceController.dispose();
    _skillController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  // ALL backend logic preserved exactly
  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
    }
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

  void _addInterest() {
    final interest = _interestController.text.trim();
    if (interest.isNotEmpty && !_interests.contains(interest)) {
      setState(() {
        _interests.add(interest);
        _interestController.clear();
      });
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Profile Picture', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndCropImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndCropImage(ImageSource.gallery);
              },
            ),
            if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty)
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.error),
                title: Text('Remove photo', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _profileImageBase64 = null);
                },
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndCropImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      if (image == null) return;

      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 70,
        maxWidth: 400,
        maxHeight: 400,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Profile Picture',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        final bytes = await croppedFile.readAsBytes();
        setState(() {
          _profileImageBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Failed to pick/crop image: $e');
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    final currentWhatsapp = _whatsappController.text.replaceAll(' ', '');
    if (currentWhatsapp != _originalWhatsApp || !_isWhatsAppVerified) {
      if (currentWhatsapp.isNotEmpty) {
        NotificationService.showError(context, 'Please verify your WhatsApp number first.');
        return;
      }
    }

    setState(() => _isLoading = true);
    NotificationService.showLoading(context);

    final currentUser = context.read<AuthService>().currentUser;
    if (currentUser == null) {
      NotificationService.hideLoading(context);
      return;
    }

    final updatedUser = UserModel(
      id: currentUser.id,
      email: currentUser.email,
      fullName: _fullNameController.text.trim(),
      collegeName: _collegeNameController.text.trim(),
      branch: _branchController.text.trim(),
      year: _yearController.text.trim(),
      bio: _bioController.text.trim(),
      userType: _selectedRole,
      specialization: _specializationController.text.trim(),
      researchArea: _researchAreaController.text.trim(),
      organization: _organizationController.text.trim(),
      designation: _designationController.text.trim(),
      experience: _experienceController.text.trim(),
      whatsapp: _originalWhatsApp,
      whatsappVerified: _isWhatsAppVerified,
      verifiedAt: currentUser.verifiedAt, // Preserve verifiedAt if unchanged
      skills: _skills,
      interests: _interests,
      profileCompleted: true,
      profileImageBase64: _profileImageBase64,
      createdAt: currentUser.createdAt,
    );

    final error = await context.read<AuthService>().updateProfile(updatedUser);

    if (mounted) {
      NotificationService.hideLoading(context);
      setState(() => _isLoading = false);
      if (error != null) {
        NotificationService.showError(context, error);
      } else {
        NotificationService.showSuccess(context, 'Profile updated successfully!');
        Navigator.pop(context);
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
        title: const Text('Edit Profile'),
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _showImageOptions,
                  child: Stack(
                    children: [
                      AvatarWidget(
                        imageBase64: _profileImageBase64,
                        name: _fullNameController.text,
                        radius: 50,
                        showGlow: true,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppColors.darkSurface : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        label: 'Full Name',
                        controller: _fullNameController,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CustomTextField(
                        label: 'Bio',
                        controller: _bioController,
                        maxLines: 3,
                        hint: 'Tell us about yourself...',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CustomTextField(
                        label: 'WhatsApp Number',
                        controller: _whatsappController,
                        keyboardType: TextInputType.phone,
                        onChanged: (val) {
                          if (val.replaceAll(' ', '') != _originalWhatsApp) {
                            setState(() => _isWhatsAppVerified = false);
                          } else {
                            final user = context.read<AuthService>().currentUser;
                            setState(() => _isWhatsAppVerified = user?.whatsappVerified ?? false);
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
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Academic / Professional Background', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: AppSpacing.md),
                GlassCard(
                  child: Column(
                    children: [
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
                          controller: _collegeNameController,
                          label: 'College Name',
                          hint: 'e.g. GLA University',
                          prefixIcon: const Icon(Icons.school_outlined),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _branchController,
                                label: 'Branch',
                                hint: 'e.g. CSE',
                              ),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: CustomTextField(
                                controller: _yearController,
                                label: 'Year',
                                hint: 'e.g. 3rd Year',
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (_selectedRole == 'Master\'s Student') ...[
                        CustomTextField(
                          controller: _collegeNameController,
                          label: 'College/University Name',
                          hint: 'e.g. GLA University',
                          prefixIcon: const Icon(Icons.school_outlined),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _specializationController,
                                label: 'Specialization',
                                hint: 'e.g. AI & ML',
                              ),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: CustomTextField(
                                controller: _yearController,
                                label: 'Year',
                                hint: 'e.g. 1st Year',
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (_selectedRole == 'PhD Student') ...[
                        CustomTextField(
                          controller: _collegeNameController,
                          label: 'University Name',
                          hint: 'e.g. GLA University',
                          prefixIcon: const Icon(Icons.school_outlined),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _researchAreaController,
                                label: 'Research Area',
                                hint: 'e.g. Quantum Computing',
                              ),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: CustomTextField(
                                controller: _yearController,
                                label: 'Year of Study',
                                hint: 'e.g. 2nd Year',
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
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _designationController,
                                label: 'Role / Designation',
                                hint: 'e.g. Software Engineer',
                              ),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: CustomTextField(
                                controller: _experienceController,
                                label: 'Experience',
                                hint: 'e.g. 3 Years',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Skills (Can Teach)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: AppSpacing.md),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: '',
                              hint: 'Add a skill...',
                              controller: _skillController,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          IconButton(
                            icon: Icon(Icons.add_circle, color: theme.colorScheme.primary, size: 30),
                            onPressed: _addSkill,
                          )
                        ],
                      ),
                      if (_skills.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: _skills.map((s) => CustomChip(
                            label: s,
                            variant: ChipVariant.accent,
                            onDelete: () => setState(() => _skills.remove(s)),
                          )).toList(),
                        ),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Interests (Wants to Learn)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: AppSpacing.md),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: '',
                              hint: 'Add an interest...',
                              controller: _interestController,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          IconButton(
                            icon: Icon(Icons.add_circle, color: theme.colorScheme.secondary, size: 30),
                            onPressed: _addInterest,
                          )
                        ],
                      ),
                      if (_interests.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: _interests.map((i) => CustomChip(
                            label: i,
                            variant: ChipVariant.outlined,
                            onDelete: () => setState(() => _interests.remove(i)),
                          )).toList(),
                        ),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),

                CustomButton(
                  label: 'Save Profile',
                  isLoading: _isLoading,
                  onPressed: _saveProfile,
                  icon: Icons.check_circle_outline,
                ),
                const SizedBox(height: AppSpacing.huge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}