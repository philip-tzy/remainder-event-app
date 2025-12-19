import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/schedule_model.dart';
import '../../services/auth_service.dart';
import '../../services/schedule_service.dart';
import '../../widgets/schedule_card.dart';

class ScheduleListScreen extends StatelessWidget {
  const ScheduleListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedule'),
      ),
      body: FutureBuilder(
        future: AuthService().getUserData(userId!),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!userSnapshot.hasData) {
            return const Center(child: Text('User data not found'));
          }

          final userData = userSnapshot.data!;

          return StreamBuilder<List<ScheduleModel>>(
            stream: ScheduleService().getSchedulesByClass(
              userData.major!,
              userData.classCode!,
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
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No schedule available',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final schedules = snapshot.data!;
              
              // Group schedules by day
              final schedulesByDay = <String, List<ScheduleModel>>{};
              for (var schedule in schedules) {
                schedulesByDay.putIfAbsent(schedule.dayOfWeek, () => []);
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

              return DefaultTabController(
                length: days.length,
                child: Column(
                  children: [
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        isScrollable: true,
                        labelColor: Theme.of(context).primaryColor,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Theme.of(context).primaryColor,
                        tabs: days
                            .map((day) => Tab(text: day.substring(0, 3)))
                            .toList(),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: days.map((day) {
                          final daySchedules = schedulesByDay[day] ?? [];
                          
                          if (daySchedules.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.free_breakfast,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No classes on $day',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: daySchedules.length,
                            itemBuilder: (context, index) {
                              final schedule = daySchedules[index];
                              return ScheduleCard(
                                schedule: schedule,
                                isCurrentClass: schedule.isHappeningNow(),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
