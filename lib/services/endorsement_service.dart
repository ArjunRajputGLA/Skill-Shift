import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';

class EndorsementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> endorse({
    required String endorseeId,
    required String endorseeName,
    required String endorserId,
    required String endorserName,
    required String sessionId,
    required List<String> skills,
    required List<String> tags,
    required int rating,
    String? reviewText,
  }) async {
    if (endorseeId == endorserId) {
      return "You cannot endorse yourself.";
    }

    try {
      // 1 endorsement per session per user
      final docId = '${sessionId}_$endorserId';
      final endorsementRef = _firestore.collection('endorsements').doc(docId);
      final userRef = _firestore.collection('users').doc(endorseeId);
      final sessionRef = _firestore.collection('bookings').doc(sessionId);

      final error = await _firestore.runTransaction((transaction) async {
        final endorsementSnapshot = await transaction.get(endorsementRef);
        if (endorsementSnapshot.exists) {
          return "You have already endorsed this user for this session.";
        }

        final userSnapshot = await transaction.get(userRef);
        if (!userSnapshot.exists) {
          return "User not found.";
        }

        final sessionSnapshot = await transaction.get(sessionRef);
        if (!sessionSnapshot.exists) {
          return "Session booking not found.";
        }

        final sessionData = sessionSnapshot.data()!;
        if (sessionData['status'] != 'completed') {
          return "You can only endorse after the session is completed.";
        }

        final userData = userSnapshot.data()!;
        final user = UserModel.fromMap(userData, userSnapshot.id);

        // Update tag endorsements
        final newTagCounts = Map<String, int>.from(user.tagEndorsements);
        for (var tag in tags) {
          newTagCounts[tag] = (newTagCounts[tag] ?? 0) + 1;
        }

        // Update skill endorsements
        final newSkillCounts = Map<String, int>.from(user.skillEndorsements);
        final verifiedSkills = Map<String, bool>.from(user.verifiedSkills);
        for (var skill in skills) {
          int count = (newSkillCounts[skill] ?? 0) + 1;
          newSkillCounts[skill] = count;
          if (count >= 5) {
            verifiedSkills[skill] = true;
          }
        }

        // Update rating
        int oldReviewCount = user.reviewCount;
        double oldAvg = user.averageRating;
        int newReviewCount = oldReviewCount + 1;
        double newAvg = ((oldAvg * oldReviewCount) + rating) / newReviewCount;

        // Write endorsement doc
        transaction.set(endorsementRef, {
          'endorsementId': docId,
          'sessionId': sessionId,
          'receiverUid': endorseeId,
          'receiverName': endorseeName,
          'senderUid': endorserId,
          'senderName': endorserName,
          'skills': skills,
          'tags': tags,
          'rating': rating,
          'reviewText': reviewText ?? '',
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Update user doc
        transaction.update(userRef, {
          'tagEndorsements': newTagCounts,
          'skillEndorsements': newSkillCounts,
          'verifiedSkills': verifiedSkills,
          'averageRating': newAvg,
          'reviewCount': newReviewCount,
        });

        return null;
      });

      if (error == null) {
        String body = 'Left you a $rating-star review!';
        if (skills.isNotEmpty) {
          body = 'Endorsed your ${skills[0]} skill & left a $rating-star review!';
        }
        await NotificationService.createNotification(
          receiverUid: endorseeId,
          type: 'endorsement',
          title: '$endorserName endorsed you!',
          body: body,
          payload: {'endorsementId': docId},
        );
      }

      return error;
    } catch (e) {
      print('Error submitting endorsement: $e');
      return 'An unexpected error occurred while endorsing.';
    }
  }
}
