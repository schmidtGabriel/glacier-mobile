import 'package:flutter/material.dart';

Route pageNotFound() {
  return MaterialPageRoute(
    builder:
        (context) => Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("Page not found", style: TextStyle(fontSize: 24)),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Back"),
                ),
              ],
            ),
          ),
        ),
  );
}
