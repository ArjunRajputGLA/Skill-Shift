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

  const { noteId, fileUrls, fileTypes } = data;
  if (!noteId || !fileUrls || !fileTypes || !Array.isArray(fileUrls) || !Array.isArray(fileTypes)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing noteId, fileUrls, or fileTypes array."
    );
  }

  try {
    // 1. Check if analysis already exists to prevent duplicate generation
    const analysisRef = admin.firestore().collection("farrey_ai_analysis").doc(noteId);
    const doc = await analysisRef.get();
    if (doc.exists) {
      return { success: true, message: "Analysis already exists", data: doc.data() };
    }

    // 3. Initialize Gemini API
    const GEMINI_API_KEY = process.env.GEMINI_API_KEY; 
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
    
    let parts = [promptText];
    const maxFiles = Math.min(3, fileUrls.length);

    for (let i = 0; i < maxFiles; i++) {
      try {
        const url = fileUrls[i];
        const type = fileTypes.length > i ? fileTypes[i] : 'txt';
        const normalizedType = type.toLowerCase().replace('.', '');
        
        const response = await fetch(url);
        if (!response.ok) {
          console.warn(`Failed to fetch file ${i+1}: ${response.statusText}`);
          continue;
        }
        const arrayBuffer = await response.arrayBuffer();
        const buffer = Buffer.from(arrayBuffer);

        if (normalizedType === 'docx') {
          const mammoth = require("mammoth");
          const result = await mammoth.extractRawText({ buffer });
          parts.push({ text: `Text from document ${i+1}:\n${result.value}` });
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
      } catch (err) {
        console.warn(`Error processing file ${i+1}:`, err);
      }
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

  const { noteId, fileUrls, fileTypes } = data;
  if (!noteId || !fileUrls || !fileTypes || !Array.isArray(fileUrls) || !Array.isArray(fileTypes)) {
    throw new functions.https.HttpsError("invalid-argument", "Missing noteId, fileUrls, or fileTypes array.");
  }

  try {
    // 1. Check if study material already exists
    const flashcardsSnapshot = await admin.firestore().collection("farrey_flashcards").where("noteId", "==", noteId).limit(1).get();
    if (!flashcardsSnapshot.empty) {
      return { success: true, message: "Study material already exists" };
    }

    // 3. Initialize Gemini
    const GEMINI_API_KEY = process.env.GEMINI_API_KEY; 
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

    let parts = [promptText];
    const maxFiles = Math.min(3, fileUrls.length);

    for (let i = 0; i < maxFiles; i++) {
      try {
        const url = fileUrls[i];
        const type = fileTypes.length > i ? fileTypes[i] : 'txt';
        const normalizedType = type.toLowerCase().replace('.', '');
        
        const response = await fetch(url);
        if (!response.ok) {
          console.warn(`Failed to fetch file ${i+1}: ${response.statusText}`);
          continue;
        }
        const arrayBuffer = await response.arrayBuffer();
        const buffer = Buffer.from(arrayBuffer);

        if (normalizedType === 'docx') {
          const mammoth = require("mammoth");
          const result = await mammoth.extractRawText({ buffer });
          parts.push({ text: `Text from document ${i+1}:\n${result.value}` });
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
      } catch (err) {
        console.warn(`Error processing file ${i+1}:`, err);
      }
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

// AI Context-Aware Doubt Solver using Gemini API
exports.solveFarreyDoubt = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "You must be logged in.");
  }

  const { noteId, fileUrls, fileTypes, userQuery, chatHistory } = data;
  if (!noteId || !userQuery) {
    throw new functions.https.HttpsError("invalid-argument", "Missing noteId or query.");
  }

  try {
    const GEMINI_API_KEY = process.env.GEMINI_API_KEY; 
    const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
    const model = genAI.getGenerativeModel({ 
      model: "gemini-2.5-flash",
      systemInstruction: "You are an expert educational tutor. You have been provided with document context from the user's notes. Use this context to inform your answers whenever possible. If the answer is not fully covered in the documents, use your vast general knowledge to provide a precise, helpful, and comprehensive answer, just like a top-tier AI assistant. Always be precise and directly answer the user's questions. Format your response beautifully using Markdown, utilizing bold, italics, lists, and code blocks where appropriate."
    });

    let documentParts = [];
    if (fileUrls && Array.isArray(fileUrls) && fileTypes && Array.isArray(fileTypes)) {
      const maxFiles = Math.min(3, fileUrls.length);
      for (let i = 0; i < maxFiles; i++) {
        try {
          const url = fileUrls[i];
          const type = fileTypes.length > i ? fileTypes[i] : 'txt';
          const normalizedType = type.toLowerCase().replace('.', '');
          
          const response = await fetch(url);
          if (!response.ok) continue;
          
          const arrayBuffer = await response.arrayBuffer();
          const buffer = Buffer.from(arrayBuffer);

          if (normalizedType === 'docx') {
            const mammoth = require("mammoth");
            const result = await mammoth.extractRawText({ buffer });
            documentParts.push({ text: `Document ${i+1}:\n${result.value}` });
          } else {
            let mimeType = 'text/plain';
            if (normalizedType === 'pdf') mimeType = 'application/pdf';
            else if (['jpg', 'jpeg'].includes(normalizedType)) mimeType = 'image/jpeg';
            else if (normalizedType === 'png') mimeType = 'image/png';
            else if (normalizedType === 'webp') mimeType = 'image/webp';
            else if (normalizedType === 'heic') mimeType = 'image/heic';
            
            documentParts.push({
              inlineData: {
                data: buffer.toString("base64"),
                mimeType: mimeType
              }
            });
          }
        } catch (err) {
          console.warn(`Error processing file ${i+1}:`, err);
        }
      }
    }

    let contents = [];
    
    // Add existing chat history and combine consecutive roles to avoid Gemini API errors
    if (chatHistory && Array.isArray(chatHistory)) {
      chatHistory.forEach(msg => {
        if (msg.role && msg.text) {
          const role = msg.role === 'ai' || msg.role === 'model' ? 'model' : 'user';
          if (contents.length > 0 && contents[contents.length - 1].role === role) {
             // Combine with previous message of the same role
             contents[contents.length - 1].parts.push({ text: "\n" + msg.text });
          } else {
             contents.push({
               role: role,
               parts: [{ text: msg.text }]
             });
          }
        }
      });
    }

    // The chatHistory from Dart already includes the latest user query at the end.
    // To avoid consecutive "user" roles, we inject the documents into the last message.
    if (contents.length > 0 && contents[contents.length - 1].role === 'user') {
      contents[contents.length - 1].parts = [ ...documentParts, ...contents[contents.length - 1].parts ];
    } else {
      contents.push({
        role: 'user',
        parts: [ ...documentParts, { text: `User Question: ${userQuery}` } ]
      });
    }

    const result = await model.generateContent({ contents });
    const responseText = result.response.text();

    return { success: true, text: responseText };

  } catch (error) {
    console.error("AI Doubt Solver Error:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to solve doubt. " + error.message
    );
  }
});

// AI Content Moderation for Notes
exports.moderateFarreyNote = functions.firestore
  .document("farrey_notes/{noteId}")
  .onCreate(async (snap, context) => {
    const note = snap.data();
    if (!note) return null;

    const title = note.title || '';
    const description = note.description || '';
    const fileUrls = note.fileUrls || [];
    const fileTypes = note.fileTypes || [];
    
    // We only need a lightweight check. Reading 1 file is usually enough.
    let documentParts = [];
    documentParts.push({ text: `Title: ${title}\nDescription: ${description}` });

    try {
      if (fileUrls.length > 0) {
        const url = fileUrls[0];
        const type = fileTypes.length > 0 ? fileTypes[0] : 'txt';
        const normalizedType = type.toLowerCase().replace('.', '');
        
        const response = await fetch(url);
        if (response.ok) {
          const arrayBuffer = await response.arrayBuffer();
          const buffer = Buffer.from(arrayBuffer);

          if (normalizedType === 'docx') {
            const mammoth = require("mammoth");
            const result = await mammoth.extractRawText({ buffer });
            documentParts.push({ text: `Document Start:\n${result.value.substring(0, 5000)}` });
          } else {
            let mimeType = 'text/plain';
            if (normalizedType === 'pdf') mimeType = 'application/pdf';
            else if (['jpg', 'jpeg'].includes(normalizedType)) mimeType = 'image/jpeg';
            else if (normalizedType === 'png') mimeType = 'image/png';
            else if (normalizedType === 'webp') mimeType = 'image/webp';
            else if (normalizedType === 'heic') mimeType = 'image/heic';
            
            documentParts.push({
              inlineData: {
                data: buffer.toString("base64"),
                mimeType: mimeType
              }
            });
          }
        }
      }

      const GEMINI_API_KEY = process.env.GEMINI_API_KEY; 
      const { GoogleGenerativeAI } = require("@google/generative-ai");
      const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
      
      const model = genAI.getGenerativeModel({ 
        model: "gemini-2.5-flash",
        systemInstruction: "You are an automated content moderator for an educational platform. You must determine if the provided note/document is appropriate. Reject it ONLY IF it contains explicit NSFW content, extreme toxicity, or is blatantly 100% spam/memes with zero educational value. Respond with EXACTLY ONE WORD: either 'APPROVE' or 'REJECT'."
      });

      const result = await model.generateContent({
        contents: [{ role: 'user', parts: documentParts }]
      });
      
      const aiResponse = result.response.text().trim().toUpperCase();
      console.log(`Moderation result for note ${context.params.noteId}: ${aiResponse}`);

      if (aiResponse.includes('REJECT')) {
        await snap.ref.update({ moderationStatus: 'rejected' });
      } else {
        await snap.ref.update({ moderationStatus: 'approved' });
      }

    } catch (error) {
      console.error("Moderation Error:", error);
      // In case of error, default to approved to not block users, or leave it pending.
      // We will set to approved for now.
      await snap.ref.update({ moderationStatus: 'approved' });
    }
});

// Farrey Navigator AI Plan Generator
exports.generateFarreyNavigatorPlan = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "You must be logged in to generate a navigator plan.");
  }

  const { goalTitle, currentLevel, availableHours, targetDateStr } = data;
  if (!goalTitle || !currentLevel || !availableHours) {
    throw new functions.https.HttpsError("invalid-argument", "Missing required fields.");
  }

  try {
    const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
    const { GoogleGenerativeAI } = require("@google/generative-ai");
    const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
    const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });

    const promptText = `
You are an expert AI Learning Coach. A user wants to achieve a specific learning goal.
Goal: "${goalTitle}"
Current Level: ${currentLevel}
Available Study Time: ${availableHours}
Target Date/Timeline: ${targetDateStr || 'No specific date'}

Create a structured learning roadmap and an initial set of daily tasks for this user.
Return the result strictly as a valid JSON object matching the following structure:
{
  "phases": [
    {
      "title": "Phase 1 Title",
      "description": "What to focus on",
      "estimatedHours": "10 hours"
    }
  ],
  "initialDailyTasks": [
    {
      "title": "Read Chapter 1",
      "estimatedTime": "1 hour",
      "type": "read"
    }
  ]
}
Generate 3 to 6 phases in the roadmap, and 3 to 5 initial daily tasks for their very first day. The task type can be "read", "practice", "quiz", "flashcard", or "video".
Do not include any markdown formatting like \`\`\`json outside the JSON object. Just return the raw JSON text.
`;

    const result = await model.generateContent(promptText);
    let responseText = result.response.text();

    if (responseText.startsWith("```json")) {
      responseText = responseText.replace(/```json/g, '').replace(/```/g, '').trim();
    } else if (responseText.startsWith("```")) {
      responseText = responseText.replace(/```/g, '').trim();
    }

    const parsedData = JSON.parse(responseText);

    const uid = context.auth.uid;
    const db = admin.firestore();
    
    // Create new navigator document
    const navigatorRef = db.collection("farrey_navigator").doc();
    const navigatorId = navigatorRef.id;

    await navigatorRef.set({
      navigatorId: navigatorId,
      uid: uid,
      goalTitle: goalTitle,
      currentLevel: currentLevel,
      availableHours: availableHours,
      targetDate: targetDateStr ? new Date(targetDateStr) : null,
      progress: 0.0,
      status: "active",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      streakDays: 0,
    });

    // Create roadmap phases
    const batch = db.batch();
    
    if (parsedData.phases && Array.isArray(parsedData.phases)) {
      parsedData.phases.forEach((phase, index) => {
        const phaseRef = db.collection("navigator_roadmap").doc();
        batch.set(phaseRef, {
          roadmapId: phaseRef.id,
          navigatorId: navigatorId,
          title: phase.title || `Phase ${index + 1}`,
          description: phase.description || "",
          order: index,
          completed: false,
          estimatedHours: phase.estimatedHours || "Unknown",
        });
      });
    }

    // Create initial tasks
    if (parsedData.initialDailyTasks && Array.isArray(parsedData.initialDailyTasks)) {
      // Use current start of day for tasks
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      parsedData.initialDailyTasks.forEach((task) => {
        const taskRef = db.collection("navigator_tasks").doc();
        batch.set(taskRef, {
          taskId: taskRef.id,
          navigatorId: navigatorId,
          roadmapId: "general", // Can be updated later
          title: task.title || "Daily Task",
          date: today,
          completed: false,
          estimatedTime: task.estimatedTime || "30 mins",
          type: task.type || "practice",
        });
      });
    }

    await batch.commit();

    return { success: true, navigatorId: navigatorId };

  } catch (error) {
    console.error("Navigator Plan Generation Error:", error);
    throw new functions.https.HttpsError("internal", "Failed to generate navigator plan. " + error.message);
  }
});
