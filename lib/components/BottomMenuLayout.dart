import 'package:flutter/material.dart';
import 'package:glacier/pages/friends/FriendsStack.dart';
import 'package:glacier/pages/home/HomeStack.dart';
import 'package:glacier/pages/send-reaction/SendReactionStack.dart';

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

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,

        destinations: [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.phone_android), label: 'New'),
          NavigationDestination(
            icon: Icon(Icons.add_reaction_sharp),
            label: 'Friends',
          ),
        ],
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
  }

  // Handle tap on bottom navigation
  void _onTabTapped(int index) {
    if (index == 1) {
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushReplacementNamed('/send-reaction');
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }
}
