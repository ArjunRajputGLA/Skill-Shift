import 'package:cloud_firestore/cloud_firestore.dart';

class FarreyNavigatorModel {
  final String navigatorId;
  final String uid;
  final String goalTitle;
  final String currentLevel; // Beginner, Intermediate, Advanced
  final String availableHours; // 1 hr/day, 2 hrs/day, 4 hrs/day, Custom
  final DateTime? targetDate;
  final double progress; // 0.0 to 1.0
  final String status; // active, completed
  final DateTime createdAt;
  final int streakDays;

  FarreyNavigatorModel({
    required this.navigatorId,
    required this.uid,
    required this.goalTitle,
    required this.currentLevel,
    required this.availableHours,
    this.targetDate,
    this.progress = 0.0,
    this.status = 'active',
    required this.createdAt,
    this.streakDays = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'navigatorId': navigatorId,
      'uid': uid,
      'goalTitle': goalTitle,
      'currentLevel': currentLevel,
      'availableHours': availableHours,
      'targetDate': targetDate != null ? Timestamp.fromDate(targetDate!) : null,
      'progress': progress,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'streakDays': streakDays,
    };
  }

  factory FarreyNavigatorModel.fromMap(Map<String, dynamic> map, String id) {
    return FarreyNavigatorModel(
      navigatorId: id,
      uid: map['uid'] ?? '',
      goalTitle: map['goalTitle'] ?? '',
      currentLevel: map['currentLevel'] ?? 'Beginner',
      availableHours: map['availableHours'] ?? '1 hr/day',
      targetDate: map['targetDate'] != null ? (map['targetDate'] as Timestamp).toDate() : null,
      progress: (map['progress'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'active',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      streakDays: map['streakDays'] ?? 0,
    );
  }
}

class FarreyRoadmapModel {
  final String roadmapId;
  final String navigatorId;
  final String title;
  final String description;
  final int order;
  final bool completed;
  final String estimatedHours;

  FarreyRoadmapModel({
    required this.roadmapId,
    required this.navigatorId,
    required this.title,
    required this.description,
    required this.order,
    this.completed = false,
    required this.estimatedHours,
  });

  Map<String, dynamic> toMap() {
    return {
      'roadmapId': roadmapId,
      'navigatorId': navigatorId,
      'title': title,
      'description': description,
      'order': order,
      'completed': completed,
      'estimatedHours': estimatedHours,
    };
  }

  factory FarreyRoadmapModel.fromMap(Map<String, dynamic> map, String id) {
    return FarreyRoadmapModel(
      roadmapId: id,
      navigatorId: map['navigatorId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      order: map['order'] ?? 0,
      completed: map['completed'] ?? false,
      estimatedHours: map['estimatedHours'] ?? '1 hour',
    );
  }
}

class FarreyTaskModel {
  final String taskId;
  final String navigatorId;
  final String roadmapId;
  final String title;
  final DateTime date;
  final bool completed;
  final String estimatedTime;
  final String type; // e.g. "read", "quiz", "flashcard", "practice"

  FarreyTaskModel({
    required this.taskId,
    required this.navigatorId,
    required this.roadmapId,
    required this.title,
    required this.date,
    this.completed = false,
    required this.estimatedTime,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'navigatorId': navigatorId,
      'roadmapId': roadmapId,
      'title': title,
      'date': Timestamp.fromDate(date),
      'completed': completed,
      'estimatedTime': estimatedTime,
      'type': type,
    };
  }

  factory FarreyTaskModel.fromMap(Map<String, dynamic> map, String id) {
    return FarreyTaskModel(
      taskId: id,
      navigatorId: map['navigatorId'] ?? '',
      roadmapId: map['roadmapId'] ?? '',
      title: map['title'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completed: map['completed'] ?? false,
      estimatedTime: map['estimatedTime'] ?? '30 mins',
      type: map['type'] ?? 'practice',
    );
  }
}
