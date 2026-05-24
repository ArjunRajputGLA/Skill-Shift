import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/farrey_models.dart';

class FarreyDatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection References
  CollectionReference get _notesCollection => _firestore.collection('farrey_notes');
  CollectionReference get _commentsCollection => _firestore.collection('farrey_comments');
  CollectionReference get _savedCollection => _firestore.collection('saved_notes');

  /// Upload Note Metadata
  Future<String?> uploadNoteMetadata(FarreyNoteModel note) async {
    try {
      await _notesCollection.doc(note.noteId).set(note.toMap());
      return null; // success
    } catch (e) {
      return e.toString();
    }
  }

  /// Get Trending Notes
  Stream<List<FarreyNoteModel>> getTrendingNotes() {
    return _notesCollection
        .orderBy('totalDownloads', descending: true) // simplified trending proxy
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => FarreyNoteModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  /// Get Recently Uploaded Notes
  Stream<List<FarreyNoteModel>> getRecentNotes() {
    return _notesCollection
        .orderBy('uploadTime', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => FarreyNoteModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  /// Add Comment
  Future<String?> addComment(FarreyCommentModel comment) async {
    try {
      await _commentsCollection.doc(comment.commentId).set(comment.toMap());
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Get Comments for Note
  Stream<List<FarreyCommentModel>> getNoteComments(String noteId) {
    return _commentsCollection
        .where('noteId', isEqualTo: noteId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => FarreyCommentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  /// Save / Bookmark Note
  Future<void> toggleSaveNote(String uid, String noteId, bool isSaved) async {
    final docRef = _savedCollection.doc('${uid}_$noteId');
    if (isSaved) {
      await docRef.set({
        'uid': uid,
        'noteId': noteId,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.delete();
    }
  }

  /// Check if Note is Saved
  Stream<bool> isNoteSaved(String uid, String noteId) {
    return _savedCollection.doc('${uid}_$noteId').snapshots().map((doc) => doc.exists);
  }

  /// Search Notes
  Future<List<FarreyNoteModel>> searchNotes(String query) async {
    if (query.isEmpty) return [];
    
    // Simplistic search: getting all and filtering in memory (due to Firestore limitations without algolia)
    // For a real app, Algolia or Typesense is recommended.
    final snapshot = await _notesCollection.orderBy('uploadTime', descending: true).get();
    
    final allNotes = snapshot.docs.map((doc) => FarreyNoteModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    
    final q = query.toLowerCase();
    return allNotes.where((note) {
      return note.title.toLowerCase().contains(q) || 
             note.subject.toLowerCase().contains(q) || 
             note.tags.any((tag) => tag.toLowerCase().contains(q));
    }).toList();
  }
}
