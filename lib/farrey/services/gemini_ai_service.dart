import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class GeminiAiService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<void> generateStudyMaterial(String noteId, List<String> fileUrls, List<String> fileTypes) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('generateFarreyStudyMaterial');
      final result = await callable.call(<String, dynamic>{
        'noteId': noteId,
        'fileUrls': fileUrls,
        'fileTypes': fileTypes,
      });

      if (result.data['success'] != true) {
        throw Exception(result.data['message'] ?? "Unknown error from backend.");
      }
    } catch (e) {
      debugPrint("Error generating study material: $e");
      rethrow;
    }
  }
}
