import 'package:flutter/material.dart';
import '../models/recommendations/recommended_item.dart';
import '../models/recommendations/recommended_post.dart';
import '../models/recommendations/recommended_user.dart';
import '../models/recommendations/recommended_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class RecommendedItemCard extends StatelessWidget {
  final RecommendedItem item;
  final VoidCallback onTap;

  const RecommendedItemCard({
    Key? key,
    required this.item,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    IconData iconData = Icons.star;
    Color iconColor = AppColors.primary;
    String title = '';
    String subtitle = '';
    
    if (item is RecommendedPost) {
      final p = (item as RecommendedPost).post;
      iconData = Icons.article_outlined;
      iconColor = AppColors.exploreAccent1;
      title = p.title;
      subtitle = 'Post by ${p.userName}';
    } else if (item is RecommendedUser) {
      final u = (item as RecommendedUser).user;
      iconData = Icons.person_outline;
      iconColor = AppColors.profileAccent1;
      title = u.fullName;
      subtitle = u.branch.isNotEmpty ? '${u.branch} • ${u.year}' : 'Skill Shift User';
    } else if (item is RecommendedSession) {
      final s = (item as RecommendedSession).session;
      iconData = Icons.videocam_outlined;
      iconColor = AppColors.accent;
      title = s.title;
      subtitle = 'Session with ${s.ownerName}';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Match Percentage & Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.successGreen.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.successGreen, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${item.matchPercentage.toInt()}% Match',
                        style: const TextStyle(
                          color: AppColors.successGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: iconColor, size: 20),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Title & Subtitle
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            // Match Reasons Chips
            if (item.matchReasons.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: item.matchReasons.map((reason) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Text(
                      reason,
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        fontSize: 11,
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
