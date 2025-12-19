import 'package:flutter/material.dart';
import '../../services/event_service.dart';
import '../../services/schedule_service.dart';
import '../../models/event_model.dart';
import '../../models/schedule_model.dart';
import 'admin_main_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome, Admin! 👋',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage campus events and schedules',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Stats
            Row(
              children: [
                // Total Events Card
                Expanded(
                  child: StreamBuilder<List<EventModel>>(
                    stream: EventService().getAllEvents(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _StatCard(
                          icon: Icons.event,
                          title: 'Total Events',
                          value: '...',
                          color: Colors.blue,
                          onTap: () => _navigateToTab(1),
                        );
                      }

                      if (snapshot.hasError) {
                        return _StatCard(
                          icon: Icons.event,
                          title: 'Total Events',
                          value: 'Error',
                          color: Colors.blue,
                          onTap: () => _navigateToTab(1),
                        );
                      }

                      final count = snapshot.data?.length ?? 0;
                      return _StatCard(
                        icon: Icons.event,
                        title: 'Total Events',
                        value: count.toString(),
                        color: Colors.blue,
                        onTap: () => _navigateToTab(1),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Total Schedules Card
                Expanded(
                  child: StreamBuilder<List<ScheduleModel>>(
                    stream: ScheduleService().getAllSchedules(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _StatCard(
                          icon: Icons.schedule,
                          title: 'Total Schedules',
                          value: '...',
                          color: Colors.orange,
                          onTap: () => _navigateToTab(2),
                        );
                      }

                      if (snapshot.hasError) {
                        print('Error getting schedules: ${snapshot.error}');
                        return _StatCard(
                          icon: Icons.schedule,
                          title: 'Total Schedules',
                          value: 'Error',
                          color: Colors.orange,
                          onTap: () => _navigateToTab(2),
                        );
                      }

                      final count = snapshot.data?.length ?? 0;
                      print('📊 Total schedules count: $count'); // Debug log
                      
                      return _StatCard(
                        icon: Icons.schedule,
                        title: 'Total Schedules',
                        value: count.toString(),
                        color: Colors.orange,
                        onTap: () => _navigateToTab(2),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _QuickActionButton(
              icon: Icons.add_circle_outline,
              title: 'Create New Event',
              subtitle: 'Add a campus event',
              color: Colors.blue,
              onTap: () {
                Navigator.pushNamed(context, '/event-form');
              },
            ),
            const SizedBox(height: 8),
            _QuickActionButton(
              icon: Icons.schedule,
              title: 'Add Class Schedule',
              subtitle: 'Create new class schedule',
              color: Colors.orange,
              onTap: () => _navigateToTab(2),
            ),
            const SizedBox(height: 8),
            _QuickActionButton(
              icon: Icons.people,
              title: 'View All Events',
              subtitle: 'Manage campus events',
              color: Colors.green,
              onTap: () => _navigateToTab(1),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTab(int index) {
    adminMainScreenKey.currentState?.navigateToTab(index);
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
