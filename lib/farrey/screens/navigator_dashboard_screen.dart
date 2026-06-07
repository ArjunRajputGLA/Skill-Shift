import 'package:flutter/material.dart';
import '../models/farrey_navigator_models.dart';
import '../models/farrey_models.dart';
import '../services/navigator_service.dart';
import '../theme/farrey_colors.dart';
import 'navigator_roadmap_screen.dart';
import 'navigator_goal_creation_screen.dart';
import '../widgets/note_card.dart';

class NavigatorDashboardScreen extends StatefulWidget {
  final String navigatorId;

  const NavigatorDashboardScreen({super.key, required this.navigatorId});

  @override
  State<NavigatorDashboardScreen> createState() => _NavigatorDashboardScreenState();
}

class _NavigatorDashboardScreenState extends State<NavigatorDashboardScreen> {
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
            Text('Navigator', style: TextStyle(color: context.farreyTextPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: StreamBuilder<FarreyNavigatorModel?>(
        stream: _navigatorService.getNavigatorById(widget.navigatorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final navigator = snapshot.data;
          
          if (navigator == null) {
            return _buildEmptyState();
          }

          return _buildDashboard(navigator);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('Journey not found or was deleted.'));
  }

  Widget _buildDashboard(FarreyNavigatorModel navigator) {
    int daysRemaining = 0;
    if (navigator.targetDate != null) {
      daysRemaining = navigator.targetDate!.difference(DateTime.now()).inDays;
      if (daysRemaining < 0) daysRemaining = 0;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Goal Card
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.farreyPrimary,
                  context.farreyPrimary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: context.farreyPrimary.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  // Decorative background icon
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 140,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  Positioned(
                    left: -30,
                    bottom: -30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text('🎯', style: TextStyle(fontSize: 14)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      navigator.goalTitle,
                                      style: const TextStyle(
                                        color: Colors.white, 
                                        fontSize: 22, 
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Level: ${navigator.currentLevel}',
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (navigator.targetDate != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '⏳ $daysRemaining days remaining',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ],
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => NavigatorRoadmapScreen(navigatorId: navigator.navigatorId)));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: context.farreyPrimary,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text('View Full Roadmap', style: TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_forward_rounded, size: 16),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              height: 90,
                              width: 90,
                              child: CircularProgressIndicator(
                                value: navigator.progress,
                                strokeWidth: 10,
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${(navigator.progress * 100).toInt()}%',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
                                ),
                                Text(
                                  'Done',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Stats row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.farreySurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.farreyBorder),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 32),
                      const SizedBox(height: 8),
                      Text('${navigator.streakDays}', style: TextStyle(color: context.farreyTextPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                      Text('Day Streak', style: TextStyle(color: context.farreyTextSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.farreySurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.farreyBorder),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.schedule_rounded, color: context.farreySecondary, size: 32),
                      const SizedBox(height: 8),
                      Text(navigator.availableHours, style: TextStyle(color: context.farreyTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('Daily Target', style: TextStyle(color: context.farreyTextSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Today's Tasks
          Text('✅ Today\'s Schedule', style: TextStyle(color: context.farreyTextPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          StreamBuilder<List<FarreyTaskModel>>(
            stream: _navigatorService.getTodayTasks(navigator.navigatorId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final tasks = snapshot.data ?? [];
              if (tasks.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.farreySurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.farreyBorder),
                  ),
                  child: Center(
                    child: Text('All tasks completed for today!', style: TextStyle(color: context.farreyTextSecondary)),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: context.farreySurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.farreyBorder),
                    ),
                    child: CheckboxListTile(
                      value: task.completed,
                      onChanged: (val) {
                        if (val != null) {
                          _navigatorService.toggleTaskCompletion(task.taskId, val, navigator.navigatorId);
                        }
                      },
                      title: Text(
                        task.title,
                        style: TextStyle(
                          color: task.completed ? context.farreyTextSecondary : context.farreyTextPrimary,
                          decoration: task.completed ? TextDecoration.lineThrough : null,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text('${task.type.toUpperCase()} • ${task.estimatedTime}', style: TextStyle(color: context.farreyTextSecondary, fontSize: 12)),
                      activeColor: context.farreyPrimary,
                      checkColor: Colors.white,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 32),

          // Recommended Notes
          Text('📚 Recommended Notes', style: TextStyle(color: context.farreyTextPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          StreamBuilder<List<FarreyNoteModel>>(
            stream: _navigatorService.getRecommendedNotes(navigator.goalTitle),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No recommendations yet'));
              }
              return SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    return NoteCard(note: snapshot.data![index]);
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
