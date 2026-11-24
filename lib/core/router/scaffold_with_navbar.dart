import 'package:flutter/material.dart';

import '../../features/dashboard/presentation/screens/dashboard_home_screen.dart';
import '../../features/interviews/presentation/screens/interview_schedules_screen.dart';
import '../../features/calendar/presentation/screens/availability_calendar_screen.dart';
import '../../features/skills/presentation/screens/skill_management_screen.dart';
import '../../features/profile/presentation/screens/profile_overview_screen.dart';
import '../theme/futuremug_colors.dart';

class MainTabScaffold extends StatefulWidget {
  const MainTabScaffold({super.key});

  @override
  State<MainTabScaffold> createState() => _MainTabScaffoldState();
}

class _MainTabScaffoldState extends State<MainTabScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardHomeScreen(),
    InterviewSchedulesScreen(),
    AvailabilityCalendarScreen(),
    SkillManagementScreen(),
    ProfileOverviewScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: FuturemugColors.navyPrimary),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note, color: FuturemugColors.navyPrimary),
            label: 'Schedules',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: FuturemugColors.navyPrimary),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology, color: FuturemugColors.navyPrimary),
            label: 'Skills',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: FuturemugColors.navyPrimary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
