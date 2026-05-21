import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_chip.dart';
import '../widgets/avatar_widget.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: AppSpacing.screenHorizontal,
            right: AppSpacing.screenHorizontal,
            bottom: AppSpacing.navClearance,
          ),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Center(
                child: Column(
                  children: [
                    AvatarWidget(
                      imageBase64: user.profileImageBase64,
                      name: user.fullName,
                      radius: 56,
                      showGlow: true,
                    ),
                    const SizedBox(height: AppSpacing.lg),
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
                    const SizedBox(height: AppSpacing.xxl),
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
              const SizedBox(height: AppSpacing.xxxl),

              // Education Section
              _buildSectionTitle('Education', theme),
              const SizedBox(height: AppSpacing.md),
              GlassCard(
                animate: true,
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    _buildInfoTile(Icons.school_rounded, user.collegeName, theme, isDark),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Divider(height: 1, thickness: 0.5),
                    ),
                    _buildInfoTile(Icons.menu_book_rounded, '${user.branch} • ${user.year}', theme, isDark),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Bio Section
              if (user.bio.isNotEmpty) ...[
                _buildSectionTitle('About Me', theme),
                const SizedBox(height: AppSpacing.md),
                GlassCard(
                  animate: true,
                  child: Text(
                    user.bio, 
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
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
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: user.skills.map((skill) => CustomChip(
                              label: skill,
                              variant: ChipVariant.accent,
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                  if (user.skills.isNotEmpty && user.interests.isNotEmpty)
                    const SizedBox(width: AppSpacing.xl),
                  if (user.interests.isNotEmpty)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Wants to Learn', theme),
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: user.interests.map((interest) => CustomChip(
                              label: interest,
                              variant: ChipVariant.outlined,
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Contact
              _buildSectionTitle('Contact', theme),
              const SizedBox(height: AppSpacing.md),
              GlassCard(
                animate: true,
                child: _buildInfoTile(
                  Icons.phone_rounded,
                  user.whatsapp.isNotEmpty ? user.whatsapp : 'Not provided',
                  theme,
                  isDark,
                ),
              ),
              
              const SizedBox(height: AppSpacing.navClearance),
            ],
          ),
        ),
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
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 22),
        ),
        const SizedBox(width: AppSpacing.lg),
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
}
