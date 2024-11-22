import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:flutter_tms/ui/screen/auth/login.dart';
import 'package:flutter_tms/ui/screen/notifications.dart';
import 'package:flutter_tms/api/authService.dart';
import 'package:flutter_tms/api/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './common/commonService.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  // Constructor to accept user name and email
  const HomeScreen({super.key, required this.userName, required this.userEmail});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isCompanyInfoVisible = false;
  bool isCompanyLoading = false;
  String? _authToken;
  String? _appUrl;
  String? _taskAccessToken;

  final AuthService _authService = AuthService();
  final commonService _service = commonService();
  List<Map<String, String >> instanceList = [];
  Map<String, dynamic>? companyDetails;
  late Future<List<Map<String, String>>> _cachedInstances;

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
              child: NotificationsScreen(), // Replace with your NotificationsScreen content
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    List<dynamic> companies = companyDetails?['data']['companies'] ?? [];

    return Scaffold(
      backgroundColor: Colors.blue, // Set the background color to blue
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.blue, // Background color of the AppBar
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),//Shadow color
                  blurRadius:1.5,
                  offset: const Offset(0, 5)// Position of the shadow
                ),
              ],
            ),
            child: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent, // Make AppBar background transparent
              elevation: 0, // Remove default elevation
              title: const Text(
                'Home',
                style: TextStyle(color: Colors.white),
              ),
              actions: [
                IconButton(
                  color: Colors.white,
                  icon: const Icon(Icons.notifications), // Notification icon
                  onPressed: _showNotificationsScreen,
                ),
                IconButton(
                  color: Colors.white,
                  icon: const Icon(Icons.power_settings_new), // Power off icon
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
                    child: Card(
                      elevation: 8.0, // Elevation for the user info card
                      margin: const EdgeInsets.symmetric(horizontal: 20.0),
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
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'Email: ${widget.userEmail}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32.0),

                  // Show domain host names first
                  FutureBuilder<List<Map<String, String>>>(
                    future: _cachedInstances, // Use the cached future
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator(); // Show loading indicator while fetching data
                      }
                      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text(
                          'No domain host names found.',
                          style: TextStyle(color: Colors.white),
                        );
                      }
                      return Column(
                        children: snapshot.data!.map((instance) {
                          return GestureDetector(
                            onTap: () {
                              print('Domain URL: ${instance['domain_url']}');
                              setState(() {
                                // Toggle visibility of the horizontal card
                                _isCompanyInfoVisible = !_isCompanyInfoVisible;
                                _appUrl = instance['domain_url'];
                              });
                              // You can navigate or perform any action here
                            },
                            child: Container(
                              margin: const EdgeInsets.all(20.0),
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent,
                                borderRadius: BorderRadius.circular(12.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8.0,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Domain URL:',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4.0),
                                      Text(
                                        Uri.tryParse(instance['domain_url']!)?.host ?? 'Invalid URL',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Icon(
                                    Icons.web,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 16.0),

                  // Show horizontal card if the state variable is true
                  if (_isCompanyInfoVisible)
                    ...companies.map((company) {
                      return GestureDetector(
                        onTap: () async {
                          final selectedCompanyId = company['id'];
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setInt('selected_company_id', selectedCompanyId);

                          // Navigate to task info screen when card is clicked
                          Navigator.pushNamed(context, '/task_info', arguments: _appUrl,);

                        },
                        child: Container(
                          margin: const EdgeInsets.all(20.0),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(12.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8.0,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Company Name: ${company['name'] ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis, // Handle long text gracefully
                                      maxLines: 1,
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      'Role: ${company['roles'].isNotEmpty ? company['roles'][0] : 'N/A'}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis, // Handle long text gracefully
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                              ),
                            ],
                          ),

                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
