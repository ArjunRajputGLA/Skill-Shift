import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/farrey_colors.dart';
import '../widgets/note_card.dart';
import '../models/farrey_models.dart';
import '../services/farrey_database_service.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_provider.dart';
import '../../services/auth_service.dart';
import 'farrey_see_all_screen.dart';
import 'navigator_dashboard_screen.dart';

class FarreyHomeScreen extends StatefulWidget {
  const FarreyHomeScreen({super.key});

  @override
  State<FarreyHomeScreen> createState() => _FarreyHomeScreenState();
}

class _FarreyHomeScreenState extends State<FarreyHomeScreen> with AutomaticKeepAliveClientMixin {
  final FarreyDatabaseService _dbService = FarreyDatabaseService();
  final ScrollController _scrollController = ScrollController();

  final List<String> _categories = [
    'DSA', 'Flutter', 'DBMS', 'OS', 'CN', 'ML', 'Mathematics', 'Placement', 'Interview Prep',
    'AI', 'Data Science', 'System Design', 'Web Dev', 'App Dev', 'UI/UX', 'Cloud Computing',
    'Cybersecurity', 'Blockchain', 'Competitive Programming', 'Software Engineering'
  ];
  final List<String> _selectedCategories = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    
    final currentPosition = _scrollController.position.pixels;
    final maxExtent = _scrollController.position.maxScrollExtent;
    final remainingDistance = maxExtent - currentPosition;
    
    if (remainingDistance > 0) {
      final durationInSeconds = (remainingDistance / 30).round();
      if (durationInSeconds > 0) {
        _scrollController.animateTo(
          maxExtent,
          duration: Duration(seconds: durationInSeconds),
          curve: Curves.linear,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currentUserId = context.read<AuthService>().currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: context.farreyBackground,
      body: RefreshIndicator(
        color: context.farreyPrimary,
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.only(top: 16, bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategories(context),
              const SizedBox(height: 32),
              _buildSection(
                context: context,
                title: _selectedCategories.isEmpty ? 'Trending Notes' : 'Trending in ${_selectedCategories.length} selected',
                stream: _dbService.getTrendingNotes(currentUserId, categories: _selectedCategories),
              ),
              const SizedBox(height: 32),
              _buildSection(
                context: context,
                title: _selectedCategories.isEmpty ? 'Recently Uploaded' : 'Recent in ${_selectedCategories.length} selected',
                stream: _dbService.getRecentNotes(currentUserId, categories: _selectedCategories),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    return SizedBox(
      height: 40,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          if (notification is ScrollEndNotification) {
            _startAutoScroll();
          }
          return false;
        },
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _categories.length * 100, // Infinity simulation
          itemBuilder: (context, index) {
            final categoryIndex = index % _categories.length;
            final category = _categories[categoryIndex];
            final isSelected = _selectedCategories.contains(category);
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedCategories.remove(category);
                  } else {
                    _selectedCategories.add(category);
                  }
                });
                // Ensure scroll continues after a tiny delay to allow layout rebuild
                Future.delayed(const Duration(milliseconds: 50), () {
                  if (mounted) _startAutoScroll();
                });
              },
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? context.farreyPrimary : context.farreySurfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? context.farreyPrimary : context.farreyBorder),
                ),
                child: Center(
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? Colors.white : context.farreyTextSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
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
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FarreySeeAllScreen(
                        title: title,
                        stream: stream,
                      ),
                    ),
                  );
                },
                child: Text(
                  'See all',
                  style: TextStyle(
                    color: context.farreyPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
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
