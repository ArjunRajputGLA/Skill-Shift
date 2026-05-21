import 'package:cloud_firestore/cloud_firestore.dart';

enum MediaType { none, image, audio }

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime? timestamp;
  final bool read;
  final Map<String, List<String>> reactions;
  final String? replyTo;
  final String? mediaUrl;
  final MediaType mediaType;
  final int? audioDuration;
  final bool isEdited;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.timestamp,
    this.read = false,
    this.reactions = const {},
    this.replyTo,
    this.mediaUrl,
    this.mediaType = MediaType.none,
    this.audioDuration,
    this.isEdited = false,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    // Parse timestamp safely
    DateTime? parsedTimestamp;
    if (map['timestamp'] is Timestamp) {
      parsedTimestamp = (map['timestamp'] as Timestamp).toDate();
    }

    // Parse reactions map
    Map<String, List<String>> parsedReactions = {};
    if (map['reactions'] is Map) {
      final rawMap = map['reactions'] as Map;
      rawMap.forEach((key, value) {
        if (value is List) {
          parsedReactions[key.toString()] = List<String>.from(value);
        }
      });
    }

    // Parse mediaType
    MediaType parsedMediaType = MediaType.none;
    final String mtString = map['mediaType'] ?? 'none';
    if (mtString == 'image') parsedMediaType = MediaType.image;
    if (mtString == 'audio') parsedMediaType = MediaType.audio;

    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
      timestamp: parsedTimestamp,
      read: map['read'] ?? false,
      reactions: parsedReactions,
      replyTo: map['replyTo'],
      mediaUrl: map['mediaUrl'],
      mediaType: parsedMediaType,
      audioDuration: map['audioDuration'],
      isEdited: map['isEdited'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': timestamp == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(timestamp!),
      'read': read,
      'reactions': reactions,
    };

    if (replyTo != null) map['replyTo'] = replyTo!;
    if (mediaUrl != null) map['mediaUrl'] = mediaUrl!;
    if (mediaType != MediaType.none) {
      map['mediaType'] = mediaType.toString().split('.').last;
    }
    if (audioDuration != null) map['audioDuration'] = audioDuration!;
    if (isEdited) map['isEdited'] = true;

    return map;
  }
}
