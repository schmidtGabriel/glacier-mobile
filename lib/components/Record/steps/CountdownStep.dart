import 'package:flutter/material.dart';
import 'package:glacier/themes/app_colors.dart';

class CountdownStep extends StatelessWidget {
  final int countdown;

  const CountdownStep({super.key, required this.countdown});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.secondaryDark,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Recording will start in...',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 40),
            Text(
              '$countdown',
              style: TextStyle(
                fontSize: 120,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 40),
            Text(
              'Get ready!',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
