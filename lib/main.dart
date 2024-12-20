import 'package:flutter/material.dart';
import 'package:flutter_tms/ui/screen/cases.dart';
import 'package:flutter_tms/ui/screen/dashboard.dart';
import 'package:flutter_tms/ui/screen/favorites.dart';
import 'package:flutter_tms/ui/screen/notifications.dart';
import 'package:flutter_tms/ui/screen/bottomBar.dart';
import 'ui/screen/auth/login.dart'; // Import LoginScreen
import 'ui/screen/home.dart';  // Import HomeScreen
import 'ui/screen/auth/splash_screen.dart';

void main() {
  runApp(Tms());
}

class Tms extends StatelessWidget {
  get sk => null;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/splash', // Set initial route
      routes: {
        '/splash': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(), // Route to LoginScreen
        '/home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, String?>?;

            if (args != null && args['userName'] != null && args['userEmail'] != null) {
              return HomeScreen(
                userName: args['userName']!,
                userEmail: args['userEmail']!,
              );
            } else {

              WidgetsBinding.instance.addPostFrameCallback((_) { // Redirect to login if arguments are missing
                Navigator.of(context).pushReplacementNamed('/login');
              });

              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
          },
        '/task_info': (context) => bottomBar(),
        '/cases': (context) => CasesScreen(),
        '/favorites': (context) => FavoritesScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/notifications': (context) => NotificationsScreen(),
      },
    );
  }
}
