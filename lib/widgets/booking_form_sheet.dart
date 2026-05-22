import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/notification_service.dart';
import '../models/booking_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class BookingFormSheet extends StatefulWidget {
  final String mentorUid;
  final String mentorName;

  const BookingFormSheet({
    super.key,
    required this.mentorUid,
    required this.mentorName,
  });

  @override
  State<BookingFormSheet> createState() => _BookingFormSheetState();
}

class _BookingFormSheetState extends State<BookingFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  final _purposeController = TextEditingController();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _selectedDuration = 60; // default 60 mins

  final List<int> _durationOptions = [15, 30, 45, 60, 90, 120];
  bool _isLoading = false;

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      NotificationService.showError(context, 'Please select a preferred date');
      return;
    }
    if (_selectedTime == null) {
      NotificationService.showError(context, 'Please select a preferred time');
      return;
    }

    setState(() => _isLoading = true);
    
    final currentUser = context.read<AuthService>().currentUser;
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Format time to HH:mm
    final timeString = '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

    final request = BookingModel(
      id: '', // Generated in service
      sessionId: '', // Generated upon merge or acceptance
      mentorUid: widget.mentorUid,
      studentUid: currentUser.id,
      status: 'pending',
      topic: _topicController.text.trim(),
      purpose: _purposeController.text.trim(),
      date: _selectedDate,
      startTime: timeString,
      durationMinutes: _selectedDuration,
    );

    final error = await BookingService().requestSession(request);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null) {
        NotificationService.showError(context, error);
      } else {
        NotificationService.showSuccess(context, 'Session requested successfully!');
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: bottomInset > 0 ? bottomInset + AppSpacing.md : AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Request Session with ${widget.mentorName}',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              TextFormField(
                controller: _topicController,
                decoration: const InputDecoration(
                  labelText: 'Topic / Category',
                  hintText: 'e.g., Flutter Basics',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              
              TextFormField(
                controller: _purposeController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Purpose of Session',
                  hintText: 'What do you want to learn or discuss?',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.lg),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_rounded, size: 18),
                      label: Text(_selectedDate == null 
                          ? 'Select Date' 
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (date != null) {
                          setState(() => _selectedDate = date);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time_rounded, size: 18),
                      label: Text(_selectedTime == null ? 'Select Time' : _selectedTime!.format(context)),
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() => _selectedTime = time);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              DropdownButtonFormField<int>(
                value: _selectedDuration,
                decoration: const InputDecoration(labelText: 'Duration'),
                items: _durationOptions.map((mins) {
                  return DropdownMenuItem(
                    value: mins,
                    child: Text('$mins minutes' + (mins == 120 ? ' (Max)' : '')),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedDuration = val);
                },
              ),
              const SizedBox(height: AppSpacing.xxxl),

              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Send Request', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
