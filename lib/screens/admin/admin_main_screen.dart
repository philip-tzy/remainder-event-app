import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';
import 'admin_home_screen.dart';
import 'manage_schedule_screen.dart';
import 'admin_profile_screen.dart';

// GlobalKey untuk mengakses state dari luar
final GlobalKey<_AdminMainScreenState> adminMainScreenKey = GlobalKey<_AdminMainScreenState>();

class AdminMainScreen extends StatefulWidget {
  // DIPERBAIKI: Hapus const dan tambahkan key ke super
  AdminMainScreen({Key? key}) : super(key: key ?? adminMainScreenKey);

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const AdminDashboardScreen(), // Tab 0: Home (dengan statistics)
      const AdminHomeScreen(),      // Tab 1: Manage Events
      const ManageScheduleScreen(), // Tab 2: Manage Schedules
      const AdminProfileScreen(),   // Tab 3: Profile
    ];
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
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
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
