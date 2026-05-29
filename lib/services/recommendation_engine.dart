import 'dart:math';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/session_slot_model.dart';
import '../models/recommendations/recommended_post.dart';
import '../models/recommendations/recommended_user.dart';
import '../models/recommendations/recommended_session.dart';
import '../models/recommendations/recommended_item.dart';

class RecommendationEngine {
  static const double _perfectScore = 20.0; // Denominator for match percentage

  /// Scores a Post against the current user's profile
  RecommendedPost? scorePost(PostModel post, UserModel currentUser) {
    if (post.uid == currentUser.id) return null; // Don't recommend own posts

    double score = 0;
    List<String> reasons = [];

    final lowerSkills = currentUser.skills.map((e) => e.toLowerCase()).toSet();
    final lowerInterests = currentUser.interests.map((e) => e.toLowerCase()).toSet();
    final postTags = post.tags.map((e) => e.toLowerCase()).toList();

    // 1. Skill Match
    int skillMatches = 0;
    for (var tag in postTags) {
      if (lowerSkills.contains(tag)) {
        skillMatches++;
      }
    }
    if (skillMatches > 0) {
      score += skillMatches * 5.0;
      reasons.add('Matches Skills');
    }

    // 2. Interest Match
    int interestMatches = 0;
    for (var tag in postTags) {
      if (lowerInterests.contains(tag) && !lowerSkills.contains(tag)) {
        interestMatches++;
      }
    }
    if (interestMatches > 0) {
      score += interestMatches * 4.0;
      reasons.add('Matches Interests');
    }

    // 3. Branch & Year Match
    if (post.branch.isNotEmpty && post.branch.toLowerCase() == currentUser.branch.toLowerCase()) {
      score += 2.0;
      reasons.add('Same Branch');
    }
    
    if (post.year.isNotEmpty && post.year.toLowerCase() == currentUser.year.toLowerCase()) {
      score += 1.0;
    }

    if (score <= 0) {
      // Cold start fallback
      if (currentUser.skills.isEmpty && currentUser.interests.isEmpty && currentUser.branch.isEmpty) {
        score = 2.0;
        reasons.add('Popular Post');
      } else {
        return null;
      }
    }

    double percentage = (score / _perfectScore) * 100;
    return RecommendedPost(
      post: post,
      score: score,
      matchPercentage: min(percentage, 99.0),
      matchReasons: reasons.take(2).toList(),
    );
  }

  /// Scores a Candidate User against the current user's profile
  RecommendedUser? scoreUser(UserModel candidate, UserModel currentUser) {
    if (candidate.id == currentUser.id) return null;

    double score = 0;
    List<String> reasons = [];

    final lowerSkills = currentUser.skills.map((e) => e.toLowerCase()).toSet();
    final lowerInterests = currentUser.interests.map((e) => e.toLowerCase()).toSet();
    
    // 1. Skill Intersection
    int sharedSkills = 0;
    for (var skill in candidate.skills) {
      if (lowerSkills.contains(skill.toLowerCase())) sharedSkills++;
    }
    if (sharedSkills > 0) {
      score += sharedSkills * 4.0;
      reasons.add('Similar Skills');
    }

    // 2. Interest Intersection
    int sharedInterests = 0;
    for (var interest in candidate.interests) {
      if (lowerInterests.contains(interest.toLowerCase())) sharedInterests++;
    }
    if (sharedInterests > 0) {
      score += sharedInterests * 3.0;
      reasons.add('Shared Interests');
    }

    // 3. Reputation / Verified Skills
    int verifiedMatch = 0;
    candidate.verifiedSkills.forEach((skill, isVerified) {
      if (isVerified && (lowerSkills.contains(skill.toLowerCase()) || lowerInterests.contains(skill.toLowerCase()))) {
        verifiedMatch++;
      }
    });
    if (verifiedMatch > 0) {
      score += verifiedMatch * 3.0;
      reasons.add('Verified Expert');
    }

    if (candidate.averageRating >= 4.0) {
      score += 2.0;
      if (reasons.isEmpty) reasons.add('Highly Rated');
    }

    // 4. Branch Match
    if (candidate.branch.isNotEmpty && candidate.branch.toLowerCase() == currentUser.branch.toLowerCase()) {
      score += 2.0;
      if (reasons.length < 2) reasons.add('Same Branch');
    }

    if (score <= 0) {
      // Small baseline for high-rated users to handle cold start
      if (candidate.averageRating >= 4.0) {
        score = 2.0;
        reasons.add('Top Mentor');
      } else if (currentUser.skills.isEmpty && currentUser.interests.isEmpty && currentUser.branch.isEmpty) {
        score = 1.0;
        reasons.add('Suggested User');
      } else {
        return null;
      }
    }

    double percentage = (score / _perfectScore) * 100;
    return RecommendedUser(
      user: candidate,
      score: score,
      matchPercentage: min(percentage, 99.0),
      matchReasons: reasons.take(2).toList(),
    );
  }

  /// Scores a Session against the current user's profile
  RecommendedSession? scoreSession(SessionSlotModel session, UserModel currentUser) {
    if (session.ownerUid == currentUser.id) return null;
    if (session.status != 'scheduled') return null; // Only recommend upcoming/bookable sessions

    double score = 0;
    List<String> reasons = [];

    final lowerSkills = currentUser.skills.map((e) => e.toLowerCase()).toSet();
    final lowerInterests = currentUser.interests.map((e) => e.toLowerCase()).toSet();
    
    // Topic match
    final lowerTopic = session.topic.toLowerCase();
    bool topicMatched = false;
    
    if (lowerTopic.isNotEmpty) {
      for (var skill in lowerSkills) {
        if (lowerTopic.contains(skill)) {
          score += 6.0;
          reasons.add('Matches Skill');
          topicMatched = true;
          break;
        }
      }
      if (!topicMatched) {
        for (var interest in lowerInterests) {
          if (lowerTopic.contains(interest)) {
            score += 5.0;
            reasons.add('Matches Interest');
            topicMatched = true;
            break;
          }
        }
      }
    }

    // Title match as fallback
    final lowerTitle = session.title.toLowerCase();
    if (!topicMatched) {
      for (var skill in lowerSkills) {
        if (lowerTitle.contains(skill)) {
          score += 4.0;
          reasons.add('Relevant Topic');
          break;
        }
      }
    }

    if (score <= 0) {
      if (currentUser.skills.isEmpty && currentUser.interests.isEmpty && currentUser.branch.isEmpty) {
        score = 2.0;
        reasons.add('Upcoming Session');
      } else {
        return null;
      }
    }

    double percentage = (score / _perfectScore) * 100;
    return RecommendedSession(
      session: session,
      score: score,
      matchPercentage: min(percentage, 99.0),
      matchReasons: reasons.take(2).toList(),
    );
  }
}
