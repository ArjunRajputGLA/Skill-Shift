import 'package:flutter/material.dart';
import '../models/farrey_models.dart';
import '../theme/farrey_colors.dart';
import '../screens/note_preview_screen.dart';
import 'package:intl/intl.dart';

class NoteCard extends StatelessWidget {
  final FarreyNoteModel note;

  const NoteCard({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => NotePreviewScreen(note: note)),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: FarreyColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FarreyColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top banner indicating file type or cover
            Container(
              height: 80,
              decoration: const BoxDecoration(
                color: FarreyColors.surfaceElevated,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Center(
                child: Icon(
                  note.fileType.toLowerCase() == 'pdf' ? Icons.picture_as_pdf : Icons.image,
                  size: 40,
                  color: FarreyColors.primary.withValues(alpha: 0.5),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FarreyColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    note.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FarreyColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: FarreyColors.warning, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        note.averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: FarreyColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.download, color: FarreyColors.textSecondary, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        '${note.totalDownloads}',
                        style: const TextStyle(
                          color: FarreyColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
