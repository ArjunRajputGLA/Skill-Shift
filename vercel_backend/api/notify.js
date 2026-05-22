const admin = require("firebase-admin");

// Initialize Firebase Admin lazily to avoid re-initialization errors in serverless environments
if (!admin.apps.length) {
  try {
    // We expect FIREBASE_SERVICE_ACCOUNT_KEY to be a stringified JSON object in Vercel Env Vars
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  } catch (error) {
    console.error("Firebase Admin Initialization Error:", error);
  }
}

export default async function handler(req, res) {
  // Only allow POST requests
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  try {
    const { recipientId, title, body, data } = req.body;

    if (!recipientId) {
      return res.status(400).json({ error: 'Missing recipientId' });
    }

    // 1. Fetch recipient's FCM token from Firestore
    const userDoc = await admin.firestore().collection('users').doc(recipientId).get();
    
    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    const userData = userDoc.data();
    if (userData.notificationsEnabled === false) {
      return res.status(200).json({ success: true, message: 'Notifications are disabled for this user' });
    }

    const fcmToken = userData.fcmToken;
    if (!fcmToken) {
      return res.status(400).json({ error: 'User does not have an FCM token' });
    }

    // 2. Construct the FCM message
    const message = {
      notification: {
        title: title || 'New Notification',
        body: body || '',
      },
      data: {
        ...data,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      token: fcmToken
    };

    // 3. Send the notification using the modern HTTP v1 API
    const response = await admin.messaging().send(message);
    
    return res.status(200).json({ 
      success: true, 
      message: 'Notification sent successfully',
      response: response 
    });

  } catch (error) {
    console.error("Error sending notification:", error);
    return res.status(500).json({ error: 'Internal Server Error', details: error.message });
  }
}
