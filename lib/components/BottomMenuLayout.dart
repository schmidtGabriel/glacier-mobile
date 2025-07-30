import 'package:flutter/material.dart';
import 'package:glacier/pages/friends/FriendsStack.dart';
import 'package:glacier/pages/home/HomeStack.dart';
import 'package:glacier/pages/send-reaction/SendReactionStack.dart';
import 'package:glacier/services/getFCMToken.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BottomMenuLayout extends StatefulWidget {
  final int? index;
  final int? segment;

  const BottomMenuLayout({super.key, this.index, this.segment});

  @override
  _BottomMenuLayoutState createState() => _BottomMenuLayoutState();
}

class _BottomMenuLayoutState extends State<BottomMenuLayout> {
  int _currentIndex = 0;
  // Define the pages
  final List<Widget> _pages = [];

  // Scaffold with BottomNavigationBar
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],

      bottomNavigationBar: Theme(
        data: Theme.of(context),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          iconSize: 30,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.phone_android), label: ''),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_reaction_sharp),
              label: '',
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    // Initialize the pages
    _pages.addAll([
      HomeStack(),
      SendReactionStack(),
      FriendsStack(segment: widget.segment),
    ]);

    // Set the initial index if provided
    if (widget.index != null) {
      _currentIndex = widget.index!;
      // Ensure the page is initialized
    } else {
      _currentIndex = 0; // Default to the first tab
    }

    openPermissionsPage();
  }

  void openPermissionsPage() async {
    // Navigate to the permissions page if permissions are not granted
    final prefs = await SharedPreferences.getInstance();
    final permissionsGranted = prefs.getBool('permissionsGranted') ?? false;
    print('Permissions granted: $permissionsGranted');
    if (!permissionsGranted) {
      Navigator.of(context).pushNamed('/permissions').then((_) {
        // Reload the current page after permissions are granted
        prefs.setBool('permissionsGranted', true);
        initFCM();
        setState(() {});
      });
    }
  }

  // Handle tap on bottom navigation
  void _onTabTapped(int index) {
    if (index == 1) {
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushReplacementNamed('/gallery');
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }
}
