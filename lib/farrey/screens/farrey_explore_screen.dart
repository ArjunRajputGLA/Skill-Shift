import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/farrey_colors.dart';
import '../services/farrey_database_service.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_provider.dart';
import '../models/farrey_models.dart';
import '../widgets/note_card.dart';

class FarreyExploreScreen extends StatefulWidget {
  const FarreyExploreScreen({super.key});

  @override
  State<FarreyExploreScreen> createState() => _FarreyExploreScreenState();
}

class _FarreyExploreScreenState extends State<FarreyExploreScreen> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final FarreyDatabaseService _dbService = FarreyDatabaseService();
  
  List<FarreyNoteModel> _searchResults = [];
  bool _isSearching = false;

  @override
  bool get wantKeepAlive => true;

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
    super.build(context);
    return Scaffold(
      backgroundColor: context.farreyBackground,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 0.0, left: 16, right: 16, bottom: 16),
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: context.farreySurface.withValues(alpha: context.isDark ? 0.7 : 0.8),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: context.isDark 
                        ? Colors.white.withValues(alpha: 0.05) 
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: context.farreyTextSecondary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: context.farreyTextPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search notes, subjects...',
                          hintStyle: TextStyle(color: context.farreyTextSecondary, fontSize: 14),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: _performSearch,
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: context.farreyTextSecondary, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                          FocusScope.of(context).unfocus();
                        },
                        splashRadius: 20,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
            ),
            
            Expanded(
              child: RefreshIndicator(
                color: context.farreyPrimary,
                onRefresh: () async {
                  if (_searchController.text.isNotEmpty) {
                    _performSearch(_searchController.text);
                  }
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: _isSearching
                    ? Center(child: CircularProgressIndicator(color: context.farreyPrimary))
                    : _searchResults.isEmpty && _searchController.text.isNotEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 100),
                              Center(
                                child: Text(
                                  'No results found.',
                                  style: TextStyle(color: context.farreyTextSecondary),
                                ),
                              ),
                            ],
                          )
                        : _searchResults.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  const SizedBox(height: 100),
                                  Center(
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
                                  ),
                                ],
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 100),
                                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
            ),
          ],
        ),
    );
  }
}
