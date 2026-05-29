import 'package:flutter/material.dart';
import '../models/farrey_models.dart';
import '../widgets/note_card.dart';
import '../theme/farrey_colors.dart';
import 'note_preview_screen.dart';

class FarreySeeAllScreen extends StatelessWidget {
  final String title;
  final Stream<List<FarreyNoteModel>> stream;

  const FarreySeeAllScreen({
    Key? key,
    required this.title,
    required this.stream,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.farreyBackground,
      appBar: AppBar(
        title: Text(title, style: TextStyle(color: context.farreyTextPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: context.farreySurface,
        elevation: 0,
        iconTheme: IconThemeData(color: context.farreyTextPrimary),
      ),
      body: StreamBuilder<List<FarreyNoteModel>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading notes: ${snapshot.error}', style: TextStyle(color: context.farreyError)));
          }

          final notes = snapshot.data ?? [];
          
          if (notes.isEmpty) {
            return Center(
              child: Text(
                'No notes found.',
                style: TextStyle(color: context.farreyTextSecondary, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotePreviewScreen(note: note),
                      ),
                    );
                  },
                  child: NoteCard(
                    note: note,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
