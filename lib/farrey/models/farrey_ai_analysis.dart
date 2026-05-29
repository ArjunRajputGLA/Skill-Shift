import 'package:cloud_firestore/cloud_firestore.dart';

class FarreyAiAnalysis {
  final String analysisId;
  final String noteId;
  final String summary;
  final List<String> importantTopics;
  final List<String> quickRevision;
  final String difficulty;
  final String estimatedStudyTime;
  final DateTime? generatedAt;

  FarreyAiAnalysis({
    required this.analysisId,
    required this.noteId,
    required this.summary,
    required this.importantTopics,
    required this.quickRevision,
    required this.difficulty,
    required this.estimatedStudyTime,
    this.generatedAt,
  });

  factory FarreyAiAnalysis.fromMap(Map<String, dynamic> map, String docId) {
    return FarreyAiAnalysis(
      analysisId: map['analysisId'] ?? docId,
      noteId: map['noteId'] ?? '',
      summary: map['summary'] ?? '',
      importantTopics: List<String>.from(map['importantTopics'] ?? []),
      quickRevision: List<String>.from(map['quickRevision'] ?? []),
      difficulty: map['difficulty'] ?? 'Unknown',
      estimatedStudyTime: map['estimatedStudyTime'] ?? 'Unknown',
      generatedAt: map['generatedAt'] != null 
          ? (map['generatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'analysisId': analysisId,
      'noteId': noteId,
      'summary': summary,
      'importantTopics': importantTopics,
      'quickRevision': quickRevision,
      'difficulty': difficulty,
      'estimatedStudyTime': estimatedStudyTime,
      'generatedAt': generatedAt != null ? Timestamp.fromDate(generatedAt!) : FieldValue.serverTimestamp(),
    };
  }
}
