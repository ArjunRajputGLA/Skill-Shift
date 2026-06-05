import 'package:flutter/material.dart';
import '../models/farrey_navigator_models.dart';
import '../services/navigator_service.dart';
import '../theme/farrey_colors.dart';

class NavigatorRoadmapScreen extends StatefulWidget {
  final String navigatorId;

  const NavigatorRoadmapScreen({super.key, required this.navigatorId});

  @override
  State<NavigatorRoadmapScreen> createState() => _NavigatorRoadmapScreenState();
}

class _NavigatorRoadmapScreenState extends State<NavigatorRoadmapScreen> {
  final NavigatorService _navigatorService = NavigatorService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.farreyBackground,
      appBar: AppBar(
        backgroundColor: context.farreyBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: context.farreyTextPrimary),
        title: Text('Your Journey', style: TextStyle(color: context.farreyTextPrimary)),
      ),
      body: StreamBuilder<List<FarreyRoadmapModel>>(
        stream: _navigatorService.getRoadmap(widget.navigatorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final phases = snapshot.data ?? [];
          if (phases.isEmpty) {
            return Center(child: Text('No roadmap phases found.', style: TextStyle(color: context.farreyTextSecondary)));
          }

          final firstUncompletedIndex = phases.indexWhere((p) => !p.completed);

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
            itemCount: phases.length,
            itemBuilder: (context, index) {
              final phase = phases[index];
              final isLast = index == phases.length - 1;
              final isNextActive = index == firstUncompletedIndex;
              final isFuture = !phase.completed && !isNextActive;

              Color nodeColor = phase.completed ? context.farreyPrimary : (isNextActive ? context.farreySecondary : context.farreySurfaceElevated);
              Color iconColor = (phase.completed || isNextActive) ? Colors.white : context.farreyTextSecondary;
              IconData nodeIcon = phase.completed ? Icons.check_rounded : (isNextActive ? Icons.play_arrow_rounded : Icons.lock_rounded);

              return SizedBox(
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Vertical connecting line
                    if (!isLast)
                      Positioned(
                        top: 90,
                        bottom: -90,
                        child: Container(
                          width: 6,
                          decoration: BoxDecoration(
                            color: phase.completed ? context.farreyPrimary : context.farreySurfaceElevated,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    
                    // Animated Milestone Node
                    GestureDetector(
                      onTap: () {
                        // Show phase details in bottom sheet
                        if (!isFuture) _showPhaseDetails(context, phase);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: nodeColor,
                              border: Border.all(
                                color: isNextActive ? context.farreySecondary : (phase.completed ? context.farreyPrimary : context.farreyBorder),
                                width: isNextActive ? 6 : 4,
                              ),
                              boxShadow: [
                                if (phase.completed || isNextActive)
                                  BoxShadow(
                                    color: nodeColor.withValues(alpha: 0.5),
                                    blurRadius: isNextActive ? 30 : 20,
                                    spreadRadius: isNextActive ? 8 : 2,
                                  )
                              ],
                            ),
                            child: Icon(
                              nodeIcon,
                              color: iconColor,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Text(
                              phase.title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isFuture ? context.farreyTextSecondary : context.farreyTextPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showPhaseDetails(BuildContext context, FarreyRoadmapModel phase) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.farreySurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (c) => SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(phase.title, style: TextStyle(color: context.farreyTextPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(phase.description, style: TextStyle(color: context.farreyTextSecondary, fontSize: 16)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(Icons.timer_outlined, color: context.farreyPrimary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Estimated Time: ${phase.estimatedHours}', style: TextStyle(color: context.farreyTextPrimary, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (!phase.completed)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await NavigatorService().markPhaseComplete(phase.roadmapId, phase.navigatorId);
                      if (c.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('${phase.title} completed! 🎉'),
                          backgroundColor: context.farreyPrimary,
                        ));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.farreyPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Mark Complete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
