import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:marquee/marquee.dart';
import '../theme/farrey_colors.dart';
import '../../theme/theme_provider.dart';
import 'farrey_home_screen.dart';
import 'farrey_explore_screen.dart';
import 'farrey_upload_screen.dart';
import 'farrey_saved_screen.dart';
import 'farrey_profile_screen.dart';
import '../../services/auth_service.dart';
import 'navigator_list_screen.dart';

class FarreyMainLayout extends StatefulWidget {
  const FarreyMainLayout({super.key});

  @override
  State<FarreyMainLayout> createState() => _FarreyMainLayoutState();
}

class _FarreyMainLayoutState extends State<FarreyMainLayout> {
  int _currentIndex = 0;
  late PageController _pageController;
  
  Offset _fabPosition = const Offset(0, 0);
  bool _isFabInitialized = false;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isFabInitialized) {
      final size = MediaQuery.of(context).size;
      _fabPosition = Offset(size.width - 170, size.height - 250);
      _isFabInitialized = true;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 24,
                        child: Marquee(
                          text: _titles[_currentIndex],
                          style: TextStyle(
                            color: context.farreyTextPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: -0.5,
                          ),
                          scrollAxis: Axis.horizontal,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          blankSpace: 30.0,
                          velocity: 40.0,
                          pauseAfterRound: const Duration(seconds: 2),
                        ),
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
    final currentUserId = context.read<AuthService>().currentUser?.id ?? '';
    
    return Stack(
      children: [
        Scaffold(
          backgroundColor: context.farreyBackground,
          extendBody: true, 
          extendBodyBehindAppBar: true,
          resizeToAvoidBottomInset: false,
          body: Column(
            children: [
              _buildUnifiedHeader(context),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  children: _screens,
                ),
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
        ),
        Positioned(
          left: _fabPosition.dx,
          top: _fabPosition.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _fabPosition += details.delta;
                
                final size = MediaQuery.of(context).size;
                if (_fabPosition.dx < 0) _fabPosition = Offset(0, _fabPosition.dy);
                if (_fabPosition.dy < 0) _fabPosition = Offset(_fabPosition.dx, 0);
                if (_fabPosition.dx > size.width - 160) _fabPosition = Offset(size.width - 160, _fabPosition.dy);
                if (_fabPosition.dy > size.height - 150) _fabPosition = Offset(_fabPosition.dx, size.height - 150);
              });
            },
            child: Material(
              color: Colors.transparent,
              child: FloatingActionButton.extended(
                heroTag: 'ai_navigator_fab_global',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => NavigatorListScreen(uid: currentUserId)),
                  );
                },
                backgroundColor: context.farreyPrimary,
                icon: const Icon(Icons.explore_rounded, color: Colors.white),
                label: const Text('AI Navigator', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                elevation: 8,
              ),
            ),
          ),
        ),
      ],
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
