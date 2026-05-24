import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/farrey_colors.dart';
import '../models/farrey_models.dart';
import '../widgets/note_card.dart';
import '../../services/auth_service.dart';
import '../../theme/theme_provider.dart';

class FarreyProfileScreen extends StatelessWidget {
  const FarreyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    
    if (user == null) {
      return Scaffold(
        backgroundColor: context.farreyBackground,
        body: Center(child: Text('Please log in.', style: TextStyle(color: context.farreyTextPrimary))),
      );
    }

    return Scaffold(
      backgroundColor: context.farreyBackground,
      body: Stack(
        children: [
          // Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.only(top: 110),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: context.farreySurface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: context.farreyBorder),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: context.farreyPrimary.withValues(alpha: 0.1),
                          child: Text(
                            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                            style: TextStyle(fontSize: 32, color: context.farreyPrimary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.fullName,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.farreyTextPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: TextStyle(fontSize: 14, color: context.farreyTextSecondary),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatColumn(context, 'Reputation', 'Great'),
                            _buildStatColumn(context, 'Role', user.userType ?? 'Student'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'My Uploads',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.farreyTextPrimary),
                  ),
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('farrey_notes')
                    .where('uploaderUid', isEqualTo: user.id)
                    .orderBy('uploadTime', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator(color: context.farreyPrimary)),
                    );
                  }
                  
                  final docs = snapshot.data?.docs ?? [];
                  
                  if (docs.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text('You haven\'t uploaded any notes yet.', style: TextStyle(color: context.farreyTextSecondary)),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final note = FarreyNoteModel.fromMap(
                            docs[index].data() as Map<String, dynamic>,
                            docs[index].id,
                          );
                          return NoteCard(note: note);
                        },
                        childCount: docs.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          
          // Floating Header
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'My Profile',
                            style: TextStyle(
                              color: context.farreyTextPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.farreySecondary.withValues(alpha: 0.1),
                            ),
                            child: IconButton(
                              icon: Icon(
                                context.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                color: context.farreySecondary,
                                size: 18,
                              ),
                              onPressed: () {
                                context.read<ThemeProvider>().toggleTheme();
                              },
                              splashRadius: 20,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.farreyError.withValues(alpha: 0.1),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.exit_to_app_rounded, color: context.farreyError, size: 18),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              tooltip: 'Return to Skill Shift',
                              splashRadius: 20,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
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

  Widget _buildStatColumn(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.farreyPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: context.farreyTextSecondary),
        ),
      ],
    );
  }
}
