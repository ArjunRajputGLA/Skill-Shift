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
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
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

  // ALL backend logic preserved exactly
  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      NotificationService.showWarning(context, "Please enter email and password");
      return;
    }

    if (_isLoading) return;
    setState(() => _isLoading = true);
    NotificationService.showLoading(context, message: "Authenticating, please wait...");

    final authService = Provider.of<AuthService>(context, listen: false);
    final navigator = Navigator.of(context, rootNavigator: true);
    final error = await authService.signIn(email: email, password: password);
    navigator.pop(); // Close dialog safely

    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null) {
        NotificationService.showError(context, error);
      } else {
        NotificationService.showSuccess(context, "Login successful");
      }
    }
  }

  void _loginWithGoogle() async {
    if (_isGoogleLoading) return;
    setState(() => _isGoogleLoading = true);
    NotificationService.showLoading(context, message: "Authenticating with Google, please be patient...");

    final authService = Provider.of<AuthService>(context, listen: false);
    final navigator = Navigator.of(context, rootNavigator: true);
    final error = await authService.signInWithGoogle();
    navigator.pop(); // Close dialog safely

    if (mounted) {
      setState(() => _isGoogleLoading = false);
      if (error != null) {
        NotificationService.showError(context, error);
      } else {
        NotificationService.showSuccess(context, "Google login successful");
      }
    }
  }

  void _showForgotPasswordDialog() {
    final theme = Theme.of(context);
    final emailController = TextEditingController(text: _emailController.text);
    bool isResetting = false;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
              title: Text('Reset Password', style: theme.textTheme.titleLarge),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Enter your email address to receive a password reset link.', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.lg),
                  CustomTextField(
                    label: 'Email',
                    hint: 'you@university.edu',
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isResetting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isResetting ? null : () async {
                    final email = emailController.text.trim();
                    if (email.isEmpty) {
                      NotificationService.showWarning(dialogContext, "Please enter your email");
                      return;
                    }
                    setStateDialog(() => isResetting = true);
                    final authService = Provider.of<AuthService>(context, listen: false);
                    final error = await authService.resetPassword(email);
                    
                    setStateDialog(() => isResetting = false);
                    if (error != null) {
                      if (dialogContext.mounted) NotificationService.showError(dialogContext, error);
                    } else {
                      if (dialogContext.mounted) {
                        NotificationService.showSuccess(dialogContext, "Password reset link sent to $email");
                        Navigator.pop(dialogContext);
                      }
                    }
                  },
                  child: isResetting 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Send Link'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
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
      body: VideoBackground(
        accentColor1: AppColors.primary,
        accentColor2: AppColors.primaryLight,
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
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      'Welcome to Skill Shift',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displayMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Sign in to sync your skills and connect.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.huge),
                    CustomTextField(
                      label: 'Email',
                      hint: 'you@university.edu',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    CustomTextField(
                      label: 'Password',
                      hint: 'Enter your password',
                      controller: _passwordController,
                      isPassword: true,
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: 'Log In',
                      onPressed: _login,
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
                      onPressed: _loginWithGoogle,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    SecondaryButton(
                      label: "Don't have an account? Sign Up",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignupScreen()),
                        );
                      },
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
}
