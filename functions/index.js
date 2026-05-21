const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// Trigger on new message creation
exports.onNewMessage = functions.firestore
  .document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const newValue = snap.data();
    const senderId = newValue.senderId;
    const senderName = newValue.senderName || "Someone";
    const chatId = context.params.chatId;

    // Get chat participants
    const chatDoc = await admin.firestore().collection("chats").doc(chatId).get();
    if (!chatDoc.exists) return null;
    
    const participants = chatDoc.data().participants || [];
    // Find recipient (the other participant)
    const recipientId = participants.find((id) => id !== senderId);
    if (!recipientId) return null;

    // Get recipient's FCM token
    const userDoc = await admin.firestore().collection("users").doc(recipientId).get();
    if (!userDoc.exists) return null;

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) {
      console.log(`User ${recipientId} does not have an FCM token.`);
      return null;
    }

    // Determine notification title and body
    let title = `${senderName} sent you a message`;
    let body = newValue.text || "";
    
    if (newValue.replyTo) {
      title = `${senderName} replied to your message`;
    }
    
    if (body.length === 0) {
      if (newValue.mediaType === "image") body = "📷 Photo";
      else if (newValue.mediaType === "audio") body = "🎵 Voice note";
      else body = "New message";
    }

    const payload = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: "message",
        chatId: chatId,
        click_action: "FLUTTER_NOTIFICATION_CLICK"
      }
    };

    try {
      await admin.messaging().sendToDevice(fcmToken, payload);
      console.log("Successfully sent message notification to", recipientId);
    } catch (error) {
      console.error("Error sending message notification:", error);
    }
    return null;
  });

// Trigger on message reaction (update)
exports.onMessageReaction = functions.firestore
  .document("chats/{chatId}/messages/{messageId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const chatId = context.params.chatId;

    // Check if reactions changed
    const beforeReactions = before.reactions || {};
    const afterReactions = after.reactions || {};
    
    // We only want to notify if a NEW reaction was added
    let newReactorId = null;
    let newEmoji = null;

    for (const [emoji, users] of Object.entries(afterReactions)) {
      const oldUsers = beforeReactions[emoji] || [];
      const newUsers = users.filter(u => !oldUsers.includes(u));
      if (newUsers.length > 0) {
        newReactorId = newUsers[0]; // Just take the first one
        newEmoji = emoji;
        break;
      }
    }

    if (!newReactorId) return null; // No new reaction added

    // Don't notify if the user reacted to their own message
    const messageOwnerId = after.senderId;
    if (newReactorId === messageOwnerId) return null;

    // Get the reactor's name
    const reactorDoc = await admin.firestore().collection("users").doc(newReactorId).get();
    const reactorName = reactorDoc.exists ? reactorDoc.data().fullName : "Someone";

    // Get the recipient's (message owner) FCM token
    const ownerDoc = await admin.firestore().collection("users").doc(messageOwnerId).get();
    if (!ownerDoc.exists) return null;

    const fcmToken = ownerDoc.data().fcmToken;
    if (!fcmToken) return null;

    const payload = {
      notification: {
        title: `${reactorName} reacted ${newEmoji} to your message`,
        body: after.text ? `"${after.text}"` : "Media message",
      },
      data: {
        type: "reaction",
        chatId: chatId,
        click_action: "FLUTTER_NOTIFICATION_CLICK"
      }
    };

    try {
      await admin.messaging().sendToDevice(fcmToken, payload);
      console.log("Successfully sent reaction notification to", messageOwnerId);
    } catch (error) {
      console.error("Error sending reaction notification:", error);
    }
    return null;
  });

// Trigger on connection request
exports.onConnectionRequest = functions.firestore
  .document("connection_requests/{requestId}")
  .onCreate(async (snap, context) => {
    const request = snap.data();
    const senderId = request.senderId;
    const recipientId = request.recipientId;

    if (!senderId || !recipientId) return null;

    // Get sender's name
    const senderDoc = await admin.firestore().collection("users").doc(senderId).get();
    const senderName = senderDoc.exists ? senderDoc.data().fullName : "Someone";

    // Get recipient's FCM token
    const recipientDoc = await admin.firestore().collection("users").doc(recipientId).get();
    if (!recipientDoc.exists) return null;

    const fcmToken = recipientDoc.data().fcmToken;
    if (!fcmToken) return null;

    const payload = {
      notification: {
        title: "New Connection Request",
        body: `${senderName} wants to connect with you`,
      },
      data: {
        type: "connection_request",
        senderId: senderId,
        click_action: "FLUTTER_NOTIFICATION_CLICK"
      }
    };

    try {
      await admin.messaging().sendToDevice(fcmToken, payload);
      console.log("Successfully sent connection request notification to", recipientId);
    } catch (error) {
      console.error("Error sending connection request notification:", error);
    }
    return null;
  });
