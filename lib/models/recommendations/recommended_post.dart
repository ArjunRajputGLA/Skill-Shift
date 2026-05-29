import 'recommended_item.dart';
import '../post_model.dart';

class RecommendedPost extends RecommendedItem {
  final PostModel post;

  RecommendedPost({
    required this.post,
    required double score,
    required double matchPercentage,
    required List<String> matchReasons,
  }) : super(
          id: post.id,
          score: score,
          matchPercentage: matchPercentage,
          matchReasons: matchReasons,
          recommendationType: 'Post',
        );
}
