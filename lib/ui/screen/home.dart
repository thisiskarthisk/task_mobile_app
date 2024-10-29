// lib/ui/screen/home.dart
import 'package:flutter/material.dart';
import 'package:flutter_tms/ui/screen/auth/login.dart';
import 'cases.dart'; // Import CasesScreen

class HomeScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  // Constructor to accept user name and email
  const HomeScreen({Key? key, required this.userName, required this.userEmail}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isCompanyInfoVisible = false; // State to control visibility of horizontal card

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue, // Set the background color to blue
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.blue, // Background color of the AppBar
              // border: Border(
              //   bottom: BorderSide(
              //     // color: Colors.black.withOpacity(.0), // Border color
              //   //   // width: 1.0, // Border width
              //   ),
              // ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),//Shadow color
                  blurRadius:1.5,
                  offset: Offset(0, 5)// Position of the shadow
                ),
              ],
            ),
            child: AppBar(
              backgroundColor: Colors.transparent, // Make AppBar background transparent
              elevation: 0, // Remove default elevation
              title: Text(
                'Home',
                style: TextStyle(color: Colors.white),
              ),
              actions: [
                IconButton(
                  color: Colors.white,
                  icon: Icon(Icons.notifications), // Notification icon
                  onPressed: () {
                    // Add your notification functionality here
                  },
                ),
                IconButton(
                  color: Colors.white,
                  icon: Icon(Icons.power_settings_new), // Power off icon
                  onPressed: () {
                    // Add your logout functionality here
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Center card displaying user information
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        // Toggle visibility of the horizontal card
                        _isCompanyInfoVisible = !_isCompanyInfoVisible;
                      });
                    },
                    child: Card(
                      elevation: 8.0, // Elevation for the user info card
                      margin: EdgeInsets.symmetric(horizontal: 20.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Welcome, ${widget.userName}!',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              'Email: ${widget.userEmail}',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 32.0),

                  // Show horizontal card if the state variable is true
                  if (_isCompanyInfoVisible)
                    GestureDetector(
                      onTap: () {
                        // Navigate to CasesScreen when the horizontal card is clicked
                        Navigator.pushNamed(context, '/task_info');
                      },
                      child: Container(
                        margin: EdgeInsets.all(20.0),
                        padding: EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent, // Background color for the horizontal card
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2), // Shadow color
                              blurRadius: 8.0, // Spread of the shadow
                              offset: Offset(0, 4), // Position of the shadow
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Company Name: Proflujo',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                SizedBox(height: 4.0),
                                Text(
                                  'Address: 123 Main St, Anytown, USA',
                                  style: TextStyle(fontSize: 14, color: Colors.white),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                            ), // Arrow icon to indicate navigation
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
