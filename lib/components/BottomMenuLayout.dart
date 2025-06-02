import 'package:flutter/material.dart';
import 'package:glacier/pages/friends/FriendsStack.dart';
import 'package:glacier/pages/home/HomeStack.dart';
import 'package:glacier/pages/send-reaction/SendReactionStack.dart';

class BottomMenuLayout extends StatefulWidget {
  const BottomMenuLayout({super.key});

  @override
  _BottomMenuLayoutState createState() => _BottomMenuLayoutState();
}

class _BottomMenuLayoutState extends State<BottomMenuLayout> {
  int _currentIndex = 0;

  // Define the pages
  final List<Widget> _pages = [
    HomeStack(),
    FriendsStack(),
    SendReactionStack(),
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
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_reaction_sharp),
            label: "Friends",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Send Reaction",
          ),
        ],
      ),
    );
  }

  // Handle tap on bottom navigation
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
