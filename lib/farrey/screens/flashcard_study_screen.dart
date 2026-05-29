import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/farrey_flashcard.dart';
import '../services/flashcard_service.dart';
import '../theme/farrey_colors.dart';

class FlashcardStudyScreen extends StatefulWidget {
  final String noteId;
  const FlashcardStudyScreen({Key? key, required this.noteId}) : super(key: key);

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen> {
  final FlashcardService _flashcardService = FlashcardService();
  final PageController _pageController = PageController();
  late Stream<List<FarreyFlashcard>> _flashcardsStream;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _flashcardsStream = _flashcardService.streamFlashcards(widget.noteId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.farreyBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Flashcards', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<FarreyFlashcard>>(
        stream: _flashcardsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: context.farreyPrimary));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          final flashcards = snapshot.data ?? [];
          if (flashcards.isEmpty) {
            return const Center(child: Text("No flashcards found.", style: TextStyle(color: Colors.white70)));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / flashcards.length,
                  backgroundColor: Colors.white12,
                  color: context.farreyPrimary,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: flashcards.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: FlipCard(flashcard: flashcards[index]),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_currentIndex + 1} / ${flashcards.length}',
                      style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

class FlipCard extends StatefulWidget {
  final FarreyFlashcard flashcard;

  const FlipCard({Key? key, required this.flashcard}) : super(key: key);

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _isFront = !_isFront;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(_animation.value * pi);

          final isFrontSide = _animation.value < 0.5;

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: isFrontSide
                ? _buildCardSide(
                    context: context,
                    text: widget.flashcard.question,
                    isQuestion: true,
                    difficulty: widget.flashcard.difficulty,
                  )
                : Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: _buildCardSide(
                      context: context,
                      text: widget.flashcard.answer,
                      isQuestion: false,
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildCardSide({required BuildContext context, required String text, required bool isQuestion, String? difficulty}) {
    return Container(
      decoration: BoxDecoration(
        color: context.farreySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isQuestion ? context.farreyPrimary.withOpacity(0.5) : Colors.green.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isQuestion && difficulty != null)
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: difficulty == 'Hard' ? Colors.red.withOpacity(0.2) : (difficulty == 'Medium' ? Colors.orange.withOpacity(0.2) : Colors.green.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  difficulty,
                  style: TextStyle(
                    color: difficulty == 'Hard' ? Colors.red : (difficulty == 'Medium' ? Colors.orange : Colors.green),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          const Spacer(),
          Text(
            isQuestion ? 'Q' : 'A',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isQuestion ? context.farreyPrimary : Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            isQuestion ? 'Tap to flip' : 'Tap to go back',
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
