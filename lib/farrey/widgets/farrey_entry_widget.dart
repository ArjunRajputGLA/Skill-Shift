import 'package:flutter/material.dart';
import '../screens/farrey_main_layout.dart';

class FarreyEntryWidget extends StatelessWidget {
  const FarreyEntryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FarreyMainLayout()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)], // Vibrant purple
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            bottomLeft: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x667C3AED),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'farrey',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900, // Extra bold
                fontSize: 16,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(width: 4),
            Icon(
              Icons.arrow_outward_rounded,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
