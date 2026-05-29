import 'recommended_item.dart';
import '../user_model.dart';

class RecommendedUser extends RecommendedItem {
  final UserModel user;

  RecommendedUser({
    required this.user,
    required double score,
    required double matchPercentage,
    required List<String> matchReasons,
  }) : super(
          id: user.id,
          score: score,
          matchPercentage: matchPercentage,
          matchReasons: matchReasons,
          recommendationType: 'Person',
        );
}
