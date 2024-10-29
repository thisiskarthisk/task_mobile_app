import 'package:flutter/material.dart';
import 'package:flutter_tms/ui/screen/cases.dart';
import 'package:flutter_tms/ui/screen/dashboard.dart';
import 'package:flutter_tms/ui/screen/favorites.dart';
import 'package:flutter_tms/ui/screen/notifications.dart';
import 'package:flutter_tms/ui/screen/task_info.dart';
import 'ui/screen/auth/login.dart'; // Import LoginScreen
import 'ui/screen/home.dart';  // Import HomeScreen

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  get sk => null;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login', // Set initial route
      routes: {
        '/login': (context) => LoginScreen(), // Route to LoginScreen
        '/home': (context) => HomeScreen(userName: 'sk', userEmail: 'karthi@proflujo.com'), // Route to HomeScreen
        '/task_info': (context) => TaskInfoScreen(),
        '/cases': (context) => CasesScreen(),
        '/favorites': (context) => FavoritesScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/notifications': (context) => NotificationsScreen(),
      },
    );
  }
}
