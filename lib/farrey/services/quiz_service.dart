import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/farrey_quiz.dart';

class QuizService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<FarreyQuiz>> getQuizzes(String noteId) async {
    try {
      final querySnapshot = await _firestore
          .collection('farrey_quizzes')
          .where('noteId', isEqualTo: noteId)
          .get();

      return querySnapshot.docs
          .map((doc) => FarreyQuiz.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception("Failed to load quizzes: $e");
    }
  }

  Stream<List<FarreyQuiz>> streamQuizzes(String noteId) {
    return _firestore
        .collection('farrey_quizzes')
        .where('noteId', isEqualTo: noteId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FarreyQuiz.fromMap(doc.data(), doc.id))
            .toList());
  }
}
