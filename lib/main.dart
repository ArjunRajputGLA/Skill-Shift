import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firebase_notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_layout.dart';
import 'screens/profile_setup_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Push Notifications
  await FirebaseNotificationService().initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const SkillShiftApp(),
    ),
  );
}

class SkillShiftApp extends StatelessWidget {
  const SkillShiftApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    
    return MaterialApp(
      title: 'Skill Shift',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      navigatorKey: rootNavigatorKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const AuthWrapper(),
    );
  }
}

/// A wrapper widget that listens to the authentication state.
/// If a user is logged in, it shows the HomeScreen.
/// If not, it shows the LoginScreen.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to changes in the AuthService
    final authService = context.watch<AuthService>();

    // Show a loading spinner while checking auth state on app startup
    if (authService.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // Better logic for checking Firebase state directly from Provider
    if (authService.currentUser != null) {
      if (authService.currentUser!.profileCompleted) {
        return const MainLayout();
      } else {
        return ProfileSetupScreen();
      }
    } else {
      return const LoginScreen();
    }
  }
}
