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

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            itemCount: phases.length,
            itemBuilder: (context, index) {
              final phase = phases[index];
              final isEven = index % 2 == 0;
              final isLast = index == phases.length - 1;

              // Duolingo style path visualization
              return SizedBox(
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Vertical connecting line
                    if (!isLast)
                      Positioned(
                        top: 80,
                        bottom: -80,
                        child: Container(
                          width: 8,
                          decoration: BoxDecoration(
                            color: phase.completed ? context.farreyPrimary : context.farreySurfaceElevated,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    
                    // Animated Milestone Node
                    Positioned(
                      left: isEven ? 20 : null,
                      right: !isEven ? 20 : null,
                      child: GestureDetector(
                        onTap: () {
                          // Show phase details in bottom sheet
                          _showPhaseDetails(context, phase);
                        },
                        child: Column(
                          children: [
                            Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: phase.completed ? context.farreyPrimary : context.farreySurfaceElevated,
                                border: Border.all(
                                  color: phase.completed ? context.farreyPrimary : context.farreyBorder,
                                  width: 4,
                                ),
                                boxShadow: [
                                  if (phase.completed)
                                    BoxShadow(
                                      color: context.farreyPrimary.withValues(alpha: 0.5),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    )
                                ],
                              ),
                              child: Icon(
                                phase.completed ? Icons.check_rounded : Icons.lock_rounded,
                                color: phase.completed ? Colors.white : context.farreyTextSecondary,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              phase.title,
                              style: TextStyle(
                                color: context.farreyTextPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
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
      builder: (c) => Padding(
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
                Text('Estimated Time: \${phase.estimatedHours}', style: TextStyle(color: context.farreyTextPrimary, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 24),
            if (!phase.completed)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Start learning -> Navigate to relevant content or mark complete
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Starting \${phase.title}...')));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.farreyPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Start Phase', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
