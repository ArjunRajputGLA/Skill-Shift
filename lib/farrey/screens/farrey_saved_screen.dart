import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/farrey_colors.dart';
import '../services/farrey_database_service.dart';
import '../models/farrey_models.dart';
import '../widgets/note_card.dart';
import '../../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FarreySavedScreen extends StatelessWidget {
  const FarreySavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthService>().currentUser;
    final dbService = FarreyDatabaseService();

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: FarreyColors.background,
        body: Center(child: Text('Please log in to view saved notes.', style: TextStyle(color: FarreyColors.textPrimary))),
      );
    }

    return Scaffold(
      backgroundColor: FarreyColors.background,
      appBar: AppBar(
        backgroundColor: FarreyColors.surface,
        elevation: 0,
        title: const Text(
          'Saved Notes',
          style: TextStyle(color: FarreyColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('saved_notes')
            .where('uid', isEqualTo: currentUser.id)
            .orderBy('savedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: FarreyColors.primary));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading saved notes.', style: TextStyle(color: FarreyColors.error)));
          }

          final savedDocs = snapshot.data?.docs ?? [];

          if (savedDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 80, color: FarreyColors.border),
                  const SizedBox(height: 16),
                  const Text(
                    'No saved notes yet.',
                    style: TextStyle(color: FarreyColors.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // Fetch the actual note data for each saved note id
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: savedDocs.length,
            itemBuilder: (context, index) {
              final noteId = savedDocs[index]['noteId'] as String;
              
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('farrey_notes').doc(noteId).get(),
                builder: (context, noteSnapshot) {
                  if (!noteSnapshot.hasData || !noteSnapshot.data!.exists) {
                    return const SizedBox.shrink(); // Note might have been deleted
                  }
                  
                  final note = FarreyNoteModel.fromMap(
                    noteSnapshot.data!.data() as Map<String, dynamic>,
                    noteSnapshot.data!.id,
                  );
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: SizedBox(
                      height: 220,
                      child: Row(
                        children: [
                          NoteCard(note: note),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    note.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: FarreyColors.textPrimary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    note.description,
                                    style: const TextStyle(color: FarreyColors.textSecondary),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: () {
                                      dbService.toggleSaveNote(currentUser.id, noteId, false);
                                    },
                                    icon: const Icon(Icons.bookmark_remove, color: FarreyColors.error),
                                    label: const Text('Remove', style: TextStyle(color: FarreyColors.error)),
                                  )
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
