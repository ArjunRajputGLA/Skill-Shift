import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/farrey_models.dart';
import '../../services/notification_service.dart';

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
      
      // Notify users of the same branch
      try {
        final usersSnapshot = await _firestore.collection('users')
            .where('branch', isEqualTo: note.branch)
            .get();
            
        for (var doc in usersSnapshot.docs) {
          final userId = doc.id;
          if (userId != note.uploaderUid) {
            await NotificationService.createNotification(
              receiverUid: userId,
              type: 'farrey_upload',
              title: 'New Note in ${note.branch}',
              body: '${note.uploaderName} uploaded "${note.title}" for ${note.subject}.',
              payload: {'noteId': note.noteId},
            );
          }
        }
      } catch (e) {
        // Ignore notification errors
      }
      
      return null; // success
    } catch (e) {
      return e.toString();
    }
  }

  /// Update Note Metadata
  Future<String?> updateNoteMetadata(FarreyNoteModel note) async {
    try {
      await _notesCollection.doc(note.noteId).update(note.toMap());
      return null; // success
    } catch (e) {
      return e.toString();
    }
  }

  /// Get Trending Notes
  Stream<List<FarreyNoteModel>> getTrendingNotes(String currentUserId, {List<String>? categories}) {
    return _notesCollection
        .snapshots()
        .map((snapshot) {
      var notes = snapshot.docs.map((doc) => FarreyNoteModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      notes = notes.where((note) => note.uploaderUid != currentUserId && note.moderationStatus == 'approved').toList();
      if (categories != null && categories.isNotEmpty) {
        notes = notes.where((note) => 
          categories.any((c) => note.subject.toLowerCase() == c.toLowerCase()) || 
          note.tags.any((t) => categories.any((c) => c.toLowerCase() == t.toLowerCase()))
        ).toList();
      }
      notes.sort((a, b) => b.totalDownloads.compareTo(a.totalDownloads));
      return notes.take(10).toList();
    });
  }

  /// Get Recently Uploaded Notes
  Stream<List<FarreyNoteModel>> getRecentNotes(String currentUserId, {List<String>? categories}) {
    return _notesCollection
        .snapshots()
        .map((snapshot) {
      var notes = snapshot.docs.map((doc) => FarreyNoteModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      notes = notes.where((note) => note.uploaderUid != currentUserId && note.moderationStatus == 'approved').toList();
      if (categories != null && categories.isNotEmpty) {
        notes = notes.where((note) => 
          categories.any((c) => note.subject.toLowerCase() == c.toLowerCase()) || 
          note.tags.any((t) => categories.any((c) => c.toLowerCase() == t.toLowerCase()))
        ).toList();
      }
      notes.sort((a, b) => b.uploadTime.compareTo(a.uploadTime));
      return notes.take(20).toList();
    });
  }

  /// Add Comment
  Future<String?> addComment(FarreyCommentModel comment) async {
    try {
      await _commentsCollection.doc(comment.commentId).set(comment.toMap());
      await _notesCollection.doc(comment.noteId).update({
        'totalComments': FieldValue.increment(1)
      });
      
      // Send notification to note uploader
      try {
        final noteDoc = await _notesCollection.doc(comment.noteId).get();
        if (noteDoc.exists) {
          final data = noteDoc.data() as Map<String, dynamic>;
          final uploaderUid = data['uploaderUid'];
          final noteTitle = data['title'] ?? 'a note';
          if (uploaderUid != null && uploaderUid != comment.senderUid) {
            await NotificationService.createNotification(
              receiverUid: uploaderUid,
              type: 'farrey_comment',
              title: 'New Comment',
              body: '${comment.senderName} commented on "$noteTitle".',
              payload: {'noteId': comment.noteId},
            );
          }
        }
      } catch (e) {
        // Ignore notification errors
      }
      
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Get Comments for Note
  Stream<List<FarreyCommentModel>> getNoteComments(String noteId) {
    return _commentsCollection
        .where('noteId', isEqualTo: noteId)
        .snapshots()
        .map((snapshot) {
      final comments = snapshot.docs.map((doc) => FarreyCommentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      comments.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return comments;
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
      if (note.moderationStatus != 'approved') return false;
      return note.title.toLowerCase().contains(q) || 
             note.subject.toLowerCase().contains(q) || 
             note.tags.any((tag) => tag.toLowerCase().contains(q));
    }).toList();
  }

  /// Report a Note for Community Moderation
  Future<String?> reportNote(String noteId, String reporterUid) async {
    try {
      final docRef = _notesCollection.doc(noteId);
      final error = await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) return 'Note not found';

        final data = doc.data() as Map<String, dynamic>;
        List<String> reportedBy = List<String>.from(data['reportedBy'] ?? []);
        
        if (reportedBy.contains(reporterUid)) {
          return 'You have already reported this note.';
        }

        reportedBy.add(reporterUid);
        
        String newStatus = data['moderationStatus'] ?? 'approved';
        if (reportedBy.length >= 3) {
          newStatus = 'hidden';
        }

        transaction.update(docRef, {
          'reportedBy': reportedBy,
          'moderationStatus': newStatus,
        });
      });
      return error; // returns null on success
    } catch (e) {
      return 'Failed to report note: $e';
    }
  }

  /// One-Time Rating System (Zomato-style)
  Future<String?> submitRating(String noteId, String userId, String userName, String? userPhotoUrl, double rating, String reviewText) async {
    try {
      final docRef = _notesCollection.doc(noteId);
      final ratingRef = docRef.collection('ratings').doc(userId);

      String? noteUploaderUid;
      String noteTitle = '';
      bool isNewRating = true;

      final error = await _firestore.runTransaction((transaction) async {
        final noteDoc = await transaction.get(docRef);
        if (!noteDoc.exists) {
          return 'Note not found';
        }

        final ratingDoc = await transaction.get(ratingRef);
        
        final data = noteDoc.data() as Map<String, dynamic>;
        noteUploaderUid = data['uploaderUid'];
        noteTitle = data['title'] ?? 'your note';
        
        final currentAverage = (data['averageRating'] ?? 0.0) is int ? (data['averageRating'] as int).toDouble() : (data['averageRating'] ?? 0.0) as double;
        final currentTotal = (data['totalRatings'] ?? 0) as int;
        
        double newAverage;
        int newTotal;

        if (ratingDoc.exists) {
          // Editing existing rating
          isNewRating = false;
          final oldRatingData = ratingDoc.data() as Map<String, dynamic>;
          final oldRating = (oldRatingData['rating'] ?? currentAverage).toDouble();
          
          if (currentTotal <= 1) {
             newAverage = rating;
             newTotal = 1;
          } else {
             newTotal = currentTotal;
             newAverage = ((currentAverage * currentTotal) - oldRating + rating) / newTotal;
          }

          transaction.update(ratingRef, {
            'rating': rating,
            'review': reviewText,
            'userName': userName,
            'userPhotoUrl': userPhotoUrl,
            'timestamp': FieldValue.serverTimestamp(),
            'isEdited': true,
          });
        } else {
          // New rating
          isNewRating = true;
          newTotal = currentTotal + 1;
          newAverage = ((currentAverage * currentTotal) + rating) / newTotal;

          transaction.set(ratingRef, {
            'rating': rating,
            'review': reviewText,
            'userName': userName,
            'userPhotoUrl': userPhotoUrl,
            'timestamp': FieldValue.serverTimestamp(),
            'isEdited': false,
          });
        }

        transaction.update(docRef, {
          'averageRating': newAverage,
          'totalRatings': newTotal,
        });

        return null; // success
      });

      if (error == null && isNewRating && noteUploaderUid != null && noteUploaderUid != userId) {
        // Send notification for NEW ratings only
        try {
          await NotificationService.createNotification(
            receiverUid: noteUploaderUid!,
            type: 'farrey_rating',
            title: 'New Review',
            body: '$userName reviewed "$noteTitle" with ${rating.toStringAsFixed(1)} stars.',
            payload: {'noteId': noteId},
          );
        } catch (e) {
          // Ignore
        }
      }

      return error;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteReview(String noteId, String userId) async {
    try {
      final docRef = _notesCollection.doc(noteId);
      final ratingRef = docRef.collection('ratings').doc(userId);

      final error = await _firestore.runTransaction((transaction) async {
        final noteDoc = await transaction.get(docRef);
        if (!noteDoc.exists) return 'Note not found';

        final ratingDoc = await transaction.get(ratingRef);
        if (!ratingDoc.exists) return 'Review not found';
        
        final data = noteDoc.data() as Map<String, dynamic>;
        final currentAverage = (data['averageRating'] ?? 0.0) is int ? (data['averageRating'] as int).toDouble() : (data['averageRating'] ?? 0.0) as double;
        final currentTotal = (data['totalRatings'] ?? 0) as int;
        
        final oldRatingData = ratingDoc.data() as Map<String, dynamic>;
        final oldRating = (oldRatingData['rating'] ?? currentAverage).toDouble();

        double newAverage = 0.0;
        int newTotal = currentTotal - 1;

        if (newTotal > 0) {
           newAverage = ((currentAverage * currentTotal) - oldRating) / newTotal;
        }

        transaction.delete(ratingRef);

        transaction.update(docRef, {
          'averageRating': newAverage,
          'totalRatings': newTotal,
        });

        return null; // success
      });

      return error;
    } catch (e) {
      return 'Error deleting review: $e';
    }
  }

  /// Check if User Rated
  Stream<bool> hasUserRated(String noteId, String userId) {
    return _notesCollection
        .doc(noteId)
        .collection('ratings')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Get User's Existing Review
  Future<FarreyReviewModel?> getUserReview(String noteId, String userId) async {
    final doc = await _notesCollection.doc(noteId).collection('ratings').doc(userId).get();
    if (doc.exists && doc.data() != null) {
      return FarreyReviewModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  /// Get All Note Reviews
  Stream<List<FarreyReviewModel>> getNoteReviews(String noteId) {
    return _notesCollection
        .doc(noteId)
        .collection('ratings')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => FarreyReviewModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  /// Increment Downloads
  Future<void> incrementDownloads(String noteId) async {
    try {
      await _notesCollection.doc(noteId).update({
        'totalDownloads': FieldValue.increment(1)
      });
    } catch (e) {
      // Ignore errors for simple stats updates
    }
  }

  /// Delete Note
  Future<String?> deleteNote(String noteId, String fileUrl) async {
    try {
      // Delete file from Storage
      try {
        final storageRef = FirebaseStorage.instance.refFromURL(fileUrl);
        await storageRef.delete();
      } catch (e) {
        // Continue deleting document even if storage fails (e.g. file already gone)
      }

      // Delete document from Firestore
      await _notesCollection.doc(noteId).delete();
      
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
