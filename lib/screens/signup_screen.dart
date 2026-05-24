import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/gradient_background.dart';
import '../widgets/video_background.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../services/notification_service.dart';
import '../services/google_auth_service.dart';
import '../widgets/google_sign_in_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: AppSpacing.entranceCurve,
    );
    _fadeController.forward();
  }

  bool _isEmailValid(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isPasswordStrong(String password) {
    // Minimum 8 characters, at least one uppercase, one lowercase, one number and one special character
    return RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$').hasMatch(password);
  }

  // ALL backend logic preserved exactly
  void _signup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      NotificationService.showWarning(context, "Please fill all fields");
      return;
    }

    if (!_isEmailValid(email)) {
      NotificationService.showWarning(context, "Please enter a valid email format");
      return;
    }

    if (!_isPasswordStrong(password)) {
      NotificationService.showWarning(
        context, 
        "Password must be at least 8 chars long and contain an uppercase, lowercase, number, and special character."
      );
      return;
    }

    if (_isLoading) return;
    setState(() => _isLoading = true);
    NotificationService.showLoading(context, message: "Creating your account...");

    final authService = Provider.of<AuthService>(context, listen: false);
    final navigator = Navigator.of(context, rootNavigator: true);
    
    final error = await authService.signUp(
      email: email,
      password: password,
      name: name,
    );
    navigator.pop(); // Close dialog safely

    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null) {
        NotificationService.showError(context, error);
      } else {
        NotificationService.showSuccess(context, "Account created successfully");
        Navigator.pop(context);
      }
    }
  }

  void _signupWithGoogle() async {
    if (_isGoogleLoading) return;
    setState(() => _isGoogleLoading = true);
    NotificationService.showLoading(context, message: "Authenticating with Google...");

    final authService = Provider.of<AuthService>(context, listen: false);
    final navigator = Navigator.of(context, rootNavigator: true);
    final error = await authService.signInWithGoogle();
    navigator.pop(); // Close dialog safely

    if (mounted) {
      setState(() => _isGoogleLoading = false);
      if (error != null) {
        NotificationService.showError(context, error);
      } else {
        NotificationService.showSuccess(context, "Google signup successful");
        Navigator.pop(context); // Optional depending on how nav is handled, but if authState changes it's automatic.
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: VideoBackground(
        accentColor1: AppColors.primary,
        accentColor2: AppColors.accent,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Join your campus talent marketplace',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.huge),
                    CustomTextField(
                      label: 'Full Name',
                      hint: 'e.g., Alex Johnson',
                      controller: _nameController,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    CustomTextField(
                      label: 'College Email',
                      hint: 'you@university.edu',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    CustomTextField(
                      label: 'Password',
                      hint: 'Min. 6 characters',
                      controller: _passwordController,
                      isPassword: true,
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    PrimaryButton(
                      label: 'Sign Up',
                      onPressed: _signup,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: Text(
                            'OR',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    GoogleSignInButton(
                      isLoading: _isGoogleLoading,
                      onPressed: _signupWithGoogle,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
