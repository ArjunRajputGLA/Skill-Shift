import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/farrey_colors.dart';
import '../models/farrey_models.dart';
import '../widgets/note_card.dart';
import '../../services/auth_service.dart';

class FarreyProfileScreen extends StatelessWidget {
  const FarreyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    
    if (user == null) {
      return const Scaffold(
        backgroundColor: FarreyColors.background,
        body: Center(child: Text('Please log in.', style: TextStyle(color: FarreyColors.textPrimary))),
      );
    }

    return Scaffold(
      backgroundColor: FarreyColors.background,
      appBar: AppBar(
        backgroundColor: FarreyColors.surface,
        elevation: 0,
        title: const Text('My Farrey Profile', style: TextStyle(color: FarreyColors.textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: FarreyColors.textPrimary),
            onPressed: () {
              Navigator.of(context).pop(); // Go back to Skill Shift
            },
            tooltip: 'Return to Skill Shift',
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              color: FarreyColors.surface,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: FarreyColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 32, color: FarreyColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.fullName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: FarreyColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(fontSize: 14, color: FarreyColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn('Reputation', 'Great'),
                      _buildStatColumn('Role', user.userType ?? 'Student'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'My Uploads',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FarreyColors.textPrimary),
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
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: FarreyColors.primary)),
                );
              }
              
              final docs = snapshot.data?.docs ?? [];
              
              if (docs.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text('You haven\'t uploaded any notes yet.', style: TextStyle(color: FarreyColors.textSecondary)),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FarreyColors.primary),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: FarreyColors.textSecondary),
        ),
      ],
    );
  }
}
