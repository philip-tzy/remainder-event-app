import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_dashboard_screen.dart';
import 'user_home_screen.dart';
import 'schedule_list_screen.dart';
import 'user_profile_screen.dart';
import '../../services/schedule_notification_service.dart';
import '../../services/auth_service.dart';
import '../../services/schedule_service.dart';

// GlobalKey untuk mengakses state dari luar
final GlobalKey<_UserMainScreenState> userMainScreenKey = GlobalKey<_UserMainScreenState>();

class UserMainScreen extends StatefulWidget {
  UserMainScreen({Key? key}) : super(key: key ?? userMainScreenKey);

  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const UserDashboardScreen(),  // Tab 0: Home
      const UserHomeScreen(),       // Tab 1: Campus Events
      const ScheduleListScreen(),   // Tab 2: My Schedule
      const UserProfileScreen(),    // Tab 3: Profile
    ];
    _scheduleWeeklyNotifications();
  }

  Future<void> _scheduleWeeklyNotifications() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final userData = await AuthService().getUserData(userId);
      if (userData == null || userData.major == null || userData.classCode == null) {
        return;
      }

      final schedules = await ScheduleService()
          .getSchedulesByClass(userData.major!, userData.classCode!)
          .first;

      await ScheduleNotificationService()
          .scheduleWeeklyClassNotifications(schedules);
      print('✅ Weekly class notifications scheduled');
    } catch (e) {
      print('Error scheduling notifications: $e');
    }
  }

  // Public method untuk navigasi dari screen lain
  void navigateToTab(int index) {
    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (mounted) {
            setState(() => _selectedIndex = index);
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_outlined),
            activeIcon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule_outlined),
            activeIcon: Icon(Icons.schedule),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
