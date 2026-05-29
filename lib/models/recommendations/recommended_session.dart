import 'recommended_item.dart';
import '../session_slot_model.dart';

class RecommendedSession extends RecommendedItem {
  final SessionSlotModel session;

  RecommendedSession({
    required this.session,
    required double score,
    required double matchPercentage,
    required List<String> matchReasons,
  }) : super(
          id: session.id,
          score: score,
          matchPercentage: matchPercentage,
          matchReasons: matchReasons,
          recommendationType: 'Session',
        );
}
