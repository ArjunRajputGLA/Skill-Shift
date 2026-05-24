import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/farrey_colors.dart';
import 'farrey_home_screen.dart';
import 'farrey_explore_screen.dart';
import 'farrey_upload_screen.dart';
import 'farrey_saved_screen.dart';
import 'farrey_profile_screen.dart';

class FarreyMainLayout extends StatefulWidget {
  const FarreyMainLayout({super.key});

  @override
  State<FarreyMainLayout> createState() => _FarreyMainLayoutState();
}

class _FarreyMainLayoutState extends State<FarreyMainLayout> {
  int _currentIndex = 0;
  late PageController _pageController;

  final List<Widget> _screens = [
    const FarreyHomeScreen(),
    const FarreyExploreScreen(),
    const FarreyUploadScreen(),
    const FarreySavedScreen(),
    const FarreyProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.farreyBackground,
      extendBody: true, // Allows content to scroll underneath the floating nav bar
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Use bottom nav to switch
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: _FloatingGlassNav(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
          ),
        ),
      ),
    );
  }
}

class _FloatingGlassNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _FloatingGlassNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: context.farreySurface.withValues(alpha: isDark ? 0.7 : 0.8),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.05) 
                  : Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded, label: 'Home', index: 0, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.search_rounded, label: 'Explore', index: 1, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.add_circle_rounded, label: 'Upload', index: 2, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.bookmark_rounded, label: 'Saved', index: 3, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.person_rounded, label: 'Profile', index: 4, currentIndex: currentIndex, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;
    final color = isSelected ? context.farreyPrimary : context.farreyTextSecondary;
    
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.farreyPrimary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
