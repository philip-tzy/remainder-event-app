import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/schedule_model.dart';
import '../../models/user_model.dart';
import '../../services/schedule_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/schedule_card.dart';

class ScheduleListScreen extends StatefulWidget {
  const ScheduleListScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleListScreen> createState() => _ScheduleListScreenState();
}

class _ScheduleListScreenState extends State<ScheduleListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final List<String> _dayShort = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void initState() {
    super.initState();
    // Get current day index (Monday = 0, Sunday = 6)
    final today = DateTime.now().weekday - 1; // weekday: 1=Monday, 7=Sunday
    _tabController = TabController(
      length: _days.length,
      vsync: this,
      initialIndex: today,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Schedule')),
        body: const Center(child: Text('Please login first')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedule'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          tabs: List.generate(_days.length, (index) {
            final isToday = index == DateTime.now().weekday - 1;
            return Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_dayShort[index]),
                  if (isToday)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ),
      body: FutureBuilder<UserModel?>(
        future: AuthService().getUserData(userId),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!userSnapshot.hasData || userSnapshot.data == null) {
            return const Center(child: Text('User data not found'));
          }

          final user = userSnapshot.data!;

          if (user.major == null ||
              user.batch == null ||
              user.classCode == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber,
                      size: 64, color: Colors.orange[700]),
                  const SizedBox(height: 16),
                  const Text(
                    'Profile incomplete',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Please complete your profile to view schedules'),
                ],
              ),
            );
          }

          return StreamBuilder<List<ScheduleModel>>(
            stream: ScheduleService().getSchedulesForUser(
              user.major!,
              user.batch!,
              user.classCode!,
              user.concentration,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return TabBarView(
                  controller: _tabController,
                  children: List.generate(_days.length, (index) {
                    return _buildEmptyState();
                  }),
                );
              }

              final allSchedules = snapshot.data!;

              // Group schedules by day
              final schedulesByDay = <String, List<ScheduleModel>>{};
              for (var schedule in allSchedules) {
                schedulesByDay.putIfAbsent(schedule.dayOfWeek, () => []);
                schedulesByDay[schedule.dayOfWeek]!.add(schedule);
              }

              // Sort schedules by start time
              for (var day in schedulesByDay.keys) {
                schedulesByDay[day]!.sort((a, b) {
                  return a.startTime.compareTo(b.startTime);
                });
              }

              return TabBarView(
                controller: _tabController,
                children: List.generate(_days.length, (index) {
                  final day = _days[index];
                  final daySchedules = schedulesByDay[day] ?? [];

                  if (daySchedules.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildScheduleList(daySchedules);
                }),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No classes today',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Enjoy your free time!',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList(List<ScheduleModel> schedules) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        final isCurrentClass = schedule.isHappeningNow();
        final isUpcoming = schedule.isUpcomingSoon();

        return Column(
          children: [
            ScheduleCard(
              schedule: schedule,
              isCurrentClass: isCurrentClass,
              isUpcoming: isUpcoming,
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}
