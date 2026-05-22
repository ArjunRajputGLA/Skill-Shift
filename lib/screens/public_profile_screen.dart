import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/booking_service.dart';
import '../models/session_slot_model.dart';
import '../models/user_model.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_chip.dart';
import '../widgets/avatar_widget.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/booking_form_sheet.dart';

class PublicProfileScreen extends StatelessWidget {
  final String userId;
  final bool showAppBar;

  const PublicProfileScreen({
    super.key,
    required this.userId,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUser = context.read<AuthService>().currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: showAppBar ? AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ) : null,
      extendBodyBehindAppBar: true,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User not found.'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final user = UserModel.fromMap(userData, snapshot.data!.id);

          return RefreshIndicator(
            onRefresh: () async {
              // Refresh is handled by stream/future automatically, this is just for UX
              await Future.delayed(const Duration(seconds: 1));
            },
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
              top: showAppBar ? MediaQuery.of(context).padding.top + 60 : AppSpacing.md,
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
                        '${user.branch} • ${user.year}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      if (user.reviewCount > 0) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              '${user.averageRating.toStringAsFixed(1)} (${user.reviewCount} reviews)',
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
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

                // Session Booking
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: const Text('Request Session', style: TextStyle(fontSize: 16)),
                    onPressed: () {
                      if (currentUser == null) {
                        NotificationService.showError(context, 'Please login first');
                        return;
                      }
                      if (currentUser.id == userId) {
                        NotificationService.showError(context, 'You cannot book a session with yourself');
                        return;
                      }
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => BookingFormSheet(
                          mentorUid: userId,
                          mentorName: user.fullName,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Skills
                if (user.skills.isNotEmpty) ...[
                  _buildSectionTitle('💡 Skill Reputation', theme),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: user.skills.map((skill) {
                      final isVerified = user.verifiedSkills[skill] == true;
                      final count = user.skillEndorsements[skill] ?? 0;
                      return CustomChip(
                        label: '$skill ×$count',
                        variant: ChipVariant.accent,
                        isVerified: isVerified,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],

                // Endorsements (Tags)
                if (user.tagEndorsements.isNotEmpty) ...[
                  _buildSectionTitle('🏆 Endorsements', theme),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: user.tagEndorsements.entries.map((entry) {
                      return CustomChip(
                        label: '${entry.key} ×${entry.value}',
                        variant: ChipVariant.filled,
                        isVerified: true, // Always show star for tag endorsements
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],

                // Interests
                if (user.interests.isNotEmpty) ...[
                  _buildSectionTitle('Interests', theme),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: user.interests.map((interest) => CustomChip(
                      label: interest,
                      variant: ChipVariant.outlined,
                    )).toList(),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],

                // Reviews List
                if (user.reviewCount > 0) ...[
                  _buildSectionTitle('📝 Reviews', theme),
                  const SizedBox(height: AppSpacing.md),
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('endorsements')
                        .where('receiverUid', isEqualTo: userId)
                        .where('reviewText', isNotEqualTo: '')
                        .limit(10)
                        .get(),
                    builder: (context, reviewSnap) {
                      if (!reviewSnap.hasData) return const Center(child: CircularProgressIndicator());
                      if (reviewSnap.data!.docs.isEmpty) return const Text('No written reviews yet.');

                      return Column(
                        children: reviewSnap.data!.docs.map((doc) {
                          final r = doc.data() as Map<String, dynamic>;
                          return GlassCard(
                            margin: const EdgeInsets.only(bottom: AppSpacing.md),
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      r['senderName'] ?? 'Anonymous',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: List.generate(5, (i) => Icon(
                                        i < (r['rating'] ?? 5) ? Icons.star_rounded : Icons.star_outline_rounded,
                                        size: 14,
                                        color: Colors.amber,
                                      )),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  r['reviewText'] ?? '',
                                  style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ],
            ),
          ),
        );
      },
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
