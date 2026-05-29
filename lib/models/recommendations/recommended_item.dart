abstract class RecommendedItem {
  final String id;
  final double score;
  final double matchPercentage;
  final List<String> matchReasons;
  final String recommendationType;

  RecommendedItem({
    required this.id,
    required this.score,
    required this.matchPercentage,
    required this.matchReasons,
    required this.recommendationType,
  });
}
