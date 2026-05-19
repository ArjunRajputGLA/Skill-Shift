import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

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

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser == null) return;

    // Convert comma-separated string inputs to Lists
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

    // Create a modified copy of the current user
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
      profileCompleted: true, // Marking true so they don't see this screen again
      createdAt: currentUser.createdAt ?? DateTime.now(),
    );

    final error = await authService.updateProfile(updatedUser);

    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $error')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile Setup Complete! Welcome!')),
        );
        // We don't need to Navigator.push here because AuthWrapper in main.dart
        // is listening to authService state changes and will automatically route 
        // to HomeScreen now that profileCompleted == true!
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Your Profile'),
        automaticallyImplyLeading: false, // Don't allow them to go back to blank screen
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Tell us about yourself so peers can find and connect with you.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                
                // College Information
                TextFormField(
                  controller: _collegeController,
                  decoration: const InputDecoration(
                    labelText: 'College Name', 
                    border: OutlineInputBorder(),
                    hintText: 'e.g. GLA University',
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _branchController,
                        decoration: const InputDecoration(
                          labelText: 'Branch',
                          border: OutlineInputBorder(),
                          hintText: 'e.g. CSE',
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _yearController,
                        decoration: const InputDecoration(
                          labelText: 'Year',
                          border: OutlineInputBorder(),
                          hintText: 'e.g. 3rd Year',
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Divider(),
                ),
                
                // Skills & Interests
                TextFormField(
                  controller: _skillsController,
                  decoration: const InputDecoration(
                    labelText: 'Your Skills (comma separated)',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. Flutter, DSA, Public Speaking',
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Please add at least one skill' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _interestsController,
                  decoration: const InputDecoration(
                    labelText: 'Things you want to learn/do',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. Backend Dev, Find Co-founder',
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                // Bio & Contact
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Short Bio',
                    border: OutlineInputBorder(),
                    hintText: 'I help with Flutter and DSA. Looking for hackathon teammates.',
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _whatsappController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp Number (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                
                const SizedBox(height: 32),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Complete Profile', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
