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
  
  // Dynamic Role Fields
  final String userType;
  final String specialization;
  final String researchArea;
  final String organization;
  final String designation;
  final String experience;
  
  final bool whatsappVerified;
  final DateTime? verifiedAt;
  final bool notificationsEnabled;
  final bool profileCompleted;
  final String? profileImageBase64;
  final String? profileImageUrl;
  final String? fcmToken;
  final String authProvider;
  final DateTime? createdAt;
  final Map<String, bool> verifiedSkills;
  final Map<String, int> tagEndorsements;
  final Map<String, int> skillEndorsements;
  final double averageRating;
  final int reviewCount;

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
    this.userType = 'Bachelor\'s Student',
    this.specialization = '',
    this.researchArea = '',
    this.organization = '',
    this.designation = '',
    this.experience = '',
    this.whatsappVerified = false,
    this.verifiedAt,
    this.notificationsEnabled = true,
    this.profileCompleted = false,
    this.profileImageBase64,
    this.profileImageUrl,
    this.fcmToken,
    this.authProvider = 'email',
    this.createdAt,
    this.verifiedSkills = const {},
    this.tagEndorsements = const {},
    this.skillEndorsements = const {},
    this.averageRating = 0.0,
    this.reviewCount = 0,
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
      'userType': userType,
      'specialization': specialization,
      'researchArea': researchArea,
      'organization': organization,
      'designation': designation,
      'experience': experience,
      'whatsappVerified': whatsappVerified,
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'notificationsEnabled': notificationsEnabled,
      'profileCompleted': profileCompleted,
      'profileImageBase64': profileImageBase64,
      'profileImageUrl': profileImageUrl,
      'fcmToken': fcmToken,
      'authProvider': authProvider,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'verifiedSkills': verifiedSkills,
      'tagEndorsements': tagEndorsements,
      'skillEndorsements': skillEndorsements,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
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
      userType: map['userType'] ?? 'Bachelor\'s Student',
      specialization: map['specialization'] ?? '',
      researchArea: map['researchArea'] ?? '',
      organization: map['organization'] ?? '',
      designation: map['designation'] ?? '',
      experience: map['experience'] ?? '',
      whatsappVerified: map['whatsappVerified'] ?? false,
      verifiedAt: map['verifiedAt'] != null
          ? (map['verifiedAt'] as Timestamp).toDate()
          : null,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      profileCompleted: map['profileCompleted'] ?? (
        // If missing from DB, infer true if they have bio or skills
        (map['skills'] != null && (map['skills'] as List).isNotEmpty) || 
        (map['bio'] != null && map['bio'].toString().isNotEmpty)
      ),
      profileImageBase64: map['profileImageBase64'],
      profileImageUrl: map['profileImageUrl'],
      fcmToken: map['fcmToken'],
      authProvider: map['authProvider'] ?? 'email',
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : null,
      verifiedSkills: (map['verifiedSkills'] ?? {})
          .cast<String, dynamic>()
          .map<String, bool>((key, value) => MapEntry(key as String, value == true)),
      tagEndorsements: (map['tagEndorsements'] ?? map['endorsementCounts'] ?? {})
          .cast<String, dynamic>()
          .map<String, int>((key, value) => MapEntry(key as String, (value as num).toInt())),
      skillEndorsements: (map['skillEndorsements'] ?? {})
          .cast<String, dynamic>()
          .map<String, int>((key, value) => MapEntry(key as String, (value as num).toInt())),
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
    );
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? collegeName,
    String? branch,
    String? year,
    List<String>? skills,
    List<String>? interests,
    String? bio,
    String? whatsapp,
    bool? whatsappVerified,
    DateTime? verifiedAt,
    bool? notificationsEnabled,
    bool? profileCompleted,
    String? profileImageBase64,
    String? profileImageUrl,
    String? fcmToken,
    String? authProvider,
    DateTime? createdAt,
    Map<String, bool>? verifiedSkills,
    Map<String, int>? tagEndorsements,
    Map<String, int>? skillEndorsements,
    double? averageRating,
    int? reviewCount,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      collegeName: collegeName ?? this.collegeName,
      branch: branch ?? this.branch,
      year: year ?? this.year,
      skills: skills ?? this.skills,
      interests: interests ?? this.interests,
      bio: bio ?? this.bio,
      whatsapp: whatsapp ?? this.whatsapp,
      whatsappVerified: whatsappVerified ?? this.whatsappVerified,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      profileImageBase64: profileImageBase64 ?? this.profileImageBase64,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      authProvider: authProvider ?? this.authProvider,
      createdAt: createdAt ?? this.createdAt,
      verifiedSkills: verifiedSkills ?? this.verifiedSkills,
      tagEndorsements: tagEndorsements ?? this.tagEndorsements,
      skillEndorsements: skillEndorsements ?? this.skillEndorsements,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}
