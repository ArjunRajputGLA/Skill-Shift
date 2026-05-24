import 'package:flutter/material.dart';
import '../models/farrey_models.dart';
import '../theme/farrey_colors.dart';
import '../screens/note_preview_screen.dart';

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
          color: context.farreySurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.farreyBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top banner indicating file type or cover
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: context.farreySurfaceElevated,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Center(
                child: Icon(
                  note.fileType.toLowerCase() == 'pdf' ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                  size: 40,
                  color: context.farreyPrimary.withValues(alpha: 0.5),
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
                    style: TextStyle(
                      color: context.farreyTextPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    note.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.farreyTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, color: context.farreyWarning, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        note.averageRating.toStringAsFixed(1),
                        style: TextStyle(
                          color: context.farreyTextSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.download_rounded, color: context.farreyTextSecondary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${note.totalDownloads}',
                        style: TextStyle(
                          color: context.farreyTextSecondary,
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
