import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

class RecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<PostModel>> getRecommendations(UserModel currentUser) async {
    try {
      // 1. Fetch recent posts (limit to 100 for efficiency)
      final snapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      final posts = snapshot.docs
          .map((doc) => PostModel.fromMap(doc.data(), doc.id))
          // Don't recommend user's own posts
          .where((post) => post.uid != currentUser.id)
          .toList();

      // 2. Score posts based on profile matching
      final Map<PostModel, int> postScores = {};

      for (var post in posts) {
        int score = 0;

        // +3 if post tag matches a user skill
        for (var tag in post.tags) {
          if (currentUser.skills.any((s) => s.toLowerCase() == tag.toLowerCase())) {
            score += 3;
          }
        }

        // +2 if post tag matches a user interest
        for (var tag in post.tags) {
          if (currentUser.interests.any((i) => i.toLowerCase() == tag.toLowerCase())) {
            score += 2;
          }
        }

        // +1 if branch matches
        if (post.branch.isNotEmpty && 
            currentUser.branch.isNotEmpty && 
            post.branch.toLowerCase() == currentUser.branch.toLowerCase()) {
          score += 1;
        }

        // Only recommend posts that have a score > 0
        if (score > 0) {
          postScores[post] = score;
        }
      }

      // 3. Sort posts by score descending
      final sortedEntries = postScores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)); // descending

      // 4. Return top recommendations (e.g., top 10)
      return sortedEntries.map((e) => e.key).take(10).toList();
    } catch (e) {
      print('Error getting recommendations: $e');
      return [];
    }
  }
}
