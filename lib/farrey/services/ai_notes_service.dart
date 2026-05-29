import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../models/farrey_ai_analysis.dart';

class AiNotesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Retrieves or generates an AI Analysis for a Farrey Note
  Future<FarreyAiAnalysis?> getAnalysis(String noteId, String fileUrl, String fileType) async {
    try {
      // 1. Check if it already exists in Firestore (caching)
      final doc = await _firestore.collection('farrey_ai_analysis').doc(noteId).get();
      if (doc.exists && doc.data() != null) {
        return FarreyAiAnalysis.fromMap(doc.data()!, doc.id);
      }

      // 2. Call secure backend function
      final HttpsCallable callable = _functions.httpsCallable('analyzeFarreyNote');
      final result = await callable.call(<String, dynamic>{
        'noteId': noteId,
        'fileUrl': fileUrl,
        'fileType': fileType,
      });

      if (result.data['success'] == true) {
        final Map<String, dynamic> dataMap = Map<String, dynamic>.from(result.data['data'] as Map);
        return FarreyAiAnalysis.fromMap(dataMap, noteId);
      } else {
        throw Exception(result.data['message'] ?? "Unknown error from backend.");
      }
    } catch (e) {
      debugPrint("Error in getAnalysis: $e");
      rethrow;
    }
  }
}
