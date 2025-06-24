import 'package:flutter/material.dart';
import 'package:glacier/pages/friends/FriendsStack.dart';
import 'package:glacier/pages/home/HomeStack.dart';
import 'package:glacier/pages/send-reaction/SendReactionStack.dart';

class BottomMenuLayout extends StatefulWidget {
  final int? index;

  const BottomMenuLayout({super.key, this.index});

  @override
  _BottomMenuLayoutState createState() => _BottomMenuLayoutState();
}

class _BottomMenuLayoutState extends State<BottomMenuLayout> {
  int _currentIndex = 0;

  // Define the pages
  final List<Widget> _pages = [
    HomeStack(),
    SendReactionStack(),
    FriendsStack(),
  ];

  // Scaffold with BottomNavigationBar
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: SizedBox(height: 60),
      ),
      body: _pages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
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
    );
  }

  @override
  void initState() {
    super.initState();
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
    setState(() {
      _currentIndex = index;
    });
  }
}
