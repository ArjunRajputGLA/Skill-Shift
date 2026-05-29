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
  final List<String> fileUrls;
  final List<String> fileTypes;
  final List<String> fileNames;
  final DateTime uploadTime;
  double averageRating;
  int totalRatings;
  int totalViews;
  int totalDownloads;
  int totalComments;

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
    this.fileUrl = '',
    this.fileType = '',
    this.fileUrls = const [],
    this.fileTypes = const [],
    this.fileNames = const [],
    required this.uploadTime,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.totalViews = 0,
    this.totalDownloads = 0,
    this.totalComments = 0,
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
      'fileUrls': fileUrls,
      'fileTypes': fileTypes,
      'fileNames': fileNames,
      'uploadTime': Timestamp.fromDate(uploadTime),
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'totalViews': totalViews,
      'totalDownloads': totalDownloads,
      'totalComments': totalComments,
    };
  }

  factory FarreyNoteModel.fromMap(Map<String, dynamic> map, String id) {
    // Migration: if fileUrls is empty but fileUrl is present, put it in the list.
    List<String> parsedUrls = List<String>.from(map['fileUrls'] ?? []);
    List<String> parsedTypes = List<String>.from(map['fileTypes'] ?? []);
    List<String> parsedNames = List<String>.from(map['fileNames'] ?? []);
    
    String legacyUrl = map['fileUrl'] ?? '';
    String legacyType = map['fileType'] ?? '';
    
    if (parsedUrls.isEmpty && legacyUrl.isNotEmpty) {
      parsedUrls = [legacyUrl];
      parsedTypes = [legacyType];
      parsedNames = ['Document.$legacyType'];
    }

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
      fileUrl: legacyUrl,
      fileType: legacyType,
      fileUrls: parsedUrls,
      fileTypes: parsedTypes,
      fileNames: parsedNames,
      uploadTime: (map['uploadTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      totalRatings: map['totalRatings'] ?? 0,
      totalViews: map['totalViews'] ?? 0,
      totalDownloads: map['totalDownloads'] ?? 0,
      totalComments: map['totalComments'] ?? 0,
    );
  }
}

class FarreyCommentModel {
  final String commentId;
  final String noteId;
  final String senderUid;
  final String senderName;
  final String? senderPhotoUrl;
  final String text;
  final DateTime timestamp;

  FarreyCommentModel({
    required this.commentId,
    required this.noteId,
    required this.senderUid,
    required this.senderName,
    this.senderPhotoUrl,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'commentId': commentId,
      'noteId': noteId,
      'senderUid': senderUid,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory FarreyCommentModel.fromMap(Map<String, dynamic> map, String id) {
    return FarreyCommentModel(
      commentId: id,
      noteId: map['noteId'] ?? '',
      senderUid: map['senderUid'] ?? '',
      senderName: map['senderName'] ?? 'Unknown User',
      senderPhotoUrl: map['senderPhotoUrl'],
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class FarreyReviewModel {
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final double rating;
  final String reviewText;
  final DateTime timestamp;
  final bool isEdited;

  FarreyReviewModel({
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.rating,
    required this.reviewText,
    required this.timestamp,
    this.isEdited = false,
  });

  factory FarreyReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return FarreyReviewModel(
      userId: id, // The document ID in the ratings subcollection is the userId
      userName: map['userName'] ?? 'Unknown User',
      userPhotoUrl: map['userPhotoUrl'],
      rating: (map['rating'] ?? 5.0).toDouble(),
      reviewText: map['review'] ?? '', // Old ratings will have empty review text
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isEdited: map['isEdited'] ?? false,
    );
  }
}
