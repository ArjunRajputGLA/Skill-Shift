import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/farrey_models.dart';
import '../models/ai_doubt_chat.dart';
import '../services/doubt_solver_service.dart';
import '../theme/farrey_colors.dart';
import '../widgets/chat_bubble.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoubtSolverScreen extends StatefulWidget {
  final FarreyNoteModel note;

  const DoubtSolverScreen({super.key, required this.note});

  @override
  State<DoubtSolverScreen> createState() => _DoubtSolverScreenState();
}

class _DoubtSolverScreenState extends State<DoubtSolverScreen> {
  final DoubtSolverService _solverService = DoubtSolverService();
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  AiDoubtChat? _currentChat;
  bool _isLoading = true;
  bool _isTyping = false;

  final List<String> _quickActions = [
    'Explain Simply',
    'Give Examples',
    'Exam Questions',
    'Quick Revision'
  ];

  @override
  void initState() {
    super.initState();
    _loadChatSession();
  }

  Future<void> _loadChatSession() async {
    final chat = await _solverService.getChatSession(widget.note.noteId);
    if (mounted) {
      setState(() {
        _currentChat = chat;
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    final userMsg = AiDoubtMessage(
      messageId: const Uuid().v4(),
      sender: 'user',
      text: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      if (_currentChat == null) {
        _currentChat = AiDoubtChat(
          chatId: const Uuid().v4(),
          noteId: widget.note.noteId,
          uid: uid,
          messages: [userMsg],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        _currentChat!.messages.add(userMsg);
      }
      _isTyping = true;
    });

    _msgController.clear();
    _scrollToBottom();

    try {
      final aiResponseText = await _solverService.askAiDoubt(
        noteId: widget.note.noteId,
        fileUrls: widget.note.fileUrls,
        fileTypes: widget.note.fileTypes,
        userQuery: text,
        chatHistory: _currentChat!.messages,
      );

      final aiMsg = AiDoubtMessage(
        messageId: const Uuid().v4(),
        sender: 'ai',
        text: aiResponseText,
        timestamp: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _currentChat!.messages.add(aiMsg);
          _isTyping = false;
        });
        _scrollToBottom();
        _solverService.saveChatSession(_currentChat!);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Failed to get AI response. Please try again.'),
          backgroundColor: context.farreyError,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.farreyBackground,
      appBar: AppBar(
        backgroundColor: context.farreyBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: context.farreyTextPrimary),
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: context.farreyPrimary),
            const SizedBox(width: 8),
            Text(
              'Farrey AI Tutor',
              style: TextStyle(
                color: context.farreyTextPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: context.farreyPrimary))
          : Column(
              children: [
                Expanded(
                  child: _currentChat == null || _currentChat!.messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: _currentChat!.messages.length + (_isTyping ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _currentChat!.messages.length && _isTyping) {
                              return _buildTypingIndicator();
                            }
                            return ChatBubble(message: _currentChat!.messages[index]);
                          },
                        ),
                ),
                _buildQuickActions(),
                _buildInputArea(),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.farreyPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.psychology, size: 64, color: context.farreyPrimary),
            ),
            const SizedBox(height: 24),
            Text(
              'Context-Aware Doubt Solver',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.farreyTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask me anything about "${widget.note.title}". I have fully analyzed the documents and am ready to explain concepts, provide examples, or quiz you!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.farreyTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: context.farreySurface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 14, color: context.farreyPrimary),
            const SizedBox(width: 8),
            Text(
              'AI is thinking...',
              style: TextStyle(color: context.farreyTextSecondary, fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: _quickActions.map((action) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              backgroundColor: context.farreySurface,
              side: BorderSide(color: context.farreyPrimary.withValues(alpha: 0.3)),
              label: Text(
                action,
                style: TextStyle(color: context.farreyPrimary, fontSize: 12),
              ),
              onPressed: () => _sendMessage(action),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.farreyBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: context.farreySurface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _msgController,
                  maxLines: 4,
                  minLines: 1,
                  style: TextStyle(color: context.farreyTextPrimary),
                  decoration: InputDecoration(
                    hintText: 'Ask about this note...',
                    hintStyle: TextStyle(color: context.farreyTextSecondary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                if (!_isTyping) {
                  _sendMessage(_msgController.text);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.farreyPrimary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: context.farreyBackground,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
