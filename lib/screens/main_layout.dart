import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_provider.dart';
import '../services/auth_service.dart';
import '../widgets/gradient_background.dart';
import '../widgets/avatar_widget.dart';
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

  // Per-screen accent colors for gradient background
  static const List<List<Color>> _screenAccents = [
    [AppColors.homeAccent1, AppColors.homeAccent2],
    [AppColors.exploreAccent1, AppColors.exploreAccent2],
    [AppColors.postsAccent1, AppColors.postsAccent2],
    [AppColors.messagesAccent1, AppColors.messagesAccent2],
    [AppColors.profileAccent1, AppColors.profileAccent2],
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
      duration: AppSpacing.durationNormal,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: GradientBackground(
        accentColor1: _screenAccents[_currentIndex][0],
        accentColor2: _screenAccents[_currentIndex][1],
        child: Column(
          children: [
            // Floating Header
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.md,
                ),
                child: _FloatingHeader(
                  title: _titles[_currentIndex],
                  isDark: isDark,
                  onAvatarTap: () => _onTabTapped(4),
                ),
              ),
            ),
            
            // Content Pages
            Expanded(
              child: PageView(
                controller: pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                children: _screens,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
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

class _FloatingHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  final VoidCallback onAvatarTap;

  const _FloatingHeader({
    required this.title,
    required this.isDark,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthService>().currentUser;
    
    Widget buildGlassContainer(Widget child, {EdgeInsetsGeometry? padding}) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 56,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkSurfaceElevated : Colors.white)
                  .withValues(alpha: isDark ? 0.7 : 0.8),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left side: Avatar & Text
        buildGlassContainer(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AvatarWidget(
                imageBase64: user?.profileImageBase64,
                name: user?.fullName ?? '',
                radius: 18,
                onTap: onAvatarTap,
              ),
              const SizedBox(width: AppSpacing.sm),
              AnimatedSwitcher(
                duration: AppSpacing.durationNormal,
                child: Text(
                  title,
                  key: ValueKey(title),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
        const SizedBox(width: AppSpacing.md),
        // Right side: Icons
        buildGlassContainer(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: AnimatedSwitcher(
                  duration: AppSpacing.durationFast,
                  transitionBuilder: (child, animation) => RotationTransition(
                    turns: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    key: ValueKey(isDark),
                    size: 20,
                  ),
                ),
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                onPressed: () => context.read<ThemeProvider>().toggleTheme(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, size: 20),
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, size: 20),
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                onPressed: () => context.read<AuthService>().signOut(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
      ],
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
          height: 60,
          decoration: BoxDecoration(
            color: (isDark ? AppColors.darkSurfaceElevated : Colors.white)
                .withValues(alpha: isDark ? 0.7 : 0.8),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.1),
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
                isSelected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.search_outlined,
                activeIcon: Icons.search_rounded,
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _GlowingNavItem(
                icon: Icons.add_box_outlined,
                activeIcon: Icons.add_box_rounded,
                isSelected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble_rounded,
                isSelected: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person_rounded,
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
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
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
        duration: AppSpacing.durationFast,
        curve: Curves.easeOutCirc,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primary.withValues(alpha: 0.15) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedSwitcher(
          duration: AppSpacing.durationFast,
          child: Icon(
            isSelected ? activeIcon : icon,
            key: ValueKey(isSelected),
            size: 26,
            color: isSelected 
                ? theme.colorScheme.primary 
                : theme.iconTheme.color?.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

class _GlowingNavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GlowingNavItem({
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_GlowingNavItem> createState() => _GlowingNavItemState();
}

class _GlowingNavItemState extends State<_GlowingNavItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(
                alpha: widget.isSelected ? 0.3 : _glowAnimation.value * 0.3,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(
                    alpha: _glowAnimation.value * 0.4,
                  ),
                  blurRadius: 12 * _glowAnimation.value,
                  spreadRadius: 2 * _glowAnimation.value,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                widget.isSelected ? widget.activeIcon : widget.icon,
                size: 30,
                color: widget.isSelected 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.primary.withValues(alpha: 0.8),
              ),
            ),
          );
        },
      ),
    );
  }
}
