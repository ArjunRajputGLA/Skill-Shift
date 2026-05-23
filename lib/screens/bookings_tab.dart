import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/notification_service.dart';
import '../models/booking_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/glass_card.dart';
import '../widgets/endorsement_dialog.dart';
import '../widgets/duolingo_button.dart';

class BookingsTab extends StatelessWidget {
  const BookingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(text: 'Sessions'),
              Tab(text: 'Requests'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _BookingListView(isRequests: false),
                _BookingListView(isRequests: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingListView extends StatelessWidget {
  final bool isRequests;
  const _BookingListView({required this.isRequests});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser!;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where(Filter.or(
            Filter('mentorUid', isEqualTo: user.id),
            Filter('studentUid', isEqualTo: user.id),
          ))
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data!.docs;
        
        final allBookings = docs.map((doc) => BookingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
        
        // Filter based on tab
        final requestStatuses = ['pending', 'rescheduled', 'rejected'];
        final filteredBookings = allBookings.where((b) {
          if (isRequests) {
            return requestStatuses.contains(b.status);
          } else {
            return !requestStatuses.contains(b.status);
          }
        }).toList();

        // Sort descending by created at
        filteredBookings.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));

        if (filteredBookings.isEmpty) {
          return Center(child: Text(isRequests ? 'No pending requests.' : 'No sessions found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100, top: AppSpacing.md),
          itemCount: filteredBookings.length,
          itemBuilder: (context, index) {
            final booking = filteredBookings[index];
            return _BookingCard(booking: booking, currentUserId: user.id);
          },
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final String currentUserId;

  const _BookingCard({required this.booking, required this.currentUserId});

  Color _getStatusColor() {
    switch (booking.status) {
      case 'accepted':
      case 'completed':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
      case 'missed':
        return Colors.red;
      case 'pending':
      case 'rescheduled':
      default:
        return Colors.orange;
    }
  }

  void _showRejectDialog(BuildContext context, String bookingId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Session Request'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Reason (Mandatory)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                NotificationService.showError(ctx, 'Reason is required');
                return;
              }
              await BookingService().rejectBooking(bookingId, reasonController.text);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showSuggestTimeDialog(BuildContext context, String bookingId) {
    final remarkController = TextEditingController();
    DateTime? selectedDate = booking.date ?? DateTime.now();
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Suggest Different Time'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Date'),
                  subtitle: Text('${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate!,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (date != null) setState(() => selectedDate = date);
                  },
                ),
                ListTile(
                  title: const Text('Time'),
                  subtitle: Text(selectedTime?.format(context) ?? 'Select Time'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    if (time != null) setState(() => selectedTime = time);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: remarkController,
                  decoration: const InputDecoration(labelText: 'Remark (Optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (selectedTime == null) {
                  NotificationService.showError(ctx, 'Time is required');
                  return;
                }
                final timeString = '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
                await BookingService().suggestTime(bookingId, selectedDate!, timeString, remarkController.text);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Suggest'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletionDialog(BuildContext context, String bookingId, bool isMentor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Session Completion'),
        content: const Text('Did this session happen successfully?'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await BookingService().updateBookingStatus(bookingId, 'missed');
            },
            child: const Text('No, it was missed', style: TextStyle(color: Colors.red)),
          ),
          SizedBox(
            width: 160,
            child: DuolingoButton(
              title: 'Yes, it happened',
              color: AppColors.successGreen,
              onPressed: () async {
                Navigator.pop(ctx);
                await BookingService().confirmSessionCompletion(bookingId, isMentor);
                if (ctx.mounted && !isMentor) {
                  // Unlock endorsements for student
                  showModalBottomSheet(
                    context: ctx,
                    builder: (_) => EndorsementDialog(
                      sessionId: bookingId,
                      mentorUid: booking.mentorUid,
                      mentorName: 'Mentor', // Ideally fetched
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMentor = currentUserId == booking.mentorUid;
    final dateStr = booking.date != null ? '${booking.date!.day}/${booking.date!.month}/${booking.date!.year}' : 'TBD';
    final timeStr = booking.startTime ?? 'TBD';
    
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  booking.topic.isNotEmpty ? booking.topic : 'Session Request',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Chip(
                label: Text(booking.status.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                backgroundColor: _getStatusColor().withValues(alpha: 0.2),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('${isMentor ? "Student" : "Mentor"}: ${isMentor ? booking.studentUid.substring(0, 5) : booking.mentorUid.substring(0, 5)}...'), // Shortened ID for mockup
          const SizedBox(height: 4),
          Text('$dateStr • $timeStr • ${booking.durationMinutes} mins', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          if (booking.purpose.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Purpose: ${booking.purpose}', style: const TextStyle(fontSize: 13)),
          ],
          if (booking.cancelReason != null) ...[
            const SizedBox(height: 8),
            Text('Reason: ${booking.cancelReason}', style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ],
          if (booking.remark != null && booking.status == 'rescheduled') ...[
            const SizedBox(height: 8),
            Text('Remark: ${booking.remark}', style: const TextStyle(color: Colors.orange, fontSize: 13)),
          ],
          const SizedBox(height: AppSpacing.md),

          // ACTIONS
          if (booking.status == 'pending' && isMentor) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showSuggestTimeDialog(context, booking.id),
                    child: const Text('Suggest Time'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DuolingoButton(
                    title: 'Accept',
                    color: AppColors.successGreen,
                    onPressed: () async {
                      final name = context.read<AuthService>().currentUser?.fullName ?? 'Mentor';
                      await BookingService().acceptBooking(booking, name);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => _showRejectDialog(context, booking.id),
                child: const Text('Reject Request', style: TextStyle(color: Colors.red)),
              ),
            ),
          ] else if (booking.status == 'rescheduled' && !isMentor) ...[
            OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () async {
                    await BookingService().cancelBooking(booking.id, 'Student declined suggested time');
                  },
                  child: const Text('Decline', style: TextStyle(color: Colors.red)),
                ),
                SizedBox(
                  width: 160,
                  child: DuolingoButton(
                    title: 'Accept New Time',
                    color: AppColors.successGreen,
                    onPressed: () async {
                      final name = context.read<AuthService>().currentUser?.fullName ?? 'Student';
                      await BookingService().studentAcceptNewTime(booking, 'Mentor'); // Mentor name would ideally be fetched
                    },
                  ),
                ),
              ],
            ),
          ] else if (booking.status == 'accepted' || booking.status == 'ongoing') ...[
            OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 8,
              children: [
                if (isMentor)
                  OutlinedButton(
                    onPressed: () async {
                      // Mark Attendance logic here (mocked for simplicity to just mark present)
                      await BookingService().markAttendance(booking.id, 'Present');
                      NotificationService.showSuccess(context, 'Attendance marked Present');
                    },
                    child: const Text('Mark Present'),
                  ),
                SizedBox(
                  width: 160,
                  child: DuolingoButton(
                    title: isMentor 
                      ? (booking.mentorConfirmed ? 'Confirmed' : 'Confirm Done') 
                      : (booking.studentConfirmed ? 'Confirmed' : 'Confirm Done'),
                    color: AppColors.primary,
                    onPressed: () {
                      final hasConfirmed = isMentor ? booking.mentorConfirmed : booking.studentConfirmed;
                      if (hasConfirmed) {
                        NotificationService.showSuccess(context, 'You have already confirmed this session.');
                        return;
                      }
                      _showCompletionDialog(context, booking.id, isMentor);
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
