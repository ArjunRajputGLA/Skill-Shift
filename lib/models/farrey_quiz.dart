class FarreyQuiz {
  final String quizId;
  final String noteId;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final String difficulty;

  FarreyQuiz({
    required this.quizId,
    required this.noteId,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.difficulty,
  });

  factory FarreyQuiz.fromMap(Map<String, dynamic> map, String id) {
    return FarreyQuiz(
      quizId: map['quizId'] ?? id,
      noteId: map['noteId'] ?? '',
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correctAnswer'] ?? '',
      explanation: map['explanation'] ?? '',
      difficulty: map['difficulty'] ?? 'Medium',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'quizId': quizId,
      'noteId': noteId,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'difficulty': difficulty,
    };
  }
}
