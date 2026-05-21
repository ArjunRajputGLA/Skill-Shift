import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/gradient_background.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../services/notification_service.dart';

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
  void _signup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      NotificationService.showWarning(context, "Please fill all fields");
      return;
    }

    setState(() => _isLoading = true);
    NotificationService.showLoading(context);

    final authService = Provider.of<AuthService>(context, listen: false);
    final error = await authService.signUp(name: name, email: email, password: password);

    if (mounted) {
      NotificationService.hideLoading(context);
      setState(() => _isLoading = false);
      if (error != null) {
        NotificationService.showError(context, error);
      } else {
        NotificationService.showSuccess(context, "Account created successfully");
        Navigator.pop(context);
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
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GradientBackground(
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
