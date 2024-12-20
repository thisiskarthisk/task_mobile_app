import 'package:flutter/material.dart';
import 'package:flutter_tms/ui/screen/auth/login.dart';
import 'package:flutter_tms/ui/screen/cases.dart';
import 'package:flutter_tms/ui/screen/dashboard.dart';
import 'package:flutter_tms/ui/screen/favorites.dart';
import 'package:flutter_tms/ui/screen/home.dart';
import 'package:flutter_tms/ui/screen/home.dart';
import 'package:flutter_tms/ui/screen/notifications.dart';
import 'package:flutter_tms/api/authService.dart';

class bottomBar extends StatefulWidget {
  @override
  _bottomBarState createState() => _bottomBarState();
}

class _bottomBarState extends State<bottomBar> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final AuthService authService = AuthService();
  final List<String> _titles = ["Cases", "Favorites", "Dashboard", "Notifications"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _titles.length, vsync: this);
    _tabController!.addListener(() {
      setState(() {}); // Update the title when the tab changes
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Logout"),
          content: Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              child: Text("No"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text("Yes"),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
              },
            ),
          ],
        );
      },
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Filter Options"),
          content: Text("Choose your filter options here."),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text("Apply"),
              onPressed: () {
                Navigator.of(context).pop();
                // Apply filter functionality
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Define scaling factors for responsiveness
    final double fontSizeFactor = screenWidth * 0.05;
    final double iconSize = screenWidth * 0.08;

    return DefaultTabController(
      length: _titles.length,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.blue,
          title: Text(
            _titles[_tabController!.index],
            style: TextStyle(color: Colors.white, fontSize: fontSizeFactor),
          ),
          elevation: 6.0, // Shadow effect
          actions: _tabController!.index == 0
              ? [
            IconButton(
              color: Colors.white,
              icon: Icon(Icons.notifications, size: iconSize),
              onPressed: () {
                // Add notification functionality here
              },
            ),
            IconButton(
              color: Colors.white,
              icon: Icon(Icons.filter_list, size: iconSize),
              onPressed: _showFilterDialog,
            ),
          ]
              : null,
        ),
        drawer: Drawer(
          child: Container(
            color: Colors.white,
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  child: Text(
                    'Projlujo',
                    style: TextStyle(color: Colors.white, fontSize: fontSizeFactor * 1.2),
                  ),
                  decoration: BoxDecoration(color: Colors.blue),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.list,
                  title: 'Cases',
                  isSelected: _tabController!.index == 0,
                  onTap: () => _tabController!.animateTo(0),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.star,
                  title: 'Favorites',
                  isSelected: _tabController!.index == 1,
                  onTap: () => _tabController!.animateTo(1),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.person,
                  title: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to Profile screen
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to Settings screen
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: _showLogoutConfirmationDialog,
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            CasesScreen(),
            FavoritesScreen(),
            DashboardScreen(),
            NotificationsScreen(),
          ],
        ),
        bottomNavigationBar: Container(
          color: Colors.blue,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(width: 4.0, color: Colors.white),
              insets: EdgeInsets.symmetric(horizontal: 50.0),
            ),
            tabs: [
              Tab(icon: Icon(Icons.list, size: iconSize)),
              Tab(icon: Icon(Icons.star, size: iconSize)),
              Tab(icon: Icon(Icons.calendar_today, size: iconSize)),
              Tab(icon: Icon(Icons.notifications, size: iconSize)),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            Map<String, String?> userData = await authService.getUserData();
            if (userData['userName'] != null && userData['userEmail'] != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      HomeScreen(userName: userData['userName']!, userEmail: userData['userEmail']!),
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
          child: Icon(Icons.home, color: Colors.white, size: iconSize),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  // Drawer item builder for consistent styling
  Widget _buildDrawerItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
        bool isSelected = false,
      }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double fontSizeFactor = screenWidth * 0.05;

    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : Colors.black, size: fontSizeFactor),
      title: Text(
        title,
        style: TextStyle(color: isSelected ? Colors.blue : Colors.black, fontSize: fontSizeFactor),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}
