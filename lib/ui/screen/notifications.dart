import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get screen width and height using MediaQuery
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Define some dynamic values based on screen size
    double padding = screenWidth * 0.05; // 5% padding
    double fontSize = screenWidth < 600 ? 18 : 24; // Smaller font size on smaller screens

    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications"),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(padding), // Apply dynamic padding
          child: Text(
            'Welcome to Notifications Screen!',
            style: TextStyle(
              fontSize: fontSize, // Adjust font size dynamically
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
