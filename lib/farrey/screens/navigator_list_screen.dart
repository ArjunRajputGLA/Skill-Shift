import 'package:flutter/material.dart';
import '../models/farrey_navigator_models.dart';
import '../services/navigator_service.dart';
import '../theme/farrey_colors.dart';
import 'navigator_dashboard_screen.dart';
import 'navigator_goal_creation_screen.dart';

class NavigatorListScreen extends StatefulWidget {
  final String uid;

  const NavigatorListScreen({super.key, required this.uid});

  @override
  State<NavigatorListScreen> createState() => _NavigatorListScreenState();
}

class _NavigatorListScreenState extends State<NavigatorListScreen> {
  final NavigatorService _navigatorService = NavigatorService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.farreyBackground,
      appBar: AppBar(
        backgroundColor: context.farreyBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: context.farreyTextPrimary),
        title: Row(
          children: [
            Icon(Icons.explore_rounded, color: context.farreyPrimary),
            const SizedBox(width: 8),
            Text('AI Journeys', style: TextStyle(color: context.farreyTextPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: StreamBuilder<List<FarreyNavigatorModel>>(
        stream: _navigatorService.getAllNavigators(widget.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final navigators = snapshot.data ?? [];
          
          if (navigators.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: navigators.length,
            itemBuilder: (context, index) {
              return _buildNavigatorCard(navigators[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NavigatorGoalCreationScreen()));
        },
        backgroundColor: context.farreyPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 80, color: context.farreyTextSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 24),
            Text(
              'No Active Journey',
              style: TextStyle(color: context.farreyTextPrimary, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Let Gemini AI generate a personalized learning roadmap and daily schedule to help you reach your goals.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.farreyTextSecondary, fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NavigatorGoalCreationScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.farreyPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Create New Goal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigatorCard(FarreyNavigatorModel navigator) {
    int daysRemaining = 0;
    if (navigator.targetDate != null) {
      daysRemaining = navigator.targetDate!.difference(DateTime.now()).inDays;
      if (daysRemaining < 0) daysRemaining = 0;
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => NavigatorDashboardScreen(navigatorId: navigator.navigatorId),
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.farreySurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.farreyBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        navigator.goalTitle,
                        style: TextStyle(color: context.farreyTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Level: ${navigator.currentLevel} • ${navigator.availableHours}',
                        style: TextStyle(color: context.farreyTextSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: context.farreyError),
                  onPressed: () => _confirmDelete(navigator.navigatorId, navigator.goalTitle),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                  splashRadius: 24,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Progress', style: TextStyle(color: context.farreyTextSecondary, fontSize: 12)),
                          Text('${(navigator.progress * 100).toInt()}%', style: TextStyle(color: context.farreyTextPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: navigator.progress,
                        backgroundColor: context.farreyPrimary.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(context.farreyPrimary),
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 6,
                      ),
                    ],
                  ),
                ),
                if (navigator.targetDate != null) ...[
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.farreyPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.hourglass_empty_rounded, size: 14, color: context.farreyPrimary),
                        const SizedBox(width: 4),
                        Text(
                          '$daysRemaining days',
                          style: TextStyle(color: context.farreyPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String navigatorId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.farreySurface,
        title: Text('Delete Journey?', style: TextStyle(color: context.farreyTextPrimary)),
        content: Text('Are you sure you want to delete "$title"? This will also delete all associated phases and tasks.', style: TextStyle(color: context.farreyTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: context.farreyTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _navigatorService.deleteNavigator(navigatorId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Journey deleted')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: context.farreyError),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
