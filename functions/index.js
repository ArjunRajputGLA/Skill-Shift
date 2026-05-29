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

// AI Notes Summarizer using Gemini API
const { GoogleGenerativeAI } = require("@google/generative-ai");

exports.analyzeFarreyNote = functions.https.onCall(async (data, context) => {
  // Ensure user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be logged in to analyze notes."
    );
  }

  const { noteId, fileUrl, fileType } = data;
  if (!noteId || !fileUrl || !fileType) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing noteId, fileUrl, or fileType."
    );
  }

  try {
    // 1. Check if analysis already exists to prevent duplicate generation
    const analysisRef = admin.firestore().collection("farrey_ai_analysis").doc(noteId);
    const doc = await analysisRef.get();
    if (doc.exists) {
      return { success: true, message: "Analysis already exists", data: doc.data() };
    }

    // 2. Fetch the file buffer
    const response = await fetch(fileUrl);
    if (!response.ok) {
      throw new Error(`Failed to fetch file: ${response.statusText}`);
    }
    const arrayBuffer = await response.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);

    // 3. Initialize Gemini API
    const GEMINI_API_KEY = "AIzaSyDGj4uN-m8tDuUq0Hg5C1C-IGdEqwCfBaI"; 
    const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
    const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });

    const promptText = `
You are an expert educational AI. Analyze the document and extract key learning material.
Return a valid JSON object with the following exact keys:
{
  "summary": "A 1-2 sentence overview of the document.",
  "importantTopics": ["Topic 1", "Topic 2", "Topic 3"],
  "quickRevision": ["Point 1", "Point 2", "Point 3"],
  "difficulty": "Beginner", // Can be Beginner, Intermediate, or Advanced
  "estimatedStudyTime": "1 hr 30 mins" // Estimate based on the length/complexity of the text
}
`;

    const normalizedType = fileType.toLowerCase().replace('.', '');
    
    let parts = [promptText];

    if (normalizedType === 'docx') {
      const mammoth = require("mammoth");
      const result = await mammoth.extractRawText({ buffer });
      parts.push({ text: `Text to analyze:\n${result.value}` });
    } else {
      let mimeType = 'text/plain';
      if (normalizedType === 'pdf') mimeType = 'application/pdf';
      else if (['jpg', 'jpeg'].includes(normalizedType)) mimeType = 'image/jpeg';
      else if (normalizedType === 'png') mimeType = 'image/png';
      else if (normalizedType === 'webp') mimeType = 'image/webp';
      else if (normalizedType === 'heic') mimeType = 'image/heic';
      
      parts.push({
        inlineData: {
          data: buffer.toString("base64"),
          mimeType: mimeType
        }
      });
    }

    // 4. Call Gemini
    const result = await model.generateContent(parts);
    let responseText = result.response.text();
    
    // Clean up markdown block if present
    if (responseText.startsWith("```json")) {
      responseText = responseText.replace(/```json/g, '').replace(/```/g, '').trim();
    } else if (responseText.startsWith("```")) {
      responseText = responseText.replace(/```/g, '').trim();
    }
    
    // 5. Parse Output
    const parsedData = JSON.parse(responseText);

    const aiData = {
      analysisId: noteId,
      noteId: noteId,
      summary: parsedData.summary || "Summary not available.",
      importantTopics: parsedData.importantTopics || [],
      quickRevision: parsedData.quickRevision || [],
      difficulty: parsedData.difficulty || "Intermediate",
      estimatedStudyTime: parsedData.estimatedStudyTime || "Unknown",
      generatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // 6. Store in Firestore
    await analysisRef.set(aiData);

    return { success: true, data: aiData };

  } catch (error) {
    console.error("AI Analysis Error:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to generate AI analysis. " + error.message
    );
  }
});

// Flashcard & Quiz Generator using Gemini API
exports.generateFarreyStudyMaterial = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "You must be logged in to generate study material.");
  }

  const { noteId, fileUrl, fileType } = data;
  if (!noteId || !fileUrl || !fileType) {
    throw new functions.https.HttpsError("invalid-argument", "Missing noteId, fileUrl, or fileType.");
  }

  try {
    // 1. Check if study material already exists
    const flashcardsSnapshot = await admin.firestore().collection("farrey_flashcards").where("noteId", "==", noteId).limit(1).get();
    if (!flashcardsSnapshot.empty) {
      return { success: true, message: "Study material already exists" };
    }

    // 2. Fetch the file buffer
    const response = await fetch(fileUrl);
    if (!response.ok) {
      throw new Error(`Failed to fetch file: ${response.statusText}`);
    }
    const arrayBuffer = await response.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);

    // 3. Initialize Gemini
    const GEMINI_API_KEY = "AIzaSyDGj4uN-m8tDuUq0Hg5C1C-IGdEqwCfBaI"; 
    const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
    const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });

    const promptText = `
You are an expert educational AI. Analyze the document and generate study material.
Return a valid JSON object strictly matching this format:
{
  "flashcards": [
    {
      "question": "Clear question here?",
      "answer": "Concise answer here.",
      "difficulty": "Easy" // Easy, Medium, or Hard
    }
  ],
  "quizzes": [
    {
      "question": "Multiple choice question?",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correctAnswer": "Option B", // Must EXACTLY match one of the options
      "explanation": "Explanation of why this is correct.",
      "difficulty": "Medium"
    }
  ]
}
Generate at least 5 flashcards and 5 quizzes based on the most important concepts.
`;

    const normalizedType = fileType.toLowerCase().replace('.', '');
    let parts = [promptText];

    if (normalizedType === 'docx') {
      const mammoth = require("mammoth");
      const result = await mammoth.extractRawText({ buffer });
      parts.push({ text: `Text to analyze:\n${result.value}` });
    } else {
      let mimeType = 'text/plain';
      if (normalizedType === 'pdf') mimeType = 'application/pdf';
      else if (['jpg', 'jpeg'].includes(normalizedType)) mimeType = 'image/jpeg';
      else if (normalizedType === 'png') mimeType = 'image/png';
      else if (normalizedType === 'webp') mimeType = 'image/webp';
      else if (normalizedType === 'heic') mimeType = 'image/heic';
      
      parts.push({
        inlineData: {
          data: buffer.toString("base64"),
          mimeType: mimeType
        }
      });
    }

    // 4. Call Gemini
    const result = await model.generateContent(parts);
    let responseText = result.response.text();
    
    if (responseText.startsWith("```json")) {
      responseText = responseText.replace(/```json/g, '').replace(/```/g, '').trim();
    } else if (responseText.startsWith("```")) {
      responseText = responseText.replace(/```/g, '').trim();
    }
    
    // 5. Parse Output
    const parsedData = JSON.parse(responseText);
    const flashcards = parsedData.flashcards || [];
    const quizzes = parsedData.quizzes || [];

    // 6. Write to Firestore in batches
    const db = admin.firestore();
    const batch = db.batch();

    flashcards.forEach(card => {
      const docRef = db.collection("farrey_flashcards").doc();
      batch.set(docRef, {
        flashcardId: docRef.id,
        noteId: noteId,
        question: card.question,
        answer: card.answer,
        difficulty: card.difficulty || "Medium",
        generatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    quizzes.forEach(quiz => {
      const docRef = db.collection("farrey_quizzes").doc();
      batch.set(docRef, {
        quizId: docRef.id,
        noteId: noteId,
        question: quiz.question,
        options: quiz.options || [],
        correctAnswer: quiz.correctAnswer,
        explanation: quiz.explanation || "",
        difficulty: quiz.difficulty || "Medium",
      });
    });

    await batch.commit();

    return { success: true, message: "Successfully generated study material." };

  } catch (error) {
    console.error("AI Study Material Error:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to generate study material. " + error.message
    );
  }
});
