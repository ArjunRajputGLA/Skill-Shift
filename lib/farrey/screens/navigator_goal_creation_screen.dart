import 'package:flutter/material.dart';
import '../services/navigator_service.dart';
import '../theme/farrey_colors.dart';

class NavigatorGoalCreationScreen extends StatefulWidget {
  const NavigatorGoalCreationScreen({super.key});

  @override
  State<NavigatorGoalCreationScreen> createState() => _NavigatorGoalCreationScreenState();
}

class _NavigatorGoalCreationScreenState extends State<NavigatorGoalCreationScreen> {
  final NavigatorService _navigatorService = NavigatorService();
  final TextEditingController _goalController = TextEditingController();
  
  String _selectedLevel = 'Beginner';
  String _selectedHours = '1 hr/day';
  DateTime? _targetDate;
  bool _isLoading = false;

  final List<String> _levels = ['Beginner', 'Intermediate', 'Advanced'];
  final List<String> _hours = ['1 hr/day', '2 hrs/day', '4 hrs/day', 'Custom'];

  void _generatePlan() async {
    if (_goalController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a goal', style: TextStyle(color: context.farreyError))));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _navigatorService.generateNavigatorPlan(
        goalTitle: _goalController.text.trim(),
        currentLevel: _selectedLevel,
        availableHours: _selectedHours,
        targetDate: _targetDate,
      );
      
      if (mounted) {
        Navigator.of(context).pop(); // Go back to dashboard/home which will now show the active plan
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e', style: TextStyle(color: context.farreyError))));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: context.farreyPrimary,
              onPrimary: context.farreyBackground,
              surface: context.farreySurface,
              onSurface: context.farreyTextPrimary,
            ),
            dialogBackgroundColor: context.farreyBackground,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _targetDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.farreyBackground,
      appBar: AppBar(
        backgroundColor: context.farreyBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: context.farreyTextPrimary),
        title: Text('Create AI Journey', style: TextStyle(color: context.farreyTextPrimary)),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: context.farreyPrimary),
                  const SizedBox(height: 16),
                  Text('Gemini AI is crafting your roadmap...', style: TextStyle(color: context.farreyTextSecondary)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 100.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What do you want to learn?', style: TextStyle(color: context.farreyTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _goalController,
                    style: TextStyle(color: context.farreyTextPrimary),
                    decoration: InputDecoration(
                      hintText: 'e.g. Master Flutter, Crack DBMS Exam',
                      hintStyle: TextStyle(color: context.farreyTextSecondary),
                      filled: true,
                      fillColor: context.farreySurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  Text('Current Level', style: TextStyle(color: context.farreyTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    children: _levels.map((level) {
                      final isSelected = _selectedLevel == level;
                      return ChoiceChip(
                        label: Text(level),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedLevel = level);
                        },
                        selectedColor: context.farreyPrimary.withValues(alpha: 0.2),
                        backgroundColor: context.farreySurface,
                        labelStyle: TextStyle(color: isSelected ? context.farreyPrimary : context.farreyTextSecondary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: isSelected ? context.farreyPrimary : context.farreyBorder),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  Text('Available Study Time', style: TextStyle(color: context.farreyTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    children: _hours.map((hour) {
                      final isSelected = _selectedHours == hour;
                      return ChoiceChip(
                        label: Text(hour),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedHours = hour);
                        },
                        selectedColor: context.farreyPrimary.withValues(alpha: 0.2),
                        backgroundColor: context.farreySurface,
                        labelStyle: TextStyle(color: isSelected ? context.farreyPrimary : context.farreyTextSecondary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: isSelected ? context.farreyPrimary : context.farreyBorder),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  Text('Target Date (Optional)', style: TextStyle(color: context.farreyTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: context.farreySurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.farreyBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: context.farreyPrimary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _targetDate != null ? "${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}" : 'Select a date',
                              style: TextStyle(color: _targetDate != null ? context.farreyTextPrimary : context.farreyTextSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _generatePlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.farreyPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Generate Journey', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
