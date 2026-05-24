import 'package:flutter/material.dart';
import '../screens/farrey_main_layout.dart';

class FarreyEntryWidget extends StatefulWidget {
  const FarreyEntryWidget({super.key});

  @override
  State<FarreyEntryWidget> createState() => _FarreyEntryWidgetState();
}

class _FarreyEntryWidgetState extends State<FarreyEntryWidget> {
  Offset? _position;
  final GlobalKey _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    
    // Initial position: slightly above bottom nav to not overlap profile icon
    _position ??= Offset(size.width - 90, size.height - 200);

    final isLeft = _position!.dx < size.width / 2;

    return Positioned(
      left: _position!.dx,
      top: _position!.dy,
      child: GestureDetector(
        key: _key,
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              _position!.dx + details.delta.dx,
              _position!.dy + details.delta.dy,
            );
          });
        },
        onPanEnd: (details) {
          double widgetWidth = 90.0;
          double widgetHeight = 44.0;
          if (_key.currentContext != null) {
            final box = _key.currentContext!.findRenderObject() as RenderBox;
            widgetWidth = box.size.width;
            widgetHeight = box.size.height;
          }

          double newX = _position!.dx;
          double newY = _position!.dy;

          // Snap to left or right edge
          if (newX + (widgetWidth / 2) < size.width / 2) {
            newX = 0;
          } else {
            newX = size.width - widgetWidth;
          }

          // Keep within vertical bounds
          if (newY < padding.top) newY = padding.top;
          if (newY > size.height - padding.bottom - widgetHeight) {
            newY = size.height - padding.bottom - widgetHeight;
          }

          setState(() {
            _position = Offset(newX, newY);
          });
        },
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FarreyMainLayout()),
          );
        },
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isLeft ? 0 : 24),
                bottomLeft: Radius.circular(isLeft ? 0 : 24),
                topRight: Radius.circular(isLeft ? 24 : 0),
                bottomRight: Radius.circular(isLeft ? 24 : 0),
              ),
              boxShadow: const [
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
                    fontWeight: FontWeight.w900,
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
        ),
      ),
    );
  }
}
