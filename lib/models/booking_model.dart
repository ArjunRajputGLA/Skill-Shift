import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String sessionId;
  final String mentorUid;
  final String studentUid;
  
  // Status: pending, accepted, rescheduled, rejected, ongoing, completed, cancelled, missed
  final String status; 
  final String? remark;
  
  // Session Request Details
  final String topic;
  final String purpose;
  final DateTime? date;
  final String? startTime; // "HH:mm"
  final int durationMinutes;
  
  // Mentor / Student Workflow data
  final String? cancelReason;
  final String? attendanceStatus; // 'Present', 'Absent'
  final bool mentorConfirmed;
  final bool studentConfirmed;

  final DateTime? createdAt;

  BookingModel({
    required this.id,
    required this.sessionId,
    required this.mentorUid,
    required this.studentUid,
    this.status = 'pending',
    this.remark,
    this.topic = '',
    this.purpose = '',
    this.date,
    this.startTime,
    this.durationMinutes = 60,
    this.cancelReason,
    this.attendanceStatus,
    this.mentorConfirmed = false,
    this.studentConfirmed = false,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'mentorUid': mentorUid,
      'studentUid': studentUid,
      'status': status,
      'remark': remark,
      'topic': topic,
      'purpose': purpose,
      'date': date != null ? Timestamp.fromDate(date!) : null,
      'startTime': startTime,
      'durationMinutes': durationMinutes,
      'cancelReason': cancelReason,
      'attendanceStatus': attendanceStatus,
      'mentorConfirmed': mentorConfirmed,
      'studentConfirmed': studentConfirmed,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map, String documentId) {
    return BookingModel(
      id: documentId,
      sessionId: map['sessionId'] ?? '',
      mentorUid: map['mentorUid'] ?? '',
      studentUid: map['studentUid'] ?? '',
      status: map['status'] ?? 'pending',
      remark: map['remark'],
      topic: map['topic'] ?? '',
      purpose: map['purpose'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate(),
      startTime: map['startTime'],
      durationMinutes: map['durationMinutes'] ?? 60,
      cancelReason: map['cancelReason'],
      attendanceStatus: map['attendanceStatus'],
      mentorConfirmed: map['mentorConfirmed'] ?? false,
      studentConfirmed: map['studentConfirmed'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
