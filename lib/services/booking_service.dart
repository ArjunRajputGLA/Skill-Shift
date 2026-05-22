import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/session_slot_model.dart';
import '../models/booking_model.dart';
import '../services/notification_service.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Student requests a new session.
  /// Handles merging logic if an identical overlapping session exists.
  Future<String?> requestSession(BookingModel request) async {
    try {
      QuerySnapshot sessionsSnapshot = await _firestore.collection('sessionSlots')
          .where('ownerUid', isEqualTo: request.mentorUid)
          .where('topic', isEqualTo: request.topic)
          .get();
          
      String? mergeSessionId;
      
      for (var doc in sessionsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final session = SessionSlotModel.fromMap(data, doc.id);
        
        if (request.date != null && 
            session.date.year == request.date!.year &&
            session.date.month == request.date!.month &&
            session.date.day == request.date!.day) {
            
            if (session.participants.length < session.maxParticipants) {
                final requestStartParts = request.startTime!.split(':');
                final requestStart = TimeOfDay(hour: int.parse(requestStartParts[0]), minute: int.parse(requestStartParts[1]));
                
                if (session.startTime.hour == requestStart.hour && session.startTime.minute == requestStart.minute) {
                    mergeSessionId = session.id;
                    break;
                }
            }
        }
      }
      
      final bookingRef = _firestore.collection('bookings').doc();
      
      if (mergeSessionId != null) {
        final sessionRef = _firestore.collection('sessionSlots').doc(mergeSessionId);
        await _firestore.runTransaction((transaction) async {
            final snapshot = await transaction.get(sessionRef);
            if (!snapshot.exists) throw Exception("Session vanished");
            final sessionData = snapshot.data()!;
            List<String> participants = List<String>.from(sessionData['participants'] ?? []);
            
            if (participants.length < (sessionData['maxParticipants'] ?? 1)) {
                participants.add(request.studentUid);
                transaction.update(sessionRef, {
                    'participants': participants,
                    'booked': true,
                });
                
                final acceptedRequest = BookingModel(
                  id: bookingRef.id,
                  sessionId: mergeSessionId!,
                  mentorUid: request.mentorUid,
                  studentUid: request.studentUid,
                  status: 'accepted',
                  topic: request.topic,
                  purpose: request.purpose,
                  date: request.date,
                  startTime: request.startTime,
                  durationMinutes: request.durationMinutes,
                );
                transaction.set(bookingRef, acceptedRequest.toMap());
            } else {
                // Fallback: create pending if it filled up instantly
                transaction.set(bookingRef, request.toMap());
            }
        });
      } else {
        await bookingRef.set(request.toMap());
      }
      
      await NotificationService.createNotification(
        receiverUid: request.mentorUid,
        type: 'session',
        title: 'New Session Request',
        body: 'A student requested a session on ${request.topic}',
        payload: {'bookingId': bookingRef.id},
      );

      return null;
    } catch (e) {
      print('Error requesting session: $e');
      return 'Failed to request session: $e';
    }
  }

  /// Mentor accepts a pending booking.
  /// Creates a SessionSlot and links it to the booking.
  Future<String?> acceptBooking(BookingModel booking, String mentorName, {int maxParticipants = 1}) async {
    try {
      final sessionRef = _firestore.collection('sessionSlots').doc();
      final bookingRef = _firestore.collection('bookings').doc(booking.id);

      final startParts = booking.startTime!.split(':');
      final startTime = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
      
      final endTotalMinutes = startTime.hour * 60 + startTime.minute + booking.durationMinutes;
      final endTime = TimeOfDay(hour: endTotalMinutes ~/ 60, minute: endTotalMinutes % 60);

      final newSession = SessionSlotModel(
        id: sessionRef.id,
        ownerUid: booking.mentorUid,
        ownerName: mentorName,
        title: booking.topic,
        topic: booking.topic,
        date: booking.date ?? DateTime.now(),
        startTime: startTime,
        endTime: endTime,
        maxParticipants: maxParticipants,
        participants: [booking.studentUid],
        status: 'scheduled',
        booked: true,
      );

      await _firestore.runTransaction((transaction) async {
        transaction.set(sessionRef, newSession.toMap());
        transaction.update(bookingRef, {
          'status': 'accepted',
          'sessionId': sessionRef.id,
        });
      });

      await NotificationService.createNotification(
        receiverUid: booking.studentUid,
        type: 'session',
        title: 'Session Accepted!',
        body: 'Your session on ${booking.topic} has been accepted.',
        payload: {'bookingId': booking.id, 'sessionId': sessionRef.id},
      );

      return null;
    } catch (e) {
      return 'Failed to accept booking: $e';
    }
  }

  /// Mentor rejects a booking.
  Future<String?> rejectBooking(String bookingId, String reason) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'rejected',
        'cancelReason': reason,
      });

      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (doc.exists) {
        final data = doc.data()!;
        await NotificationService.createNotification(
          receiverUid: data['studentUid'],
          type: 'session',
          title: 'Session Request Declined',
          body: 'Your request for ${data['topic']} was declined. Reason: ${reason.isNotEmpty ? reason : "Not specified"}',
          payload: {'bookingId': bookingId},
        );
      }

      return null;
    } catch (e) {
      return 'Failed to reject booking.';
    }
  }

  /// Mentor suggests a different time.
  Future<String?> suggestTime(String bookingId, DateTime newDate, String newTime, String remark) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'rescheduled',
        'date': Timestamp.fromDate(newDate),
        'startTime': newTime,
        'remark': remark,
      });

      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (doc.exists) {
        final data = doc.data()!;
        await NotificationService.createNotification(
          receiverUid: data['studentUid'],
          type: 'session',
          title: 'Session Rescheduled',
          body: 'Your mentor suggested a new time for ${data['topic']}. Please review.',
          payload: {'bookingId': bookingId},
        );
      }

      return null;
    } catch (e) {
      return 'Failed to suggest new time.';
    }
  }

  /// Student accepts the suggested time.
  Future<String?> studentAcceptNewTime(BookingModel booking, String mentorName) async {
    final error = await acceptBooking(booking, mentorName);
    if (error == null) {
      await NotificationService.createNotification(
        receiverUid: booking.mentorUid,
        type: 'session',
        title: 'Reschedule Accepted',
        body: 'The student accepted your new time for ${booking.topic}.',
        payload: {'bookingId': booking.id},
      );
    }
    return error;
  }

  /// Student rejects the suggested time (cancels).
  Future<String?> cancelBooking(String bookingId, String reason) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'cancelled',
        'cancelReason': reason,
      });
      return null;
    } catch (e) {
      return 'Failed to cancel booking.';
    }
  }

  /// Update generic booking status (e.g. for missed sessions)
  Future<String?> updateBookingStatus(String bookingId, String status) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({'status': status});
      return null;
    } catch (e) {
      return 'Failed to update booking status.';
    }
  }

  /// Mark attendance (mentor only)
  Future<String?> markAttendance(String bookingId, String status) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'attendanceStatus': status,
      });
      return null;
    } catch (e) {
      return 'Failed to mark attendance.';
    }
  }

  /// Confirm session happened (both users)
  Future<String?> confirmSessionCompletion(String bookingId, bool isMentor) async {
    try {
      final updateData = isMentor ? {'mentorConfirmed': true} : {'studentConfirmed': true};
      
      await _firestore.runTransaction((transaction) async {
        final bookingRef = _firestore.collection('bookings').doc(bookingId);
        final snapshot = await transaction.get(bookingRef);
        if (!snapshot.exists) return;

        transaction.update(bookingRef, updateData);
        
        final data = snapshot.data()!;
        final mentorConfirmed = isMentor ? true : (data['mentorConfirmed'] ?? false);
        final studentConfirmed = !isMentor ? true : (data['studentConfirmed'] ?? false);
        
        if (mentorConfirmed && studentConfirmed) {
          transaction.update(bookingRef, {'status': 'completed'});
        }
      });
      return null;
    } catch (e) {
      return 'Failed to confirm session.';
    }
  }
}
