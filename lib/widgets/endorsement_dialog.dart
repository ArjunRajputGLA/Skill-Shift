import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/endorsement_service.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';
import '../theme/app_spacing.dart';
import '../widgets/custom_chip.dart';

class EndorsementDialog extends StatefulWidget {
  final String sessionId;
  final String mentorUid;
  final String mentorName;

  const EndorsementDialog({
    super.key,
    required this.sessionId,
    required this.mentorUid,
    required this.mentorName,
  });

  @override
  State<EndorsementDialog> createState() => _EndorsementDialogState();
}

class _EndorsementDialogState extends State<EndorsementDialog> {
  int _rating = 0;
  final List<String> _selectedSkills = [];
  final List<String> _selectedTags = [];
  final TextEditingController _reviewController = TextEditingController();

  static const List<String> availableTags = [
    'Helpful',
    'Great Teacher',
    'Fast Learner',
    'Good Teammate',
    'Strong Problem Solver',
    'Friendly',
    'Professional',
    'Clear Communication',
    'UI/UX Expert',
    'Flutter Expert',
    'DSA Expert',
  ];

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _submitEndorsement() async {
    if (_rating == 0) {
      NotificationService.showError(context, 'Please select a star rating.');
      return;
    }

    final currentUser = context.read<AuthService>().currentUser;
    if (currentUser == null) return;

    NotificationService.showLoading(context);
    final error = await EndorsementService().endorse(
      endorseeId: widget.mentorUid,
      endorseeName: widget.mentorName,
      endorserId: currentUser.id,
      endorserName: currentUser.fullName,
      sessionId: widget.sessionId,
      skills: _selectedSkills,
      tags: _selectedTags,
      rating: _rating,
      reviewText: _reviewController.text.trim(),
    );

    if (context.mounted) {
      NotificationService.hideLoading(context);
      Navigator.pop(context);
      if (error != null) {
        NotificationService.showError(context, error);
      } else {
        NotificationService.showSuccess(context, 'Endorsement successfully sent!');
      }
    }
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return IconButton(
          icon: Icon(
            starIndex <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
            color: Colors.amber,
            size: 40,
          ),
          onPressed: () {
            setState(() {
              _rating = starIndex;
            });
          },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'How was your session with ${widget.mentorName}?',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              Expanded(
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(widget.mentorUid).get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    List<String> mentorSkills = [];
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      final userModel = UserModel.fromMap(data, snapshot.data!.id);
                      mentorSkills = userModel.skills;
                    }

                    return ListView(
                      controller: controller,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // RATING
                        const SizedBox(height: AppSpacing.md),
                        Center(child: _buildStarRating()),
                        const SizedBox(height: AppSpacing.xxl),

                        // SKILLS
                        if (mentorSkills.isNotEmpty) ...[
                          Text(
                            'Endorse Skills',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: mentorSkills.map((skill) {
                              final isSelected = _selectedSkills.contains(skill);
                              return FilterChip(
                                label: Text(skill),
                                selected: isSelected,
                                selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                                onSelected: (bool selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedSkills.add(skill);
                                    } else {
                                      _selectedSkills.remove(skill);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                        ],

                        // TAGS
                        Text(
                          'Experience Tags',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: availableTags.map((tag) {
                            final isSelected = _selectedTags.contains(tag);
                            return FilterChip(
                              label: Text(tag),
                              selected: isSelected,
                              selectedColor: theme.colorScheme.secondary.withValues(alpha: 0.2),
                              onSelected: (bool selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedTags.add(tag);
                                  } else {
                                    _selectedTags.remove(tag);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.xxl),

                        // REVIEW TEXT
                        Text(
                          'Optional Review',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _reviewController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'e.g. Explained concepts very clearly...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    );
                  },
                ),
              ),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _submitEndorsement,
                  child: const Text('Submit Endorsement', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }
}
