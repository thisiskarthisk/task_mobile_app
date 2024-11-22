import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:flutter_tms/ui/screen/auth/login.dart';
import 'package:flutter_tms/ui/screen/notifications.dart';
import 'package:flutter_tms/ui/screen/task_info.dart';
import 'package:flutter_tms/api/authService.dart';
import 'package:flutter_tms/api/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './common/commonService.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  const HomeScreen({super.key, required this.userName, required this.userEmail});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isCompanyInfoVisible = false;
  bool isCompanyLoading = false;
  String? _authToken;
  String? _appUrl;
  String? _taskAccessToken; // State to control visibility of horizontal card


  final AuthService _authService = AuthService();
  final commonService _service = commonService();
  List<Map<String, String >> instanceList = [];
  Map<String, dynamic>? companyDetails;
  late Future<List<Map<String, String>>> _cachedInstances;


  // bool _showCompanyDetails = false;
  // String currUserName = "Karthi Sk";
  // String currUserEmail = "Karthisk@gmail.com";

  // List of apps
  // List<String> appsList = [
  //   "App 1",
  //   "App 2",
  //   "App 3"
  // ];  // For testing with multiple items

  // Map each app to a list of companies
  // Map<String, List<String>> companiesForApp = {
  //   "App 1": ["Company A", "Company B", "Company C", "Company D", "Company i", "Company k",],
  //   "App 2": ["Company E", "Company F"],
  //   "App 3": ["Company G", "Company H", "Company I"],
  // };

  // String? _selectedApp; // Track the selected app
  // String? _selectedCompany; // Track the selected company

  BoxDecoration themeGradient(BuildContext context) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.blue, Colors.lightBlueAccent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }


  @override
  void initState() {
    super.initState();
    _initializeData();
    _cachedInstances = _service.getSavedInstances();
  }

  Future<void> _initializeData() async {
    await _loadAuthToken();
    if (_authToken != null && _authToken!.isNotEmpty) {
      fetchAllCompanies();
      await _getInstances();
    } else {
      print('No valid auth token found.');
    }
  }

  Future<void> _loadAuthToken() async {
    try {
      final token = await _authService.getToken();
      final taskAccessToken = await _authService.getIdt();

      setState(() {
        _authToken = token;
        _taskAccessToken = taskAccessToken;
      });
    } catch (e) {
      print('Error loading token: $e');
    }
  }

  Future<void> _getInstances() async {
    try {
      final instance = await http.get(
        Uri.parse(ApiConfig.instanceEndpoint),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('response: ${json.decode(instance.body)}');

      if (instance.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(instance.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> data = responseData['data'];
          if (data.isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();

            // Clear old data before saving new data
            final allKeys = prefs.getKeys();
            for (String key in allKeys) {
              if (key.startsWith('auth_instance_')) {
                await prefs.remove(key);
              }
            }
            // Save all key-value pairs for each object
            for (int i = 0; i < data.length; i++) {
              final Map<String, dynamic> instance = data[i];

              final authInstanceId = instance['auth_instance_id'];
              final instanceType = instance['instance_type'];
              final domainUrl = instance['domain_url'];

              if (authInstanceId != null && instanceType != null && domainUrl != null) {
                await prefs.setString('auth_instance_id_$i', authInstanceId.toString());
                await prefs.setString('instance_type_$i', instanceType.toString());
                await prefs.setString('domain_url_$i', domainUrl);

                print('Instance $i saved: auth_instance_id=$authInstanceId, instance_type=$instanceType, domain_url=$domainUrl');
              }
            }
          } else {
            print('No instance data available.');
          }
        }

        return json.decode(instance.body);
      } else {
        print('Failed to load instances. Status Code: ${instance.statusCode}');
      }
    } catch (e) {
      print('Error fetching instances: $e');
    }
  }

  Future<void> fetchAllCompanies() async {
    final instances = await _service.getSavedInstances(); // This method retrieves all instances.
    for (var instance in instances) {
      final domainUrl = instance['domain_url'];
      if (domainUrl != null) {
        await _fetchCompanyDetails(domainUrl);
      }
    }
  }

  Future<void> _fetchCompanyDetails(String domainUrl) async {
    setState(() {
      isCompanyLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$domainUrl/api/v1/user/companies'),
        headers: {
          'Authorization': 'Bearer $_taskAccessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          companyDetails = data;
        });
        await _saveCompanyDetailsToPrefs(domainUrl, data);
        print('Company Details: $data');
      } else {
        print('Failed to load company details. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching company details: $e');
    } finally {
      setState(() {
        isCompanyLoading = false;
      });
    }
  }

  // Save the fetched company details to SharedPreferences
  Future<void> _saveCompanyDetailsToPrefs(String domainUrl, dynamic companyData) async {
    final prefs = await SharedPreferences.getInstance();

    // Generate a unique key based on the domain URL or instance ID
    final companyKey = 'company_details_$domainUrl';

    // Save the company details as a JSON string
    await prefs.setString(companyKey, json.encode(companyData));

    print('Company details for $domainUrl saved successfully.');
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
                  child:const Text("Yes"),
                  onPressed: () {
                    _authService.logout();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => LoginScreen()),
                    );
                  },
                )
              ],
          );
        }
    );
  }

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
              decoration: const BoxDecoration(
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
              child: NotificationsScreen(),
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    final double fontSizeFactor = screenWidth * 0.05;
    final double iconSize = screenWidth * 0.08;

    double _sliverAppBarHeight = screenHeight * 0.3;

    List<dynamic> companies = companyDetails?['data']['companies'] ?? [];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue,
        title: Text(
          "Home",
          style: TextStyle(color: Colors.white, fontSize: fontSizeFactor),
        ),
        elevation: 6.0,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.notifications, size: iconSize, color: Colors.white),
            onPressed: _showNotificationsScreen,
          ),
          IconButton(
            icon: Icon(Icons.power_settings_new, size: iconSize, color: Colors.white),
            onPressed: _showLogoutConfirmationDialog,
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: themeGradient(context),
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              automaticallyImplyLeading: false,
              expandedHeight: _sliverAppBarHeight,
              pinned: true,
              backgroundColor: Colors.blue,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.none,
                background: Container(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      CircleAvatar(
                        radius: screenWidth * 0.12,
                        child: Text(
                          currUserName.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).primaryColorDark,
                            fontSize: screenWidth * 0.1,
                          ),
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        '${widget.userName}!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: fontSizeFactor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.userEmail}',
                        style: TextStyle(fontSize: fontSizeFactor * 0.8, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                Container(
                  padding: EdgeInsets.only(
                    bottom: _showCompanyDetails ? screenHeight * 0.15 : screenHeight * 0.01,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                    color: Color(0xFFE0F2FF), // Light blue background
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Container(
                        alignment: Alignment.bottomLeft,
                        padding: EdgeInsets.only(top: screenHeight * 0.05, left: screenWidth * 0.05),
                        child: Text(
                          'Apps',
                          style: TextStyle(fontSize: fontSizeFactor * 1.5, fontWeight: FontWeight.w500),
                        ),
                      ),

                      // Check if there are less than 3 items to center them
                      appsList.length <= 2
                          ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: appsList.map((appName) {
                          bool isActiveApp = _selectedApp == appName;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedApp = appName;
                                _showCompanyDetails = true;
                              });
                            },
                            child: Container(
                              height: screenHeight * 0.2,
                              width: screenWidth * 0.4,
                              margin: EdgeInsets.all(screenWidth * 0.02),
                              decoration: BoxDecoration(
                                color: isActiveApp ? Colors.white : Colors.blue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  appName,
                                  style: TextStyle(color: isActiveApp ? Colors.blue : Colors.white),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      )
                          : GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, // 3 apps per row
                          childAspectRatio: 1.0, // Adjust the aspect ratio to fit the screen
                          crossAxisSpacing: 10.0, // Spacing between columns
                          mainAxisSpacing: 10.0, // Spacing between rows
                        ),
                        itemCount: appsList.length,
                        itemBuilder: (context, index) {
                          String appName = appsList[index];
                          bool isActiveApp = _selectedApp == appName;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedApp = appName; // Set the selected app
                                _showCompanyDetails = true; // Show company details
                              });
                            },
                            child: Container(
                              height: screenHeight * 0.2,
                              width: screenWidth * 0.5,
                              margin: EdgeInsets.all(screenWidth * 0.02),
                              decoration: BoxDecoration(
                                color: isActiveApp ? Colors.blue : Colors.white,
                                borderRadius: BorderRadius.circular(10), // Keeps corners rounded
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26, // Shadow color
                                    blurRadius: 4.0, // Softens the shadow
                                    offset: Offset(2, 2), // Horizontal and vertical offset of the shadow
                                    spreadRadius: 1.0, // Expands the shadow
                                  ),
                                ],                              ),
                              child: Center(
                                child: Text(
                                  appName,
                                  style: TextStyle(color: isActiveApp ? Colors.white : Colors.blue),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Company Details Section (scrollable)
                      AnimatedSize(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: _showCompanyDetails && _selectedApp != null
                            ? Container(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          color: Color(0xFFE0F2FF), // Light blue background
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: companiesForApp[_selectedApp!]?.length ?? 0,
                            itemBuilder: (context, index) {
                              String company = companiesForApp[_selectedApp!]![index];
                              bool isActiveCompany = _selectedCompany == company;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCompany = company;
                                  });
                                },
                                child: Card(
                                  color: isActiveCompany ? Colors.blue : Colors.white,
                                  margin: EdgeInsets.symmetric(vertical: 10),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blue,
                                      child: Icon(Icons.business, color: Colors.black),
                                    ),
                                    title: Text(
                                      company,
                                      style: TextStyle(color: isActiveCompany ? Colors.white : Colors.black,fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text("Role: User", style: TextStyle(color: isActiveCompany ? Colors.white : Colors.grey)),
                                    trailing: Icon(
                                      Icons.arrow_forward,
                                      color: isActiveCompany ? Colors.white : Colors.blue,
                                    ),
                                    onTap: () {
                                      // ScaffoldMessenger.of(context).showSnackBar(
                                      //   SnackBar(content: Text('Selected: $company')),
                                      // );
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TaskInfoScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                            : SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
