import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'notification_service.dart';

class WhatsAppService {
  static Future<void> openWhatsApp({
    required String phoneNumber,
    required String userName,
    required String postTitle,
    required BuildContext context,
  }) async {
    try {
      if (phoneNumber.trim().isEmpty) {
        if (context.mounted) {
          NotificationService.showError(context, "No phone number provided.");
        }
        return;
      }

      // Remove any spaces, dashes, or non-numeric characters (except leading '+')
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      if (cleanPhone.isEmpty) {
        if (context.mounted) {
          NotificationService.showError(context, "Invalid phone number format.");
        }
        return;
      }

      // Prefill message
      final message = 'Hi $userName, I saw your post on Skill Shift:\n\n"$postTitle"\n\nand would like to connect.';
      
      // WhatsApp deep link URL
      final Uri appUri = Uri.parse('whatsapp://send?phone=$cleanPhone&text=${Uri.encodeComponent(message)}');
      final Uri webUri = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');

      try {
        // Try native app first
        final launched = await launchUrl(appUri, mode: LaunchMode.externalNonBrowserApplication);
        if (!launched) {
          // Fallback to web link
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {
        try {
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
        } catch (e) {
          if (context.mounted) {
            NotificationService.showError(
              context, 
              "Could not open WhatsApp. Ensure it is installed."
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        NotificationService.showError(
          context, 
          "Failed to launch WhatsApp: ${e.toString()}"
        );
      }
    }
  }
}
