import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/farrey_colors.dart';
import '../screens/farrey_main_layout.dart';

class FarreyEntryWidget extends StatefulWidget {
  const FarreyEntryWidget({super.key});

  @override
  State<FarreyEntryWidget> createState() => _FarreyEntryWidgetState();
}

class _FarreyEntryWidgetState extends State<FarreyEntryWidget> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: GestureDetector(
              onTap: () {
                setState(() => _isExpanded = false);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FarreyMainLayout()),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: FarreyColors.surface.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: FarreyColors.primary.withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: FarreyColors.primary.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.library_books, color: FarreyColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Enter Farrey',
                          style: TextStyle(
                            color: FarreyColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [FarreyColors.primary, FarreyColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: FarreyColors.primary.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                _isExpanded ? Icons.close : Icons.auto_awesome,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
