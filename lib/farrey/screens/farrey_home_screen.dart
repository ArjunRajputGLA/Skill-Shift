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
      backgroundColor: FarreyColors.background,
      appBar: AppBar(
        backgroundColor: FarreyColors.surface,
        elevation: 0,
        title: const Text(
          'Farrey Ecosystem',
          style: TextStyle(
            color: FarreyColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: FarreyColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildCategories(),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Trending Notes',
              stream: _dbService.getTrendingNotes(),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Recently Uploaded',
              stream: _dbService.getRecentNotes(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: FarreyColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: FarreyColors.primary.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                _categories[index],
                style: const TextStyle(
                  color: FarreyColors.primary,
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

  Widget _buildSection({required String title, required Stream<List<FarreyNoteModel>> stream}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: FarreyColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'See all',
                style: TextStyle(
                  color: FarreyColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 190,
          child: StreamBuilder<List<FarreyNoteModel>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: FarreyColors.primary));
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading notes', style: TextStyle(color: FarreyColors.error)));
              }
              
              final notes = snapshot.data ?? [];
              
              if (notes.isEmpty) {
                return const Center(
                  child: Text(
                    'No notes found yet.',
                    style: TextStyle(color: FarreyColors.textSecondary),
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
