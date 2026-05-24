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
      backgroundColor: FarreyColors.background,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Use bottom nav to switch
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: FarreyColors.surface,
        selectedItemColor: FarreyColors.primary,
        unselectedItemColor: FarreyColors.textSecondary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Upload'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark_border), label: 'Saved'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
