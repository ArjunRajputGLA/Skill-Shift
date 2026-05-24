import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/farrey_colors.dart';
import '../widgets/note_card.dart';
import '../models/farrey_models.dart';
import '../services/farrey_database_service.dart';

class FarreyHomeScreen extends StatefulWidget {
  const FarreyHomeScreen({super.key});

  @override
  State<FarreyHomeScreen> createState() => _FarreyHomeScreenState();
}

class _FarreyHomeScreenState extends State<FarreyHomeScreen> {
  final FarreyDatabaseService _dbService = FarreyDatabaseService();

  final List<String> _categories = [
    'DSA', 'Flutter', 'DBMS', 'OS', 'CN', 'ML', 'Mathematics', 'Placement', 'Interview Prep'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.farreyBackground,
      body: Stack(
        children: [
          // Main Scrollable Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 120, bottom: 100), // Padding for floating header and footer
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategories(context),
                const SizedBox(height: 32),
                _buildSection(
                  context: context,
                  title: 'Trending Notes',
                  stream: _dbService.getTrendingNotes(),
                ),
                const SizedBox(height: 32),
                _buildSection(
                  context: context,
                  title: 'Recently Uploaded',
                  stream: _dbService.getRecentNotes(),
                ),
              ],
            ),
          ),
          
          // Floating Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: context.farreySurface.withValues(alpha: context.isDark ? 0.7 : 0.8),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: context.isDark 
                              ? Colors.white.withValues(alpha: 0.05) 
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Notes Ecosystem',
                            style: TextStyle(
                              color: context.farreyTextPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.farreyPrimary.withValues(alpha: 0.1),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.notifications_none_rounded, color: context.farreyPrimary),
                              onPressed: () {},
                              splashRadius: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: context.farreySurfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.farreyBorder),
            ),
            child: Center(
              child: Text(
                _categories[index],
                style: TextStyle(
                  color: context.farreyTextSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({required BuildContext context, required String title, required Stream<List<FarreyNoteModel>> stream}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.farreyTextPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'See all',
                style: TextStyle(
                  color: context.farreyPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: StreamBuilder<List<FarreyNoteModel>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: context.farreyPrimary));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error loading notes', style: TextStyle(color: context.farreyError)));
              }
              
              final notes = snapshot.data ?? [];
              
              if (notes.isEmpty) {
                return Center(
                  child: Text(
                    'No notes found yet.',
                    style: TextStyle(color: context.farreyTextSecondary),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  return NoteCard(note: notes[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
