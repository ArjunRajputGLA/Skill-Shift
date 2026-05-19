import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'posts_screen.dart';
import 'chat_list_screen.dart';
import 'profile_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => MainLayoutState();
}

class MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  late PageController pageController;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ExploreScreen(),
    const PostsScreen(),
    const ChatListScreen(),
    const ProfileScreen(),
  ];
  
  final List<String> _titles = [
    'Skill Shift',
    'Explore',
    'Posts',
    'Messages',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true, 
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
            child: AppBar(
              title: Text(_titles[_currentIndex]),
              centerTitle: false,
              elevation: 0,
              backgroundColor: (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface).withOpacity(isDark ? 0.7 : 0.8),
              surfaceTintColor: Colors.transparent,
              systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
              actions: [
                IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  ),
                  onPressed: () {
                    context.read<ThemeProvider>().toggleTheme();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: () => context.read<AuthService>().signOut(),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: PageView(
        controller: pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: _FloatingGlassNav(
            currentIndex: _currentIndex,
            isDark: isDark,
            onTap: _onTabTapped,
          ),
        ),
      ),
    );
  }
}

class _FloatingGlassNav extends StatelessWidget {
  final int currentIndex;
  final bool isDark;
  final Function(int) onTap;

  const _FloatingGlassNav({
    required this.currentIndex,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 65,
          decoration: BoxDecoration(
            color: (isDark ? AppColors.darkSurfaceElevated : Colors.white).withOpacity(isDark ? 0.7 : 0.8),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                isSelected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.search_outlined,
                activeIcon: Icons.search_rounded,
                label: 'Explore',
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.add_box_outlined,
                activeIcon: Icons.add_box_rounded,
                label: 'Post',
                isSelected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble_rounded,
                label: 'Messages',
                isSelected: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                isSelected: currentIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCirc,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primary.withOpacity(0.15) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          isSelected ? activeIcon : icon,
          size: 26,
          color: isSelected 
              ? theme.colorScheme.primary 
              : theme.iconTheme.color?.withOpacity(0.6),
        ),
      ),
    );
  }
}
