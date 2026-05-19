import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/glass_card.dart';

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

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
    }
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final currentUser = context.read<AuthService>().currentUser;
    if (currentUser == null) return;

    final updatedUser = UserModel(
      id: currentUser.id,
      email: currentUser.email, // Email usually read-only
      fullName: _fullNameController.text.trim(),
      collegeName: _collegeNameController.text.trim(),
      branch: _branchController.text.trim(),
      year: _yearController.text.trim(),
      bio: _bioController.text.trim(),
      whatsapp: _whatsappController.text.trim(),
      skills: _skills,
      interests: _interests,
      profileCompleted: true, // Marking as complete if not already
      createdAt: currentUser.createdAt,
    );

    final error = await context.read<AuthService>().updateProfile(updatedUser);

    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
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
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        label: 'Full Name',
                        controller: _fullNameController,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Bio',
                        controller: _bioController,
                        maxLines: 3,
                        hint: 'Tell us about yourself...',
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'WhatsApp Number',
                        controller: _whatsappController,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                Text('Education', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    children: [
                      CustomTextField(
                        label: 'College/University',
                        controller: _collegeNameController,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'Branch/Major',
                              controller: _branchController,
                            ),
                          ),
                          const SizedBox(width: 16),
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
                const SizedBox(height: 24),

                Text('Skills (Can Teach)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
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
                          const SizedBox(width: 12),
                          IconButton(
                            icon: Icon(Icons.add_circle, color: theme.colorScheme.primary, size: 30),
                            onPressed: _addSkill,
                          )
                        ],
                      ),
                      if (_skills.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _skills.map((s) => Chip(
                            label: Text(s),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () => setState(() => _skills.remove(s)),
                          )).toList(),
                        ),
                      ]
                    ], // Children
                  ),
                ),
                const SizedBox(height: 24),

                Text('Interests (Wants to Learn)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
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
                          const SizedBox(width: 12),
                          IconButton(
                            icon: Icon(Icons.add_circle, color: theme.colorScheme.secondary, size: 30),
                            onPressed: _addInterest,
                          )
                        ],
                      ),
                      if (_interests.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _interests.map((i) => Chip(
                            label: Text(i),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () => setState(() => _interests.remove(i)),
                          )).toList(),
                        ),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                CustomButton(
                  label: 'Save Profile',
                  isLoading: _isLoading,
                  onPressed: _saveProfile,
                  icon: Icons.check_circle_outline,
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}