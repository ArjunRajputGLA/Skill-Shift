import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/ai_doubt_chat.dart';

class DoubtSolverService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Retrieves an existing chat session for a specific note, or returns null.
  Future<AiDoubtChat?> getChatSession(String noteId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final snapshot = await _firestore
          .collection('farrey_ai_chats')
          .where('noteId', isEqualTo: noteId)
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return AiDoubtChat.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching chat session: $e");
      return null;
    }
  }

  /// Sends a message and receives AI response
  Future<String> askAiDoubt({
    required String noteId,
    required List<String> fileUrls,
    required List<String> fileTypes,
    required String userQuery,
    required List<AiDoubtMessage> chatHistory,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('solveFarreyDoubt');
      
      final historyFormatted = chatHistory.map((msg) => {
        'role': msg.sender == 'ai' ? 'model' : 'user',
        'text': msg.text,
      }).toList();

      final result = await callable.call(<String, dynamic>{
        'noteId': noteId,
        'fileUrls': fileUrls,
        'fileTypes': fileTypes,
        'userQuery': userQuery,
        'chatHistory': historyFormatted,
      });

      if (result.data['success'] == true) {
        return result.data['text'] ?? "No response received.";
      } else {
        throw Exception(result.data['message'] ?? "Unknown error from backend.");
      }
    } catch (e) {
      debugPrint("Error asking AI Doubt: $e");
      rethrow;
    }
  }

  /// Saves the complete chat session to Firestore
  Future<void> saveChatSession(AiDoubtChat chat) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final chatRef = _firestore.collection('farrey_ai_chats').doc(chat.chatId);
      await chatRef.set(chat.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error saving chat session: $e");
    }
  }
}
