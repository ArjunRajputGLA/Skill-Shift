import 'package:flutter/material.dart';

class NotificationService {
  static void _showPopup(BuildContext context, String message, Color color, IconData icon) {
    // Remove any current SnackBar to avoid queuing delays
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 6,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    _showPopup(context, message, Colors.green.shade600, Icons.check_circle_outline);
  }

  static void showError(BuildContext context, String message) {
    _showPopup(context, message, Colors.red.shade600, Icons.error_outline);
  }

  static void showWarning(BuildContext context, String message) {
    _showPopup(context, message, Colors.orange.shade700, Icons.warning_amber_rounded);
  }

  static void showInfo(BuildContext context, String message) {
    _showPopup(context, message, Colors.blue.shade600, Icons.info_outline);
  }

  static void showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents user from dismissing it
      builder: (BuildContext context) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
              ],
            ),
            child: const CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  static void hideLoading(BuildContext context) {
    // Check if we can pop before popping to avoid exceptions
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  static String getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'weak-password':
        return 'Password must contain at least 6 characters.';
      case 'operation-not-allowed':
        return 'This sign-in method is currently disabled.';
      case 'network-request-failed':
        return 'Check your internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'invalid-credential':
        return 'Invalid credentials. Please try again.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}
