import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
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
                          child: TextButton.icon(
                            onPressed: _isLoading ? null : _verifyPhoneNumber,
                            icon: const Icon(Icons.verified_user_outlined, size: 18),
                            label: const Text('Verify Number'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
                              const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                              const SizedBox(width: 4),
                              Text('Verified', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
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
                  child: Text('Education', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: AppSpacing.md),
                GlassCard(
                  child: Column(
                    children: [
                      CustomTextField(
                        label: 'College/University',
                        controller: _collegeNameController,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'Branch/Major',
                              controller: _branchController,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: CustomTextField(
                              label: 'Year',
                              controller: _yearController,
                            ),
                          ),
                        ],
                      ),
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