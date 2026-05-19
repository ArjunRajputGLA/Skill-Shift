import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String uid;
  final String userName;
  final String branch;
  final String year;
  final String postType;
  final String title;
  final String description;
  final List<String> tags;
  final String availability;
  final DateTime? createdAt;

  PostModel({
    required this.id,
    required this.uid,
    required this.userName,
    required this.branch,
    required this.year,
    required this.postType,
    required this.title,
    required this.description,
    required this.tags,
    this.availability = '',
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'userName': userName,
      'branch': branch,
      'year': year,
      'postType': postType,
      'title': title,
      'description': description,
      'tags': tags,
      'availability': availability,
      // Use FieldValue.serverTimestamp() when creating locally
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PostModel(
      id: documentId,
      uid: map['uid'] ?? '',
      userName: map['userName'] ?? '',
      branch: map['branch'] ?? '',
      year: map['year'] ?? '',
      postType: map['postType'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      availability: map['availability'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
