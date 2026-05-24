import 'dart:ui';
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
      return Scaffold(
        backgroundColor: context.farreyBackground,
        body: Center(child: Text('Please log in to view saved notes.', style: TextStyle(color: context.farreyTextPrimary))),
      );
    }

    return Scaffold(
      backgroundColor: context.farreyBackground,
      body: Stack(
        children: [
          // Content
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('saved_notes')
                .where('uid', isEqualTo: currentUser.id)
                // Removed orderBy to prevent missing index error. 
                // Alternatively, we could sort locally.
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
                return Center(
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
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 110, bottom: 120, left: 16, right: 16),
                physics: const BouncingScrollPhysics(),
                itemCount: savedDocs.length,
                itemBuilder: (context, index) {
                  final docData = savedDocs[index].data() as Map<String, dynamic>;
                  final noteId = docData['noteId'] as String;
                  
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
              );
            },
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
                      child: Text(
                        'Saved Notes',
                        style: TextStyle(
                          color: context.farreyTextPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          letterSpacing: -0.5,
                        ),
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
