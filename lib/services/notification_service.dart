import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  // ---------------------------------------------------------------------------
  // 1. IN-APP NOTIFICATION DATABASE LOGIC
  // ---------------------------------------------------------------------------
  
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Creates a two-layer notification: 
  /// 1. Saves to Firestore (powers the in-app Bell icon)
  /// 2. Triggers Firebase Cloud Function for real Push Notification
  static Future<void> createNotification({
    required String receiverUid,
    required String type,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    final user = _auth.currentUser;
    // Don't send notifications to yourself
    if (user != null && user.uid == receiverUid) return;

    final docRef = _firestore.collection('notifications').doc();
    
    await docRef.set({
      'notificationId': docRef.id,
      'receiverUid': receiverUid,
      'senderUid': user?.uid ?? 'system',
      'title': title,
      'body': body,
      'type': type, // 'message', 'session', 'endorsement', 'recommendation', 'system'
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
      'payload': payload,
    });
  }

  /// Stream to get the unread count for the Bell badge
  static Stream<int> getUnreadCountStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('receiverUid', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Stream to fetch notifications (Grouped in UI)
  static Stream<QuerySnapshot> getNotificationsStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('notifications')
        .where('receiverUid', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .limit(50) // Pagination/limit for performance
        .snapshots();
  }

  static Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  static Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('notifications')
        .where('receiverUid', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  static Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  static Future<void> deleteAllNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('notifications')
        .where('receiverUid', isEqualTo: user.uid)
        .get();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }


  // ---------------------------------------------------------------------------
  // 2. UI POPUP LOGIC (Existing)
  // ---------------------------------------------------------------------------

  static void _showPopup(BuildContext context, String message, Color color, IconData icon) {
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
      barrierDismissible: false,
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
