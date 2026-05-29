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

class FarreySavedScreen extends StatefulWidget {
  const FarreySavedScreen({super.key});

  @override
  State<FarreySavedScreen> createState() => _FarreySavedScreenState();
}

class _FarreySavedScreenState extends State<FarreySavedScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
            child: GridView.builder(
              padding: const EdgeInsets.only(top: 16, bottom: 120, left: 16, right: 16),
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: savedDocs.length,
              itemBuilder: (context, index) {
                final docData = savedDocs[index].data() as Map<String, dynamic>;
                final noteId = docData['noteId'] as String;
                
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('farrey_notes').doc(noteId).get(),
                  builder: (context, noteSnapshot) {
                    if (noteSnapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        decoration: BoxDecoration(
                          color: context.farreySurface.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(color: context.farreyPrimary, strokeWidth: 2),
                        ),
                      );
                    }
                    if (!noteSnapshot.hasData || !noteSnapshot.data!.exists) {
                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: context.farreySurface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text('Note unavailable', style: TextStyle(color: context.farreyTextSecondary, fontSize: 12), textAlign: TextAlign.center),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                dbService.toggleSaveNote(currentUser.id, noteId, false);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: context.farreySurface.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    )
                                  ]
                                ),
                                child: Icon(Icons.bookmark_remove_rounded, color: context.farreyError, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ); 
                    }
                    
                    final note = FarreyNoteModel.fromMap(
                      noteSnapshot.data!.data() as Map<String, dynamic>,
                      noteSnapshot.data!.id,
                    );
                    
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: NoteCard(note: note),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              dbService.toggleSaveNote(currentUser.id, noteId, false);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: context.farreySurface.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  )
                                ]
                              ),
                              child: Icon(Icons.bookmark_remove_rounded, color: context.farreyError, size: 20),
                            ),
                          ),
                        ),
                      ],
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
