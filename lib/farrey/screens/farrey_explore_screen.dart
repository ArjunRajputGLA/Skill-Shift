import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/farrey_colors.dart';
import '../services/farrey_database_service.dart';
import '../models/farrey_models.dart';
import '../widgets/note_card.dart';

class FarreyExploreScreen extends StatefulWidget {
  const FarreyExploreScreen({super.key});

  @override
  State<FarreyExploreScreen> createState() => _FarreyExploreScreenState();
}

class _FarreyExploreScreenState extends State<FarreyExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FarreyDatabaseService _dbService = FarreyDatabaseService();
  
  List<FarreyNoteModel> _searchResults = [];
  bool _isSearching = false;

  void _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final results = await _dbService.searchNotes(query);
    
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.farreyBackground,
      body: Stack(
        children: [
          // Content
          Padding(
            padding: const EdgeInsets.only(top: 110, bottom: 100),
            child: _isSearching
              ? Center(child: CircularProgressIndicator(color: context.farreyPrimary))
              : _searchResults.isEmpty && _searchController.text.isNotEmpty
                  ? Center(
                      child: Text(
                        'No results found.',
                        style: TextStyle(color: context.farreyTextSecondary),
                      ),
                    )
                  : _searchResults.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_rounded, size: 80, color: context.farreyBorder),
                              const SizedBox(height: 16),
                              Text(
                                'Discover knowledge in Notes Ecosystem',
                                style: TextStyle(color: context.farreyTextSecondary, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            return NoteCard(note: _searchResults[index]);
                          },
                        ),
          ),
          
          // Floating Search Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.farreySurface.withValues(alpha: context.isDark ? 0.7 : 0.8),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: context.isDark 
                              ? Colors.white.withValues(alpha: 0.05) 
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: context.farreyTextPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search notes, subjects, tags...',
                          hintStyle: TextStyle(color: context.farreyTextSecondary.withValues(alpha: 0.6)),
                          prefixIcon: Icon(Icons.search_rounded, color: context.farreyTextSecondary),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.clear_rounded, color: context.farreyTextSecondary),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch('');
                            },
                          ),
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: InputBorder.none,
                        ),
                        onSubmitted: _performSearch,
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
}
