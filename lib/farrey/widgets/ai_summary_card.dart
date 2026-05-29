import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/farrey_ai_analysis.dart';
import '../theme/farrey_colors.dart';
import '../../theme/app_spacing.dart';

class AiSummaryCard extends StatelessWidget {
  final FarreyAiAnalysis analysis;

  const AiSummaryCard({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final theme = context;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.farreySurfaceElevated.withOpacity(theme.isDark ? 0.5 : 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.farreyPrimary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: theme.farreyPrimary.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: true,
              iconColor: theme.farreyPrimary,
              collapsedIconColor: theme.farreyTextSecondary,
              title: Row(
                children: [
                  Icon(Icons.auto_awesome, color: theme.farreyPrimary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'AI Notes Analysis',
                    style: TextStyle(
                      color: theme.farreyTextPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overview Metrics
                      Row(
                        children: [
                          _buildMetricChip(context, Icons.speed, 'Difficulty: ${analysis.difficulty}', _getDifficultyColor(analysis.difficulty)),
                          const SizedBox(width: AppSpacing.sm),
                          _buildMetricChip(context, Icons.timer_outlined, analysis.estimatedStudyTime, theme.farreySecondary),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      
                      // AI Summary
                      _buildSectionTitle(context, '📖 Summary'),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        analysis.summary,
                        style: TextStyle(color: theme.farreyTextSecondary, fontSize: 15, height: 1.5),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Important Topics
                      if (analysis.importantTopics.isNotEmpty) ...[
                        _buildSectionTitle(context, '🔥 Important Topics'),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: analysis.importantTopics.map((topic) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.farreyPrimary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: theme.farreyPrimary.withOpacity(0.2)),
                              ),
                              child: Text(
                                topic,
                                style: TextStyle(color: theme.farreyPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Quick Revision Notes
                      if (analysis.quickRevision.isNotEmpty) ...[
                        _buildSectionTitle(context, '⚡ Quick Revision'),
                        const SizedBox(height: AppSpacing.xs),
                        ...analysis.quickRevision.map((point) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.bolt, color: theme.farreySecondary, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    point,
                                    style: TextStyle(color: theme.farreyTextSecondary, fontSize: 14, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        color: context.farreyTextPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }

  Widget _buildMetricChip(BuildContext context, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    if (difficulty.toLowerCase().contains('beginner')) return Colors.green;
    if (difficulty.toLowerCase().contains('advanced')) return Colors.redAccent;
    return Colors.orange;
  }
}
