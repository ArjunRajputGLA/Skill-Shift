import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_button.dart';
import '../theme/app_colors.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch auth service for current user state
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Premium Ambient Glow Background
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.secondary.withOpacity(0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header (GlassCard)
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              )
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 56,
                            backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                            child: Text(
                              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontSize: 44, 
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.fullName,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: 200,
                          child: CustomButton(
                            label: 'Edit Profile',
                            icon: Icons.edit_rounded,
                            isPrimary: false,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Education Section
                  _buildSectionTitle('Education', theme),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildInfoTile(Icons.school_rounded, '${user.collegeName}', theme, isDark),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Divider(height: 1, thickness: 0.5),
                        ),
                        _buildInfoTile(Icons.menu_book_rounded, '${user.branch} • ${user.year}', theme, isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Bio Section
                  if (user.bio.isNotEmpty) ...[
                    _buildSectionTitle('About Me', theme),
                    const SizedBox(height: 12),
                    GlassCard(
                      child: Text(
                        user.bio, 
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Skills & Interests
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user.skills.isNotEmpty)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Can Teach', theme),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: user.skills.map((skill) => _buildGlowingChip(skill, theme.colorScheme.primary, isDark)).toList(),
                              ),
                            ],
                          ),
                        ),
                      if (user.skills.isNotEmpty && user.interests.isNotEmpty)
                        const SizedBox(width: 20),
                      if (user.interests.isNotEmpty)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Wants to Learn', theme),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: user.interests.map((interest) => _buildGlowingChip(interest, theme.colorScheme.secondary, isDark)).toList(),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Contact
                  _buildSectionTitle('Contact', theme),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: _buildInfoTile(Icons.phone_rounded, user.whatsapp.isNotEmpty ? user.whatsapp : 'Not provided', theme, isDark),
                  ),
                  
                  const SizedBox(height: 120), // Padding for floating nav bar
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String text, ThemeData theme, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlowingChip(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? color.withOpacity(0.9) : color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
