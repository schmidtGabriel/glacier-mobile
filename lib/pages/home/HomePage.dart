import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glacier/helpers/FormatStatusReaction.dart';
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
  bool isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child:
            isLoading
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (name != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            'Hello $name',
                            style: TextStyle(color: Colors.black, fontSize: 20),
                          ),
                        ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: reactions.length,
                        separatorBuilder: (_, __) => Divider(),
                        itemBuilder: (context, index) {
                          final reaction = reactions[index];
                          final title = reaction['title'] ?? 'No Name';
                          return GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/reaction',
                                arguments: reaction,
                              );
                            },
                            child: ListTile(
                              title: Text(title),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(reaction['url'] ?? 'No Description'),
                                  SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        FormatStatusReaction(
                                          reaction['status'],
                                        ),
                                      ),
                                      Text(
                                        reaction['created_at'] ?? 'No Date',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
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

    loadUserData();
  }

  Future<void> loadReactions() async {
    if (uuid == null) return;

    setState(() {
      isLoading = true;
    });
    reactions = await listReactions(userId: uuid!);
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('reactions', jsonEncode(reactions));
    setState(() {
      isLoading = false;
    });
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    uuid = prefs.getString('uuid');
    email = prefs.getString('email');
    name = prefs.getString('name');

    await loadReactions();
    setState(() {}); // Update UI after loading data
  }
}
