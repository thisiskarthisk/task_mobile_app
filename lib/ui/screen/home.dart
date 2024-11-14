import 'package:flutter/material.dart';
import 'package:flutter_tms/ui/screen/auth/login.dart';
import 'package:flutter_tms/ui/screen/notifications.dart';

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

  // Logout Confirm Modal
  void _showLogoutConfirmationDialog(){
    showDialog(
        context: context,
        builder: (BuildContext context){
          return AlertDialog(
            title: Text("Confirm Logout"),
            content: Text("Are you sure you want to log out?"),
            actions:<Widget> [
              TextButton(
                child:Text("No"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child:Text("Yes"),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen())
                  );
                },
              )
            ],
          );
        }
    );
  }

  // Function to show the notifications screen as a bottom sheet with animation
  void _showNotificationsScreen() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: NotificationsScreen(), // Replace with your NotificationsScreen content
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width and height using MediaQuery
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Define some dynamic values based on screen size
    double padding = screenWidth * 0.05; // 5% padding
    double fontSize = screenWidth < 600 ? 18 : 24; // Smaller font size on smaller screens
    double cardHeight = screenHeight * 0.25; // Adjust card height dynamically

    return Scaffold(
      backgroundColor: Colors.blue, // Set the background color to blue
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.blue, // Background color of the AppBar
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1), // Shadow color
                  blurRadius: 1.5,
                  offset: Offset(0, 5), // Position of the shadow
                ),
              ],
            ),
            child: AppBar(
              backgroundColor: Colors.transparent, // Make AppBar background transparent
              elevation: 0, // Remove default elevation
              title: Text(
                'Home',
                style: TextStyle(color: Colors.white, fontSize: fontSize),
              ),
              actions: [
                IconButton(
                  color: Colors.white,
                  icon: Icon(Icons.notifications), // Notification icon
                  onPressed: _showNotificationsScreen,
                ),
                IconButton(
                  color: Colors.white,
                  icon: Icon(Icons.power_settings_new), // Power off icon
                  onPressed: _showLogoutConfirmationDialog,
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
                      margin: EdgeInsets.symmetric(horizontal: padding), // Dynamic horizontal margin
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
                              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              'Email: ${widget.userEmail}',
                              style: TextStyle(fontSize: fontSize * 0.8),
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
                        height: cardHeight, // Dynamic height based on screen size
                        margin: EdgeInsets.all(padding), // Dynamic margin
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
                                  style: TextStyle(fontSize: fontSize * 0.9, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                SizedBox(height: 4.0),
                                Text(
                                  'Address: 123 Main St, Anytown, USA',
                                  style: TextStyle(fontSize: fontSize * 0.7, color: Colors.white),
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
