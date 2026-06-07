
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
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

    const promptText = `
You are an expert AI Learning Coach. A user wants to achieve a specific learning goal.
Goal: "${goalTitle}"
Current Level: ${currentLevel}
Available Study Time: ${availableHours}
Target Date/Timeline: ${targetDateStr || 'No specific date'}

Create a structured learning roadmap and daily tasks for this user.
Return the result strictly as a valid JSON object matching the following structure:
{
  "phases": [
    {
      "title": "Phase 1 Title",
      "description": "What to focus on",
      "estimatedHours": "10 hours",
      "tasks": [
        {
          "title": "Read Chapter 1",
          "estimatedTime": "1 hour",
          "type": "read"
        }
      ]
    }
  ]
}
Generate 3 to 6 phases in the roadmap. For EACH phase, generate 3 to 5 daily tasks. The task type can be "read", "practice", "quiz", "flashcard", or "video".
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

    // Create roadmap phases and nested tasks
    const batch = db.batch();
    
    // Base date for tasks
    const baseDate = new Date();
    baseDate.setHours(0, 0, 0, 0);
    let daysAdded = 0;

    if (parsedData.phases && Array.isArray(parsedData.phases)) {
      parsedData.phases.forEach((phase, index) => {
        const phaseRef = db.collection("navigator_roadmap").doc();
        batch.set(phaseRef, {
          roadmapId: phaseRef.id,
          navigatorId: navigatorId,
          title: phase.title || \`Phase \${index + 1}\`,
          description: phase.description || "",
          order: index,
          completed: false,
          estimatedHours: phase.estimatedHours || "Unknown",
        });

        if (phase.tasks && Array.isArray(phase.tasks)) {
          phase.tasks.forEach((task) => {
            const taskRef = db.collection("navigator_tasks").doc();
            
            const taskDate = new Date(baseDate);
            taskDate.setDate(taskDate.getDate() + daysAdded);

            batch.set(taskRef, {
              taskId: taskRef.id,
              navigatorId: navigatorId,
              roadmapId: phaseRef.id,
              title: task.title || "Daily Task",
              date: taskDate,
              completed: false,
              estimatedTime: task.estimatedTime || "30 mins",
              type: task.type || "practice",
            });
          });
          daysAdded++; // Increment date for next phase (rough estimation of progression)
        }
      });
    }

    await batch.commit();

    return { success: true, navigatorId: navigatorId };

  } catch (error) {
    console.error("Navigator Plan Generation Error:", error);
    throw new functions.https.HttpsError("internal", "Failed to generate navigator plan. " + error.message);
  }
});
