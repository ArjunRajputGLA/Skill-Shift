import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/farrey_colors.dart';
import '../services/farrey_database_service.dart';
import '../models/farrey_models.dart';
import '../widgets/note_card.dart';
import '../../services/auth_service.dart';
import '../../theme/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FarreySavedScreen extends StatelessWidget {
  const FarreySavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthService>().currentUser;
    final dbService = FarreyDatabaseService();

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: context.farreyBackground,
        body: Center(child: Text('Please log in to view saved notes.', style: TextStyle(color: context.farreyTextPrimary))),
      );
    }

    return Scaffold(
      backgroundColor: context.farreyBackground,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('saved_notes')
            .where('uid', isEqualTo: currentUser.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: context.farreyPrimary));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading saved notes: ${snapshot.error}', style: TextStyle(color: context.farreyError)));
          }

          final savedDocs = snapshot.data?.docs ?? [];

          if (savedDocs.isEmpty) {
            return RefreshIndicator(
              color: context.farreyPrimary,
              onRefresh: () async {
                await Future.delayed(const Duration(seconds: 1));
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 150),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bookmark_border_rounded, size: 80, color: context.farreyBorder),
                        const SizedBox(height: 16),
                        Text(
                          'No saved notes yet.',
                          style: TextStyle(color: context.farreyTextSecondary, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: context.farreyPrimary,
            onRefresh: () async {
              await Future.delayed(const Duration(seconds: 1));
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 110, bottom: 120, left: 16, right: 16),
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              itemCount: savedDocs.length,
              itemBuilder: (context, index) {
                final docData = savedDocs[index].data() as Map<String, dynamic>;
                final noteId = docData['noteId'] as String;
                
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('farrey_notes').doc(noteId).get(),
                  builder: (context, noteSnapshot) {
                    if (!noteSnapshot.hasData || !noteSnapshot.data!.exists) {
                      return const SizedBox.shrink(); 
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
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      note.title,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.farreyTextPrimary),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      note.description,
                                      style: TextStyle(color: context.farreyTextSecondary),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Spacer(),
                                    TextButton.icon(
                                      onPressed: () {
                                        dbService.toggleSaveNote(currentUser.id, noteId, false);
                                      },
                                      icon: Icon(Icons.bookmark_remove_rounded, color: context.farreyError),
                                      label: Text('Remove', style: TextStyle(color: context.farreyError)),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        alignment: Alignment.centerLeft,
                                      ),
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
            ),
          );
        },
      ),
    );
  }
}
