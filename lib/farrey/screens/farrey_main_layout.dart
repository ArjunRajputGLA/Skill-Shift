import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/farrey_colors.dart';
import '../../theme/theme_provider.dart';
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

  final List<String> _titles = [
    'Notes Ecosystem',
    'Explore Notes',
    'Upload Note',
    'Saved Notes',
    'My Profile',
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

  Widget _buildUnifiedHeader(BuildContext context) {
    return Align(
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    Flexible(
                      child: Text(
                        _titles[_currentIndex],
                        style: TextStyle(
                          color: context.farreyTextPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
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
                        color: context.farreyPrimary.withValues(alpha: 0.1),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.notifications_none_rounded, color: context.farreyPrimary, size: 18),
                        onPressed: () {},
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.farreyBackground,
      extendBody: true, 
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: _screens,
          ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: _buildUnifiedHeader(context),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
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
          padding: const EdgeInsets.symmetric(horizontal: 4),
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
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? context.farreyPrimary.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              if (isSelected) ...[
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
