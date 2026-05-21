import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_shift/main.dart';
import 'package:skill_shift/services/notification_service.dart';
import 'package:skill_shift/screens/chat_detail_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `Firebase.initializeApp()` before using other Firebase services.
  print("Handling a background message: ${message.messageId}");
}

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance = FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permissions
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      print('User declined or has not accepted notification permissions');
      return;
    }

    // Initialize local notifications for foreground display
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
    );

    // Setup background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // Handle background taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationMessage(message);
    });

    // Save initial token
    await _saveDeviceToken();

    // Listen for token refreshes
    _fcm.onTokenRefresh.listen((token) {
      _updateTokenInFirestore(token);
    });

    _isInitialized = true;
  }

  Future<void> _saveDeviceToken() async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _updateTokenInFirestore(token);
      }
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  Future<void> _updateTokenInFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'fcmToken': token,
        });
      } catch (e) {
        // If document doesn't exist or other error, try set with merge
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
      }
    }
  }

  Future<void> clearToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'fcmToken': FieldValue.delete(),
      });
    }
    await _fcm.deleteToken();
  }

  void _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      // Check if the app is currently in foreground with an active context
      final context = rootNavigatorKey.currentContext;
      if (context != null) {
        // Do nothing in foreground, the chat UI will update natively via streams
        print('Foreground message received, skipping popup.');
      } else {
        // Fallback to system tray if context is unavailable
        const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
          'high_importance_channel', // id
          'High Importance Notifications', // name
          channelDescription: 'This channel is used for important notifications.', // description
          importance: Importance.max,
          priority: Priority.high,
        );
        
        const NotificationDetails details = NotificationDetails(android: androidDetails);
        
        await _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: details,
          payload: jsonEncode(message.data),
        );
      }
    }
  }

  void _handleNotificationMessage(RemoteMessage message) {
    _handleNotificationTap(jsonEncode(message.data));
  }

  void _handleNotificationTap(String? payload) {
    if (payload != null) {
      try {
        final data = jsonDecode(payload);
        final context = rootNavigatorKey.currentContext;
        
        if (context == null) return;

        if (data['type'] == 'message' || data['type'] == 'reaction') {
           final chatId = data['chatId'];
           if (chatId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailScreen(
                    chatId: chatId,
                    targetUserId: 'Unknown', // Ideally fetched from DB
                    targetUserName: 'Chat',
                  ),
                ),
              );
           }
        } else if (data['type'] == 'connection_request') {
           // Navigate to connections or explore
           // Navigator.push(context, ...);
        }
      } catch (e) {
        print('Error decoding payload: $e');
      }
    }
  }

  // Handle tap from completely closed app
  Future<void> checkInitialMessage() async {
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationMessage(initialMessage);
    }
  }

  /// Sends a push notification by triggering the Vercel Serverless Function
  Future<void> sendNotificationTrigger({
    required String recipientId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    const String vercelApiUrl = 'https://skill-shift-notifications.vercel.app/api/notify';

    try {
      final response = await http.post(
        Uri.parse(vercelApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'recipientId': recipientId,
          'title': title,
          'body': body,
          'data': data ?? {},
        }),
      );

      if (response.statusCode == 200) {
        print('Successfully triggered push notification via Vercel');
      } else {
        print('Failed to trigger notification: ${response.body}');
      }
    } catch (e) {
      print('Error triggering Vercel API: $e');
    }
  }
}
