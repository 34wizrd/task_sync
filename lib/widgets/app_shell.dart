import 'package:flutter/material.dart';
import '../features/diary/dashboard_screen.dart';
import '../features/profile/profile_screen.dart';
import 'main_layout.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  // --- Define the pages and their corresponding AppBars ---
  static const List<Widget> _pages = <Widget>[
    DashboardScreen(),
    PlaceholderScreen(title: 'Food Log'),
    PlaceholderScreen(title: 'Progress'),
    ProfileScreen(),
  ];

  static final List<PreferredSizeWidget?> _appBars = <PreferredSizeWidget?>[
    _buildMainAppBar(),
    _buildSimpleAppBar('Food Log'),
    _buildSimpleAppBar('Progress'),
    _buildSimpleAppBar('Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF30D575);
    const darkBg = Color(0xFF121212);
    const lightText = Color(0xFF8A8A8E);

    return MainLayout(
      appBar: _appBars[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: darkBg,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: primaryGreen,
        unselectedItemColor: lightText,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Food Log'),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      // IndexedStack preserves the state of each page when switching tabs.
      child: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
    );
  }
}

// Helper methods to build different kinds of AppBars
PreferredSizeWidget _buildMainAppBar() {
  return AppBar(
    backgroundColor: const Color(0xFF121212),
    elevation: 0,
    centerTitle: true,
    title: const Text('Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
  );
}

PreferredSizeWidget _buildSimpleAppBar(String title) {
  return AppBar(
    backgroundColor: const Color(0xFF121212),
    elevation: 0,
    centerTitle: true,
    title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
  );
}

// A simple placeholder widget for unbuilt screens
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 24)));
  }
}