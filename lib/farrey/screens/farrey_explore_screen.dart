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
      backgroundColor: FarreyColors.background,
      appBar: AppBar(
        backgroundColor: FarreyColors.surface,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: FarreyColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search notes, subjects, tags...',
            hintStyle: TextStyle(color: FarreyColors.textSecondary.withValues(alpha: 0.6)),
            prefixIcon: const Icon(Icons.search, color: FarreyColors.textSecondary),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear, color: FarreyColors.textSecondary),
              onPressed: () {
                _searchController.clear();
                _performSearch('');
              },
            ),
            filled: true,
            fillColor: FarreyColors.surfaceElevated,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: _performSearch,
          onChanged: (val) {
            // Optional: Debounce search here for live search
          },
        ),
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator(color: FarreyColors.primary))
          : _searchResults.isEmpty && _searchController.text.isNotEmpty
              ? const Center(
                  child: Text(
                    'No results found.',
                    style: TextStyle(color: FarreyColors.textSecondary),
                  ),
                )
              : _searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, size: 80, color: FarreyColors.border),
                          const SizedBox(height: 16),
                          const Text(
                            'Discover knowledge in Farrey',
                            style: TextStyle(color: FarreyColors.textSecondary, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
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
    );
  }
}
