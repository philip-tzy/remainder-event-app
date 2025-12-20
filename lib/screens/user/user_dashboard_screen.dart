import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/schedule_service.dart';
import '../../services/event_service.dart';
import '../../models/user_model.dart';
import '../../models/schedule_model.dart';
import '../../models/event_model.dart';
import '../../widgets/schedule_card.dart';
import '../../widgets/event_list_item.dart';
import 'event_detail_screen.dart';
import 'user_main_screen.dart';

class UserDashboardScreen extends StatelessWidget {
  const UserDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please login')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Show notifications screen
            },
          ),
        ],
      ),
      body: FutureBuilder<UserModel?>(
        future: AuthService().getUserData(userId),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!userSnapshot.hasData) {
            return const Center(child: Text('User data not found'));
          }

          final userData = userSnapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              // Trigger rebuild
              (context as Element).markNeedsBuild();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card with Profile Picture
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        // Profile Picture
                        GestureDetector(
                          onTap: () {
                            // Navigate to profile when tapped
                            userMainScreenKey.currentState?.navigateToTab(3);
                          },
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            backgroundImage: userData.photoURL != null
                                ? NetworkImage(userData.photoURL!)
                                : null,
                            child: userData.photoURL == null
                                ? Text(
                                    userData.name.substring(0, 1).toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 32,
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // User Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, ${userData.name}!',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                userData.fullStudentInfo,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('EEEE, dd MMMM yyyy')
                                    .format(DateTime.now()),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Today's Schedule Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Today\'s Classes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to Schedule tab (index 2)
                          navigateToScheduleTab();
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Today's Classes
                  if (userData.major == null ||
                      userData.batch == null ||
                      userData.classCode == null)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.warning_amber,
                              size: 48,
                              color: Colors.orange[700],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Profile incomplete',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    FutureBuilder<List<ScheduleModel>>(
                      future: ScheduleService().getTodaySchedules(
                        userData.major!,
                        userData.classCode!,
                        batch: userData.batch,
                        concentration: userData.concentration,
                      ),
                      builder: (context, scheduleSnapshot) {
                        if (scheduleSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (scheduleSnapshot.hasError) {
                          print(
                              'Error loading schedules: ${scheduleSnapshot.error}');
                        }

                        if (!scheduleSnapshot.hasData ||
                            scheduleSnapshot.data!.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.event_available,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No classes today!',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final schedules = scheduleSnapshot.data!;
                        return Column(
                          children: schedules.map((schedule) {
                            final isCurrentClass = schedule.isHappeningNow();
                            final isUpcoming = schedule.isUpcomingSoon();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ScheduleCard(
                                schedule: schedule,
                                isCurrentClass: isCurrentClass,
                                isUpcoming: isUpcoming,
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),

                  const SizedBox(height: 24),

                  // Today's Events Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Today\'s Events',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to Events tab (index 1)
                          navigateToEventsTab();
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Today's Events
                  FutureBuilder<List<EventModel>>(
                    future: EventService().getTodayEvents(),
                    builder: (context, eventSnapshot) {
                      if (eventSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (eventSnapshot.hasError) {
                        print('Error loading events: ${eventSnapshot.error}');
                        return Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.red[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Error loading events',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (!eventSnapshot.hasData ||
                          eventSnapshot.data!.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No events today',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final todayEvents = eventSnapshot.data!;

                      return Column(
                        children: todayEvents.take(3).map((event) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: EventListItem(
                              event: event,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EventDetailScreen(
                                      event: event,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Navigate to Schedule tab (index 2)
  void navigateToScheduleTab() {
    userMainScreenKey.currentState?.navigateToTab(2);
  }

  // Navigate to Events tab (index 1)
  void navigateToEventsTab() {
    userMainScreenKey.currentState?.navigateToTab(1);
  }
}
