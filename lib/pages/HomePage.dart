import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glacier/pages/EmbedVideoPage.dart';
import 'package:glacier/pages/RecordPage.dart';
import 'package:glacier/services/listReactions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? uuid;
  String? email;
  String? name;
  List reactions = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              SizedBox(height: 50),
              if (name != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Hello $name',
                    style: TextStyle(color: Colors.black, fontSize: 20),
                  ),
                ),
              ElevatedButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EmbedVideoPage()),
                    ),
                child: Text('Embed Videos'),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: reactions.length,
                  itemBuilder: (context, index) {
                    final reaction = reactions[index];
                    final name = reaction['title'] ?? 'No Name';
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => RecordPage(uuid: reaction['uuid']),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(name),
                            subtitle: Text(reaction['url'] ?? 'No Description'),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  reaction['status'] == 0
                                      ? 'Pending'
                                      : 'Approved ',
                                ),

                                Text(
                                  reaction['created_at'] ?? 'No Date',
                                  textAlign: TextAlign.end,
                                ),
                              ],
                            ),
                          ),
                          Divider(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
        },
        child: Icon(Icons.logout),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _loadUserData();
  }

  Future<void> _loadReactions() async {
    if (uuid == null) return;
    reactions = await listReactions(userId: uuid!);
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('reactions', jsonEncode(reactions));
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    uuid = prefs.getString('uuid');
    email = prefs.getString('email');
    name = prefs.getString('name');

    await _loadReactions();
    setState(() {}); // Update UI after loading data
  }
}
