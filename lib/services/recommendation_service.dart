import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../models/session_slot_model.dart';
import '../models/recommendations/recommended_item.dart';
import '../models/recommendations/recommended_post.dart';
import 'recommendation_engine.dart';

class RecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RecommendationEngine _engine = RecommendationEngine();

  /// Fetches a mix of Posts, Users, and Sessions, scores them, and returns a unified sorted list.
  Future<List<RecommendedItem>> getMixedRecommendations(UserModel currentUser) async {
    try {
      List<RecommendedItem> allRecommendations = [];

      // 1. Fetch Candidates (limit to keep performance high)
      final postsFuture = _firestore.collection('posts').orderBy('createdAt', descending: true).limit(30).get().catchError((e) {
        print("Error fetching posts: $e");
        return _firestore.collection('posts').get(); // fallback if index missing
      });
      final usersFuture = _firestore.collection('users').orderBy('averageRating', descending: true).limit(30).get().catchError((e) {
        print("Error fetching users: $e");
        return _firestore.collection('users').limit(30).get();
      });
      final sessionsFuture = _firestore.collectionGroup('session_slots')
          .where('status', isEqualTo: 'scheduled')
          .limit(20)
          .get()
          .catchError((e) {
            print("Error fetching sessions: $e");
            // Return an empty snapshot-like object or handle gracefully.
            // Since we can't easily return a dummy QuerySnapshot, we'll fetch without where clause.
            return _firestore.collectionGroup('session_slots').limit(20).get();
          });

      final results = await Future.wait([postsFuture, usersFuture, sessionsFuture]);

      final postsSnapshot = results[0];
      final usersSnapshot = results[1];
      final sessionsSnapshot = results[2];

      // 2. Score Posts
      for (var doc in postsSnapshot.docs) {
        final post = PostModel.fromMap(doc.data(), doc.id);
        final recPost = _engine.scorePost(post, currentUser);
        if (recPost != null) {
          allRecommendations.add(recPost);
        }
      }

      // 3. Score Users
      for (var doc in usersSnapshot.docs) {
        final user = UserModel.fromMap(doc.data(), doc.id);
        final recUser = _engine.scoreUser(user, currentUser);
        if (recUser != null) {
          allRecommendations.add(recUser);
        }
      }

      // 4. Score Sessions
      for (var doc in sessionsSnapshot.docs) {
        final session = SessionSlotModel.fromMap(doc.data(), doc.id);
        final recSession = _engine.scoreSession(session, currentUser);
        if (recSession != null) {
          allRecommendations.add(recSession);
        }
      }

      // 6. Sort all by score descending
      allRecommendations.sort((a, b) => b.score.compareTo(a.score));

      // 7. Fallback if still empty (e.g., user has some skills but no matches found)
      if (allRecommendations.isEmpty && postsSnapshot.docs.isNotEmpty) {
        for (var doc in postsSnapshot.docs.take(5)) {
          final post = PostModel.fromMap(doc.data(), doc.id);
          if (post.uid != currentUser.id) {
            allRecommendations.add(
              RecommendedPost(
                post: post,
                score: 1.0,
                matchPercentage: 5.0,
                matchReasons: ['Popular Post'],
              ),
            );
          }
        }
      }

      // 8. Return Top 15 Mix
      return allRecommendations.take(15).toList();
    } catch (e) {
      print('Error getting mixed recommendations: $e');
      return [];
    }
  }
}
