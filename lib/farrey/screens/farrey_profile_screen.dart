import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/farrey_colors.dart';
import '../models/farrey_models.dart';
import '../widgets/note_card.dart';
import '../../services/auth_service.dart';
import '../../theme/theme_provider.dart';

class FarreyProfileScreen extends StatefulWidget {
  const FarreyProfileScreen({super.key});

  @override
  State<FarreyProfileScreen> createState() => _FarreyProfileScreenState();
}

class _FarreyProfileScreenState extends State<FarreyProfileScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = context.watch<AuthService>().currentUser;
    
    if (user == null) {
      return Scaffold(
        backgroundColor: context.farreyBackground,
        body: Center(child: Text('Please log in.', style: TextStyle(color: context.farreyTextPrimary))),
      );
    }

    return Scaffold(
      backgroundColor: context.farreyBackground,
      body: RefreshIndicator(
        color: context.farreyPrimary,
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
          setState(() {});
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.only(top: 16),
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
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: context.farreyPrimary)),
                  );
                }
                
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text('Error loading uploads.', style: TextStyle(color: context.farreyError)),
                    ),
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

                final notes = docs.map((doc) => FarreyNoteModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                )).toList();

                // Sort locally by uploadTime descending
                notes.sort((a, b) => b.uploadTime.compareTo(a.uploadTime));

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
                        return NoteCard(note: notes[index]);
                      },
                      childCount: notes.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
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
