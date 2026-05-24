import 'package:cloud_firestore/cloud_firestore.dart';

class FarreyNoteModel {
  final String noteId;
  final String uploaderUid;
  final String uploaderName;
  final String title;
  final String description;
  final String subject;
  final String semester;
  final List<String> tags;
  final String branch;
  final String fileUrl;
  final String fileType;
  final DateTime uploadTime;
  final double averageRating;
  final int totalRatings;
  final int totalViews;
  final int totalDownloads;

  FarreyNoteModel({
    required this.noteId,
    required this.uploaderUid,
    required this.uploaderName,
    required this.title,
    required this.description,
    required this.subject,
    required this.semester,
    required this.tags,
    required this.branch,
    required this.fileUrl,
    required this.fileType,
    required this.uploadTime,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.totalViews = 0,
    this.totalDownloads = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'noteId': noteId,
      'uploaderUid': uploaderUid,
      'uploaderName': uploaderName,
      'title': title,
      'description': description,
      'subject': subject,
      'semester': semester,
      'tags': tags,
      'branch': branch,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'uploadTime': Timestamp.fromDate(uploadTime),
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'totalViews': totalViews,
      'totalDownloads': totalDownloads,
    };
  }

  factory FarreyNoteModel.fromMap(Map<String, dynamic> map, String id) {
    return FarreyNoteModel(
      noteId: id,
      uploaderUid: map['uploaderUid'] ?? '',
      uploaderName: map['uploaderName'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      subject: map['subject'] ?? '',
      semester: map['semester'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      branch: map['branch'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileType: map['fileType'] ?? '',
      uploadTime: (map['uploadTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      totalRatings: map['totalRatings'] ?? 0,
      totalViews: map['totalViews'] ?? 0,
      totalDownloads: map['totalDownloads'] ?? 0,
    );
  }
}

class FarreyCommentModel {
  final String commentId;
  final String noteId;
  final String senderUid;
  final String text;
  final DateTime timestamp;

  FarreyCommentModel({
    required this.commentId,
    required this.noteId,
    required this.senderUid,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'commentId': commentId,
      'noteId': noteId,
      'senderUid': senderUid,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory FarreyCommentModel.fromMap(Map<String, dynamic> map, String id) {
    return FarreyCommentModel(
      commentId: id,
      noteId: map['noteId'] ?? '',
      senderUid: map['senderUid'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
