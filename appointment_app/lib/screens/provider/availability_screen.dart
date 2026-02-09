import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/provider_service.dart';
import '../../config/theme.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final List<String> _days = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  final Map<int, Map<String, dynamic>> _schedule = {};

  @override
  void initState() {
    super.initState();
    // Initialize default schedule
    for (int i = 0; i < 7; i++) {
      _schedule[i] = {
        'is_active': i >= 1 && i <= 5, // Mon-Fri active by default
        'start_time': '09:00',
        'end_time': '18:00',
        'slot_duration': 30,
      };
    }
    
    Future.microtask(() async {
      await Provider.of<ProviderService>(context, listen: false).fetchAvailability();
      _loadExistingSchedule();
    });
  }

  void _loadExistingSchedule() {
    final availability = Provider.of<ProviderService>(context, listen: false).availability;
    for (var slot in availability) {
      final dayOfWeek = slot['day_of_week'] as int;
      _schedule[dayOfWeek] = {
        'is_active': slot['is_active'] == true || slot['is_active'] == 1,
        'start_time': slot['start_time']?.toString().substring(0, 5) ?? '09:00',
        'end_time': slot['end_time']?.toString().substring(0, 5) ?? '18:00',
        'slot_duration': slot['slot_duration'] ?? 30,
      };
    }
    setState(() {});
  }

  Future<void> _saveSchedule() async {
    final provider = Provider.of<ProviderService>(context, listen: false);
    
    for (int i = 0; i < 7; i++) {
      await provider.setAvailability({
        'day_of_week': i,
        'start_time': _schedule[i]!['start_time'],
        'end_time': _schedule[i]!['end_time'],
        'slot_duration': _schedule[i]!['slot_duration'],
        'is_active': _schedule[i]!['is_active'],
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schedule saved successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _selectTime(int dayIndex, bool isStart) async {
    final currentTime = _schedule[dayIndex]![isStart ? 'start_time' : 'end_time'] as String;
    final parts = currentTime.split(':');
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
    );

    if (picked != null) {
      setState(() {
        final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        _schedule[dayIndex]![isStart ? 'start_time' : 'end_time'] = timeStr;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Availability'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Save'),
            onPressed: _saveSchedule,
          ),
        ],
      ),
      body: Consumer<ProviderService>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 7,
            itemBuilder: (context, index) {
              final schedule = _schedule[index]!;
              final isActive = schedule['is_active'] as bool;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _days[index],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Switch(
                            value: isActive,
                            activeColor: AppTheme.primaryColor,
                            onChanged: (value) {
                              setState(() {
                                _schedule[index]!['is_active'] = value;
                              });
                            },
                          ),
                        ],
                      ),
                      if (isActive) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectTime(index, true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white24),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.access_time, size: 18),
                                      const SizedBox(width: 8),
                                      Text(schedule['start_time']),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('to'),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectTime(index, false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white24),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.access_time, size: 18),
                                      const SizedBox(width: 8),
                                      Text(schedule['end_time']),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('Slot Duration: '),
                            const SizedBox(width: 8),
                            DropdownButton<int>(
                              value: schedule['slot_duration'] as int,
                              items: [15, 30, 45, 60, 90, 120].map((mins) {
                                return DropdownMenuItem(
                                  value: mins,
                                  child: Text('$mins mins'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _schedule[index]!['slot_duration'] = value!;
                                });
                              },
                            ),
                          ],
                        ),
                      ] else
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Closed',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
