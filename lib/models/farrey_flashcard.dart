import 'package:cloud_firestore/cloud_firestore.dart';

class FarreyFlashcard {
  final String flashcardId;
  final String noteId;
  final String question;
  final String answer;
  final String difficulty;
  final DateTime? generatedAt;

  FarreyFlashcard({
    required this.flashcardId,
    required this.noteId,
    required this.question,
    required this.answer,
    required this.difficulty,
    this.generatedAt,
  });

  factory FarreyFlashcard.fromMap(Map<String, dynamic> map, String id) {
    return FarreyFlashcard(
      flashcardId: map['flashcardId'] ?? id,
      noteId: map['noteId'] ?? '',
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      difficulty: map['difficulty'] ?? 'Medium',
      generatedAt: map['generatedAt'] != null 
          ? (map['generatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'flashcardId': flashcardId,
      'noteId': noteId,
      'question': question,
      'answer': answer,
      'difficulty': difficulty,
      'generatedAt': generatedAt != null ? Timestamp.fromDate(generatedAt!) : FieldValue.serverTimestamp(),
    };
  }
}
