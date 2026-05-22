import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SessionSlotModel {
  final String id;
  final String ownerUid;
  final String ownerName;
  final String title;
  final String topic;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  
  // Capacity and Merging
  final int maxParticipants;
  final List<String> participants;
  
  // Meeting Details
  final String meetingType; // e.g. 'Google Meet', 'Zoom', 'WhatsApp', 'Custom'
  final String? meetingLink;
  
  final String status; // 'scheduled', 'ongoing', 'completed', 'cancelled'

  // Legacy fields for backwards compatibility
  final bool booked;
  final String? bookedBy;
  
  final DateTime? createdAt;

  SessionSlotModel({
    required this.id,
    required this.ownerUid,
    required this.ownerName,
    required this.title,
    this.topic = '',
    required this.date,
    required this.startTime,
    required this.endTime,
    this.maxParticipants = 1,
    this.participants = const [],
    this.meetingType = 'Google Meet',
    this.meetingLink,
    this.status = 'scheduled',
    this.booked = false,
    this.bookedBy,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'ownerUid': ownerUid,
      'ownerName': ownerName,
      'title': title,
      'topic': topic,
      'date': Timestamp.fromDate(date),
      'startTime': '${startTime.hour}:${startTime.minute}',
      'endTime': '${endTime.hour}:${endTime.minute}',
      'maxParticipants': maxParticipants,
      'participants': participants,
      'meetingType': meetingType,
      'meetingLink': meetingLink,
      'status': status,
      'booked': booked,
      'bookedBy': bookedBy,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory SessionSlotModel.fromMap(Map<String, dynamic> map, String documentId) {
    final startParts = (map['startTime'] as String).split(':');
    final endParts = (map['endTime'] as String).split(':');

    DateTime parsedDate;
    if (map['date'] is Timestamp) {
      parsedDate = (map['date'] as Timestamp).toDate();
    } else if (map['date'] is String) {
      parsedDate = DateTime.tryParse(map['date'] as String) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    DateTime? parsedCreatedAt;
    if (map['createdAt'] is Timestamp) {
      parsedCreatedAt = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      parsedCreatedAt = DateTime.tryParse(map['createdAt'] as String);
    }

    return SessionSlotModel(
      id: documentId,
      ownerUid: map['ownerUid'] ?? '',
      ownerName: map['ownerName'] ?? '',
      title: map['title'] ?? '',
      topic: map['topic'] ?? '',
      date: parsedDate,
      startTime: TimeOfDay(hour: int.tryParse(startParts[0]) ?? 0, minute: int.tryParse(startParts[1]) ?? 0),
      endTime: TimeOfDay(hour: int.tryParse(endParts[0]) ?? 0, minute: int.tryParse(endParts[1]) ?? 0),
      maxParticipants: map['maxParticipants'] ?? 1,
      participants: List<String>.from(map['participants'] ?? []),
      meetingType: map['meetingType'] ?? 'Google Meet',
      meetingLink: map['meetingLink'],
      status: map['status'] ?? 'scheduled',
      booked: map['booked'] ?? false,
      bookedBy: map['bookedBy'],
      createdAt: parsedCreatedAt,
    );
  }
}
