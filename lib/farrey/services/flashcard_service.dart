import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/farrey_flashcard.dart';

class FlashcardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<FarreyFlashcard>> getFlashcards(String noteId) async {
    try {
      final querySnapshot = await _firestore
          .collection('farrey_flashcards')
          .where('noteId', isEqualTo: noteId)
          .get();

      return querySnapshot.docs
          .map((doc) => FarreyFlashcard.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception("Failed to load flashcards: $e");
    }
  }

  Stream<List<FarreyFlashcard>> streamFlashcards(String noteId) {
    return _firestore
        .collection('farrey_flashcards')
        .where('noteId', isEqualTo: noteId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FarreyFlashcard.fromMap(doc.data(), doc.id))
            .toList());
  }
}
