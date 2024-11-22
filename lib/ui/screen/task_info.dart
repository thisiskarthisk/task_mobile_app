import 'package:flutter/material.dart';
import 'package:flutter_tms/ui/screen/auth/login.dart';
import 'package:flutter_tms/ui/screen/cases.dart';
import 'package:flutter_tms/ui/screen/dashboard.dart';
import 'package:flutter_tms/ui/screen/favorites.dart';
import 'package:flutter_tms/ui/screen/home.dart';
import 'package:flutter_tms/ui/screen/notifications.dart';
import 'package:flutter_tms/api/authService.dart';

class TaskInfoScreen extends StatefulWidget {
  @override
  _TaskInfoScreenState createState() => _TaskInfoScreenState();
}

class _TaskInfoScreenState extends State<TaskInfoScreen> {
  int _selectedIndex = 0;

  final AuthService authService = AuthService();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  // Method to show date picker and update the corresponding controller
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.toLocal()}".split(' ')[0]; // Format the date as 'YYYY-MM-DD'
      });
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Filter by Date"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _startDateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      hintText: "Select Start Date",
                    ),
                    onTap: () => _selectDate(context, _startDateController),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _endDateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      hintText: "Select End Date",
                    ),
                    onTap: () => _selectDate(context, _endDateController),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Use _startDateController.text and _endDateController.text for filtering
              },
              child: const Text("Filter"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  // A list of content widgets to display based on the selected index
  final List<Widget> _contentWidgets = [
    CasesScreen(),
    FavoritesScreen(),
    DashboardScreen(),
    NotificationsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Logout Confirm Modal
  void _showLogoutConfirmationDialog(){
    showDialog(
        context: context,
        builder: (BuildContext context){
          return AlertDialog(
            title: const Text("Confirm Logout"),
            content: const Text("Are you sure you want to log out?"),
            actions:<Widget> [
              TextButton(
                child:const Text("No"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text("Yes"),
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.blue,
        title: Text(
          _selectedIndex == 0 ? 'Cases' :
          _selectedIndex == 1 ? 'Favorites' :
          _selectedIndex == 2 ? 'Dashboard' : 'Notifications',
          style: const TextStyle(color: Colors.white),
        ),
        actions: _selectedIndex == 0
        ? [
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.notifications), // Notification icon
            onPressed: () {
              // Add your notification functionality here
            },
          ),
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          )
        ]
        : null ,
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              const DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text(
                  'Projlujo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.switch_account),
                title: const Text('Switch Account'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.list),
                title: Text('Cases'),
                onTap: () {
                  Navigator.pop(context);
                  _onItemTapped(0); // Navigate to Cases
                },
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text('Profile'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to Profile screen
                },
              ),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to Settings screen
                },
              ),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Logout'),
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutConfirmationDialog();
                },
              ),
            ],
          ),
        ),
      ),
      body: _contentWidgets[_selectedIndex], // Access the widget using []
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blue,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list, color: Colors.white),
            label: 'Cases',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star, color: Colors.white),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today, color: Colors.white),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications, color: Colors.white),
            label: 'Notifications',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Map<String, String?> userData = await authService.getUserData();
          if (userData['userName'] != null && userData['userEmail'] != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(userName: userData['userName']!, userEmail: userData['userEmail']!),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar( // Handle missing data explicitly
              const SnackBar(
                content: Text('Error: Missing user information.'),
              ),
            );
          }
        },
        backgroundColor: Colors.blue,
        elevation: 6,
        child: const Icon(
          Icons.home,
          color: Colors.white,
          size: 30,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
