import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_chip.dart';
import '../widgets/avatar_widget.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'edit_profile_screen.dart';
import 'public_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = context.watch<AuthService>().currentUser;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            
            // Premium Segmented Control
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9), // Slate 800 / Slate 100
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _tabController.animateTo(0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          color: _tabController.index == 0 ? theme.colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: _tabController.index == 0 ? [
                            BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))
                          ] : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Personal Info',
                          style: TextStyle(
                            color: _tabController.index == 0 ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _tabController.animateTo(1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          color: _tabController.index == 1 ? theme.colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: _tabController.index == 1 ? [
                            BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))
                          ] : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Public Profile',
                          style: TextStyle(
                            color: _tabController.index == 1 ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  const _PersonalProfileTab(),
                  PublicProfileScreen(userId: user.id, showAppBar: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalProfileTab extends StatefulWidget {
  const _PersonalProfileTab();

  @override
  State<_PersonalProfileTab> createState() => _PersonalProfileTabState();
}

class _PersonalProfileTabState extends State<_PersonalProfileTab> {
  bool _isDeleting = false;

  void _confirmDeleteAccount(AuthService authService) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
          title: Text(
            'Delete Account',
            style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to permanently delete your account? This action cannot be undone and will delete all your posts and messages.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext); // Close dialog
                setState(() => _isDeleting = true);
                NotificationService.showLoading(context);

                final error = await authService.deleteAccount();

                if (mounted) {
                  NotificationService.hideLoading(context);
                  setState(() => _isDeleting = false);
                  
                  if (error != null) {
                    NotificationService.showError(context, error);
                  } else {
                    NotificationService.showSuccess(context, 'Account deleted successfully.');
                  }
                }
              },
              child: const Text('Delete Forever'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async => Future.delayed(const Duration(milliseconds: 500)),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: AppSpacing.xl, // Pushed content slightly down
          left: AppSpacing.screenHorizontal,
          right: AppSpacing.screenHorizontal,
          bottom: AppSpacing.navClearance,
        ),
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                trailing: user.whatsapp.isNotEmpty 
                    ? (user.whatsappVerified
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified, color: AppColors.success, size: 18),
                              const SizedBox(width: 4),
                              Text('Verified', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                              const SizedBox(width: 4),
                              Text('Not verified', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.warning, fontWeight: FontWeight.bold)),
                            ],
                          ))
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // Settings Section
            _buildSectionTitle('Settings', theme),
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              animate: true,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: SwitchListTile(
                title: Text(
                  'Push Notifications',
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  user.notificationsEnabled ? 'On' : 'Off',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                value: user.notificationsEnabled,
                activeTrackColor: theme.colorScheme.primary.withValues(alpha: 0.5),
                activeThumbColor: theme.colorScheme.primary,
                onChanged: (bool value) async {
                  await authService.updateProfile(user.copyWith(notificationsEnabled: value));
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // Danger Zone
            Text(
              'Danger Zone',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              animate: true,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delete your account permanently. This action cannot be undone.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete_forever),
                      label: Text(_isDeleting ? 'Deleting...' : 'Delete Account'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error.withValues(alpha: 0.1),
                        foregroundColor: AppColors.error,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                      onPressed: _isDeleting ? null : () => _confirmDeleteAccount(authService),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.navClearance),
          ],
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

  Widget _buildInfoTile(IconData icon, String text, ThemeData theme, bool isDark, {Widget? trailing}) {
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
        if (trailing != null) trailing,
      ],
    );
  }
}
