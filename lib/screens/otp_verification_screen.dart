import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/phone_auth_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/otp_input_widget.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final int? resendToken;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.resendToken,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final PhoneAuthService _phoneAuthService = PhoneAuthService();
  bool _isLoading = false;
  String _otpCode = '';
  
  late String _currentVerificationId;
  int? _currentResendToken;

  int _resendCountdown = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _currentResendToken = widget.resendToken;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _resendCountdown = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        _timer?.cancel();
      }
    });
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
    });

    await _phoneAuthService.sendOtp(
      phoneNumber: widget.phoneNumber,
      forceResendingToken: _currentResendToken,
      codeSent: (verificationId, resendToken) {
        setState(() {
          _currentVerificationId = verificationId;
          _currentResendToken = resendToken;
          _isLoading = false;
        });
        _startTimer();
        if (mounted) {
          NotificationService.showSuccess(context, 'OTP resent successfully');
        }
      },
      verificationFailed: (error) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          NotificationService.showError(context, error.message ?? 'Failed to resend OTP');
        }
      },
      verificationCompleted: (credential) {
        // Auto-resolution (mostly Android) - handled elsewhere or just log
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _currentVerificationId = verificationId;
      },
    );
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) {
      NotificationService.showError(context, 'Please enter a valid 6-digit OTP');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    bool success = await _phoneAuthService.verifyOtp(
      verificationId: _currentVerificationId,
      smsCode: _otpCode,
    );

    if (success) {
      final authService = context.read<AuthService>();
      final currentUser = authService.currentUser;
      
      if (currentUser != null) {
        // Update user model to reflect verification
        final updatedUser = currentUser.toMap();
        updatedUser['whatsapp'] = widget.phoneNumber;
        updatedUser['whatsappVerified'] = true;
        updatedUser['verifiedAt'] = DateTime.now();

        // Update in auth service and Firestore
        final error = await authService.updateProfile(
          currentUser.copyWith(
            whatsapp: widget.phoneNumber,
            whatsappVerified: true,
            verifiedAt: DateTime.now(),
          ) // Need to add copyWith to UserModel or just rebuild it
        );

        if (error == null && mounted) {
           NotificationService.showSuccess(context, 'WhatsApp number verified!');
           Navigator.pop(context, true); // Return true to indicate success
        } else if (mounted) {
           NotificationService.showError(context, error ?? 'Failed to update profile');
        }
      }
    } else {
      if (mounted) {
        NotificationService.showError(context, 'Invalid OTP or verification failed.');
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Verify Number'),
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              Icon(
                Icons.mark_email_read_rounded,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Enter Verification Code',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'We have sent a 6-digit OTP to\n${widget.phoneNumber}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              GlassCard(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xl,
                  horizontal: AppSpacing.lg,
                ),
                child: Column(
                  children: [
                    OtpInputWidget(
                      length: 6,
                      onChanged: (val) {
                        _otpCode = val;
                      },
                      onCompleted: (val) {
                        _otpCode = val;
                        _verifyOtp();
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    CustomButton(
                      label: 'Verify OTP',
                      isLoading: _isLoading,
                      onPressed: _verifyOtp,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextButton(
                onPressed: _canResend && !_isLoading ? _resendOtp : null,
                child: Text(
                  _canResend 
                    ? 'Resend OTP' 
                    : 'Resend OTP in $_resendCountdown s',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _canResend ? theme.colorScheme.primary : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
