import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/schedule_model.dart';
import '../../services/schedule_service.dart';
import '../../utils/constants.dart';

class ManageScheduleScreen extends StatefulWidget {
  const ManageScheduleScreen({Key? key}) : super(key: key);

  @override
  State<ManageScheduleScreen> createState() => _ManageScheduleScreenState();
}

class _ManageScheduleScreenState extends State<ManageScheduleScreen> {
  final ScheduleService _scheduleService = ScheduleService();
  String? selectedMajor;
  String? selectedBatch;
  String? selectedConcentration;
  String? selectedClass;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Schedules'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddScheduleDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Schedule'),
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    // Major Dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Major',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedMajor,
                        items: AppConstants.majors.map((major) {
                          return DropdownMenuItem(
                            value: major,
                            child: Text(major, style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedMajor = value;
                            selectedBatch = null;
                            selectedConcentration = null;
                            selectedClass = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Batch Dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Batch',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedBatch,
                        items: selectedMajor == null
                            ? []
                            : AppConstants.batches.map((batch) {
                                return DropdownMenuItem(
                                  value: batch,
                                  child: Text(batch),
                                );
                              }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedBatch = value;
                            selectedConcentration = null;
                            selectedClass = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Concentration Dropdown (Optional)
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Concentration (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedConcentration,
                        items: selectedMajor == null
                            ? []
                            : [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('All'),
                                ),
                                ...AppConstants.getConcentrationsForMajor(
                                        selectedMajor!)
                                    .map((concentration) {
                                  return DropdownMenuItem(
                                    value: concentration,
                                    child: Text(
                                      concentration,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  );
                                }),
                              ],
                        onChanged: (value) {
                          setState(() => selectedConcentration = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Class Dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Class',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedClass,
                        items: selectedBatch == null
                            ? []
                            : AppConstants.classes.map((classCode) {
                                return DropdownMenuItem(
                                  value: classCode,
                                  child: Text('Class $classCode'),
                                );
                              }).toList(),
                        onChanged: (value) {
                          setState(() => selectedClass = value);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Schedule List
          Expanded(
            child: selectedMajor == null ||
                    selectedBatch == null ||
                    selectedClass == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_list,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select major, batch, and class\nto view schedules',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : StreamBuilder<List<ScheduleModel>>(
                    stream: _scheduleService.getSchedulesByFilter(
                      selectedMajor!,
                      selectedBatch!,
                      selectedClass!,
                      selectedConcentration,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No schedules yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () => _showAddScheduleDialog(),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Schedule'),
                              ),
                            ],
                          ),
                        );
                      }

                      final schedules = snapshot.data!;
                      // Group by day
                      final schedulesByDay = <String, List<ScheduleModel>>{};
                      for (var schedule in schedules) {
                        schedulesByDay.putIfAbsent(
                          schedule.dayOfWeek,
                          () => [],
                        );
                        schedulesByDay[schedule.dayOfWeek]!.add(schedule);
                      }

                      final days = [
                        'Monday',
                        'Tuesday',
                        'Wednesday',
                        'Thursday',
                        'Friday',
                        'Saturday',
                        'Sunday'
                      ];
                      
                      return ListView.builder(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16,
                          bottom: 88,
                        ),
                        itemCount: days.length,
                        itemBuilder: (context, index) {
                          final day = days[index];
                          final daySchedules = schedulesByDay[day] ?? [];
                          if (daySchedules.isEmpty) return const SizedBox.shrink();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  day,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ...daySchedules.map((schedule) {
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      child: Text(
                                        schedule.subject.substring(0, 1),
                                      ),
                                    ),
                                    title: Text(schedule.subject),
                                    subtitle: Text(
                                      '${schedule.timeSlot}\n${schedule.room} • ${schedule.lecturer}${schedule.concentration != null ? "\n${schedule.concentration}" : ""}',
                                    ),
                                    isThreeLine: true,
                                    trailing: PopupMenuButton(
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, size: 20),
                                              SizedBox(width: 8),
                                              Text('Edit'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete,
                                                  size: 20, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Delete',
                                                  style: TextStyle(
                                                      color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _showEditScheduleDialog(schedule);
                                        } else if (value == 'delete') {
                                          _deleteSchedule(schedule);
                                        }
                                      },
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddScheduleDialog() {
    if (selectedMajor == null ||
        selectedBatch == null ||
        selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select major, batch, and class first')),
      );
      return;
    }

    _showScheduleFormDialog(null);
  }

  void _showEditScheduleDialog(ScheduleModel schedule) {
    _showScheduleFormDialog(schedule);
  }

  void _showScheduleFormDialog(ScheduleModel? schedule) {
    final isEdit = schedule != null;
    final formKey = GlobalKey<FormState>();

    String subject = schedule?.subject ?? '';
    String lecturer = schedule?.lecturer ?? '';
    String room = schedule?.room ?? '';
    String dayOfWeek = schedule?.dayOfWeek ?? 'Monday';
    String? concentration = schedule?.concentration;
    
    TimeOfDay startTime = schedule != null
        ? TimeOfDay(
            hour: int.parse(schedule.startTime.split(':')[0]),
            minute: int.parse(schedule.startTime.split(':')[1]),
          )
        : const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = schedule != null
        ? TimeOfDay(
            hour: int.parse(schedule.endTime.split(':')[0]),
            minute: int.parse(schedule.endTime.split(':')[1]),
          )
        : const TimeOfDay(hour: 9, minute: 40);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          // Format time to string
          String formatTime(TimeOfDay time) {
            final hour = time.hour.toString().padLeft(2, '0');
            final minute = time.minute.toString().padLeft(2, '0');
            return '$hour:$minute';
          }

          // Pick start time
          Future<void> pickStartTime() async {
            final picked = await showTimePicker(
              context: context,
              initialTime: startTime,
            );
            if (picked != null) {
              setState(() => startTime = picked);
            }
          }

          // Pick end time
          Future<void> pickEndTime() async {
            final picked = await showTimePicker(
              context: context,
              initialTime: endTime,
            );
            if (picked != null) {
              setState(() => endTime = picked);
            }
          }

          return AlertDialog(
            title: Text(isEdit ? 'Edit Schedule' : 'Add Schedule'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info text
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Creating for: ${selectedMajor!}\nBatch: $selectedBatch\nClass: $selectedClass',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      initialValue: subject,
                      decoration: const InputDecoration(labelText: 'Subject'),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      onSaved: (v) => subject = v!,
                    ),
                    const SizedBox(height: 12),
                    
                    TextFormField(
                      initialValue: lecturer,
                      decoration: const InputDecoration(labelText: 'Lecturer'),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      onSaved: (v) => lecturer = v!,
                    ),
                    const SizedBox(height: 12),
                    
                    TextFormField(
                      initialValue: room,
                      decoration: const InputDecoration(labelText: 'Room'),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      onSaved: (v) => room = v!,
                    ),
                    const SizedBox(height: 16),
                    
                    // Concentration (Optional)
                    if (selectedMajor != null &&
                        AppConstants.getConcentrationsForMajor(selectedMajor!)
                            .isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: concentration,
                        decoration: const InputDecoration(
                          labelText: 'Concentration (Optional)',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All concentrations'),
                          ),
                          ...AppConstants.getConcentrationsForMajor(
                                  selectedMajor!)
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  )),
                        ],
                        onChanged: (v) => concentration = v,
                      ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: dayOfWeek,
                      decoration: const InputDecoration(labelText: 'Day'),
                      items: AppConstants.daysOfWeek
                          .map((day) =>
                              DropdownMenuItem(value: day, child: Text(day)))
                          .toList(),
                      onChanged: (v) => dayOfWeek = v!,
                    ),
                    const SizedBox(height: 16),

                    // Start Time Picker
                    const Text(
                      'Start Time',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: pickStartTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time,
                                color: Color(0xFF003160)),
                            const SizedBox(width: 12),
                            Text(
                              formatTime(startTime),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // End Time Picker
                    const Text(
                      'End Time',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: pickEndTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_filled,
                                color: Color(0xFF003160)),
                            const SizedBox(width: 12),
                            Text(
                              formatTime(endTime),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();

                    // Validate time
                    final start = startTime.hour * 60 + startTime.minute;
                    final end = endTime.hour * 60 + endTime.minute;

                    if (end <= start) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('End time must be after start time'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final currentUserId =
                        FirebaseAuth.instance.currentUser?.uid;
                    if (currentUserId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User not logged in')),
                      );
                      return;
                    }

                    final newSchedule = ScheduleModel(
                      id: schedule?.id,
                      major: selectedMajor!,
                      batch: selectedBatch!,
                      concentration: concentration,
                      classCode: selectedClass!,
                      subject: subject,
                      lecturer: lecturer,
                      room: room,
                      dayOfWeek: dayOfWeek,
                      startTime: formatTime(startTime),
                      endTime: formatTime(endTime),
                      createdBy: currentUserId,
                    );

                    Map<String, dynamic> result;
                    if (isEdit) {
                      result = await _scheduleService.updateSchedule(
                        schedule.id!,
                        newSchedule,
                      );
                    } else {
                      result =
                          await _scheduleService.createSchedule(newSchedule);
                    }

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(content: Text(result['message'])),
                      );
                    }
                  }
                },
                child: Text(isEdit ? 'Update' : 'Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteSchedule(ScheduleModel schedule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: Text('Delete ${schedule.subject}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _scheduleService.deleteSchedule(schedule.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    }
  }
}
