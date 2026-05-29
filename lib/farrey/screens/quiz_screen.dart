import 'package:flutter/material.dart';
import '../../models/farrey_quiz.dart';
import '../services/quiz_service.dart';
import '../theme/farrey_colors.dart';

class QuizScreen extends StatefulWidget {
  final String noteId;
  const QuizScreen({Key? key, required this.noteId}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final QuizService _quizService = QuizService();
  final PageController _pageController = PageController();
  late Stream<List<FarreyQuiz>> _quizzesStream;
  
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _quizzesStream = _quizService.streamQuizzes(widget.noteId);
  }

  int _score = 0;
  String? _selectedAnswer;
  bool _isAnswered = false;

  void _submitAnswer(FarreyQuiz currentQuiz, String answer) {
    if (_isAnswered) return;
    
    setState(() {
      _selectedAnswer = answer;
      _isAnswered = true;
      if (answer == currentQuiz.correctAnswer) {
        _score++;
      }
    });
  }

  void _nextQuestion(int totalQuestions) {
    if (_currentIndex < totalQuestions - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _isAnswered = false;
        _selectedAnswer = null;
      });
    } else {
      // Show results dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: context.farreySurface,
          title: const Text('Quiz Completed!', style: TextStyle(color: Colors.white)),
          content: Text('You scored $_score out of $totalQuestions.', style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close quiz screen
              },
              child: Text('Back to Note', style: TextStyle(color: context.farreyPrimary)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.farreyBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Quiz Mode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<FarreyQuiz>>(
        stream: _quizzesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: context.farreyPrimary));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          final quizzes = snapshot.data ?? [];
          if (quizzes.isEmpty) {
            return const Center(child: Text("No quizzes found.", style: TextStyle(color: Colors.white70)));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Score: $_score',
                      style: TextStyle(color: context.farreyPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_currentIndex + 1} / ${quizzes.length}',
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / quizzes.length,
                  backgroundColor: Colors.white12,
                  color: context.farreyPrimary,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Disable swiping to force answering
                  itemCount: quizzes.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final quiz = quizzes[index];
                    return Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: context.farreySurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Text(
                              quiz.question,
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ...quiz.options.map((option) {
                            bool isSelected = _selectedAnswer == option;
                            bool isCorrect = option == quiz.correctAnswer;
                            
                            Color buttonColor = context.farreySurface;
                            Color borderColor = Colors.white24;
                            
                            if (_isAnswered) {
                              if (isCorrect) {
                                buttonColor = Colors.green.withOpacity(0.2);
                                borderColor = Colors.green;
                              } else if (isSelected) {
                                buttonColor = Colors.red.withOpacity(0.2);
                                borderColor = Colors.red;
                              }
                            } else if (isSelected) {
                              borderColor = context.farreyPrimary;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: InkWell(
                                onTap: () => _submitAnswer(quiz, option),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: buttonColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: borderColor, width: 2),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          option,
                                          style: const TextStyle(color: Colors.white, fontSize: 16),
                                        ),
                                      ),
                                      if (_isAnswered && isCorrect)
                                        const Icon(Icons.check_circle, color: Colors.green),
                                      if (_isAnswered && isSelected && !isCorrect)
                                        const Icon(Icons.cancel, color: Colors.red),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                          if (_isAnswered) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Explanation", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text(quiz.explanation, style: const TextStyle(color: Colors.white70)),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          if (_isAnswered)
                            ElevatedButton(
                              onPressed: () => _nextQuestion(quizzes.length),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.farreyPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Next Question', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                        ],
                      ),
                    ),
                  );
                },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
