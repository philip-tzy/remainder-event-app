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
            child: Row(
              children: [
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
                        child: Text(major),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedMajor = value;
                        selectedClass = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Class',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedClass,
                    items: selectedMajor == null
                        ? []
                        : AppConstants.getClassesForMajor(selectedMajor!).map((classCode) {
                            return DropdownMenuItem(
                              value: classCode,
                              child: Text(classCode),
                            );
                          }).toList(),
                    onChanged: (value) {
                      setState(() => selectedClass = value);
                    },
                  ),
                ),
              ],
            ),
          ),

          // Schedule List
          Expanded(
            child: selectedMajor == null || selectedClass == null
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
                          'Select major and class to view schedules',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : StreamBuilder<List<ScheduleModel>>(
                    stream: _scheduleService.getSchedulesByClass(
                      selectedMajor!,
                      selectedClass!,
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

                      final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
                      
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
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
                                      '${schedule.timeSlot}\n${schedule.room} • ${schedule.lecturer}',
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
                                              Icon(Icons.delete, size: 20, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Delete', style: TextStyle(color: Colors.red)),
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
    if (selectedMajor == null || selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select major and class first')),
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
    String timeSlot = schedule?.timeSlot ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Schedule' : 'Add Schedule'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: subject,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  onSaved: (v) => subject = v!,
                ),
                TextFormField(
                  initialValue: lecturer,
                  decoration: const InputDecoration(labelText: 'Lecturer'),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  onSaved: (v) => lecturer = v!,
                ),
                TextFormField(
                  initialValue: room,
                  decoration: const InputDecoration(labelText: 'Room'),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  onSaved: (v) => room = v!,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: dayOfWeek,
                  decoration: const InputDecoration(labelText: 'Day'),
                  items: AppConstants.daysOfWeek
                      .map((day) => DropdownMenuItem(value: day, child: Text(day)))
                      .toList(),
                  onChanged: (v) => dayOfWeek = v!,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: timeSlot.isEmpty ? null : timeSlot,
                  decoration: const InputDecoration(labelText: 'Time Slot'),
                  items: AppConstants.timeSlots
                      .map((slot) => DropdownMenuItem(value: slot, child: Text(slot)))
                      .toList(),
                  onChanged: (v) => timeSlot = v!,
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
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
                
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                if (currentUserId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User not logged in')),
                  );
                  return;
                }

                final newSchedule = ScheduleModel(
                  id: schedule?.id,
                  major: selectedMajor!,
                  classCode: selectedClass!,
                  subject: subject,
                  lecturer: lecturer,
                  room: room,
                  dayOfWeek: dayOfWeek,
                  timeSlot: timeSlot,
                  createdBy: currentUserId, // DIPERBAIKI: Menambahkan createdBy
                );

                Map<String, dynamic> result;
                if (isEdit) {
                  result = await _scheduleService.updateSchedule(
                    schedule.id!,
                    newSchedule,
                  );
                } else {
                  result = await _scheduleService.createSchedule(newSchedule);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result['message'])),
                  );
                }
              }
            },
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
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
