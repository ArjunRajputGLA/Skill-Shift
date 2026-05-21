import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id; // maps to uid
  final String fullName;
  final String email;
  final String collegeName;
  final String branch;
  final String year;
  final List<String> skills;
  final List<String> interests;
  final String bio;
  final String whatsapp;
  final bool profileCompleted;
  final String? profileImageBase64;
  final String? fcmToken;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.collegeName = '',
    this.branch = '',
    this.year = '',
    this.skills = const [],
    this.interests = const [],
    this.bio = '',
    this.whatsapp = '',
    this.profileCompleted = false,
    this.profileImageBase64,
    this.fcmToken,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'fullName': fullName,
      'email': email,
      'collegeName': collegeName,
      'branch': branch,
      'year': year,
      'skills': skills,
      'interests': interests,
      'bio': bio,
      'whatsapp': whatsapp,
      'profileCompleted': profileCompleted,
      'profileImageBase64': profileImageBase64,
      'fcmToken': fcmToken,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      id: documentId,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      collegeName: map['collegeName'] ?? '',
      branch: map['branch'] ?? '',
      year: map['year'] ?? '',
      skills: List<String>.from(map['skills'] ?? []),
      interests: List<String>.from(map['interests'] ?? []),
      bio: map['bio'] ?? '',
      whatsapp: map['whatsapp'] ?? '',
      profileCompleted: map['profileCompleted'] ?? false,
      profileImageBase64: map['profileImageBase64'],
      fcmToken: map['fcmToken'],
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : null,
    );
  }
}
