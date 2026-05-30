import 'package:cloud_firestore/cloud_firestore.dart';

class AiDoubtMessage {
  final String messageId;
  final String sender; // 'user' or 'ai'
  final String text;
  final DateTime timestamp;

  AiDoubtMessage({
    required this.messageId,
    required this.sender,
    required this.text,
    required this.timestamp,
  });

  factory AiDoubtMessage.fromMap(Map<String, dynamic> map) {
    DateTime parsedTimestamp = DateTime.now();
    if (map['timestamp'] is Timestamp) {
      parsedTimestamp = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is String) {
      parsedTimestamp = DateTime.parse(map['timestamp']);
    }

    return AiDoubtMessage(
      messageId: map['messageId'] ?? '',
      sender: map['sender'] ?? 'user',
      text: map['text'] ?? '',
      timestamp: parsedTimestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'sender': sender,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

class AiDoubtChat {
  final String chatId;
  final String noteId;
  final String uid;
  final List<AiDoubtMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  AiDoubtChat({
    required this.chatId,
    required this.noteId,
    required this.uid,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AiDoubtChat.fromMap(Map<String, dynamic> map, String id) {
    List<AiDoubtMessage> parsedMessages = [];
    if (map['messages'] is List) {
      parsedMessages = (map['messages'] as List)
          .map((msg) => AiDoubtMessage.fromMap(Map<String, dynamic>.from(msg)))
          .toList();
    }

    DateTime parsedCreatedAt = DateTime.now();
    if (map['createdAt'] is Timestamp) {
      parsedCreatedAt = (map['createdAt'] as Timestamp).toDate();
    }

    DateTime parsedUpdatedAt = DateTime.now();
    if (map['updatedAt'] is Timestamp) {
      parsedUpdatedAt = (map['updatedAt'] as Timestamp).toDate();
    }

    return AiDoubtChat(
      chatId: id,
      noteId: map['noteId'] ?? '',
      uid: map['uid'] ?? '',
      messages: parsedMessages,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'noteId': noteId,
      'uid': uid,
      'messages': messages.map((m) => m.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
