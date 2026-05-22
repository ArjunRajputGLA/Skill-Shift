const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// Single unified trigger for all push notifications in the app.
// Listens to the `notifications` collection which powers the in-app Bell icon.
exports.onNotificationCreated = functions.firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    if (!notification) return null;

    const receiverUid = notification.receiverUid;
    const title = notification.title;
    const body = notification.body;
    const type = notification.type;
    const payloadData = notification.payload || {};

    if (!receiverUid) return null;

    // Get recipient's FCM token
    const userDoc = await admin.firestore().collection("users").doc(receiverUid).get();
    if (!userDoc.exists) {
      console.log(`User ${receiverUid} not found.`);
      return null;
    }

    const userData = userDoc.data();
    // Check if the user has push notifications enabled in settings
    if (userData.notificationsEnabled === false) {
      console.log(`User ${receiverUid} has notifications disabled.`);
      return null;
    }

    const fcmToken = userData.fcmToken;
    if (!fcmToken) {
      console.log(`User ${receiverUid} does not have an FCM token.`);
      return null;
    }

    // Construct FCM payload using modern HTTP v1 API structure
    const message = {
      token: fcmToken,
      notification: {
        title: title || '',
        body: body || '',
      },
      data: {
        type: String(type || 'system'),
        notificationId: String(context.params.notificationId || ''),
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      }
    };

    // Safely inject custom payload data ensuring all values are strings (required by FCM data payload)
    if (payloadData) {
      for (const [key, value] of Object.entries(payloadData)) {
        message.data[key] = String(value);
      }
    }

    // Send FCM Push Notification
    try {
      await admin.messaging().send(message);
      console.log(`Successfully sent ${type} push notification to ${receiverUid}`);
    } catch (error) {
      console.error(`Error sending ${type} push notification:`, error);
    }
    
    return null;
  });
