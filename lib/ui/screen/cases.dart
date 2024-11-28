import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:flutter_tms/ui/screen/panel.dart';
import 'package:flutter_tms/ui/screen/case_details.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './common/commonService.dart';
import 'package:flutter_tms/api/authService.dart';

class CasesScreen extends StatefulWidget {
  @override
  _CasesScreenState createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {

  List<Map<String, dynamic>> userCompanyCases = [];
  List<Map<String, dynamic>> caseTypes = [];
  bool isLoading = true;
  bool starred = false;
  String? _taskAccessToken;
  int? _selectedCompanyId;

  final AuthService _authService = AuthService();
  final commonService _service = commonService();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadSelectedCompanyIdFromPrefs();
    await _getInstance();
  }

  Future<void> _getInstance() async {
    final instances = await _service.getSavedInstances(); // This method retrieves all instances.
    for (var instance in instances) {
      final domainUrl = instance['domain_url'];
      if (domainUrl != null) {
        _fetchCaseTypes(domainUrl);
      }
    }
  }

  Future<void> _loadSelectedCompanyIdFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedCompanyId = prefs.getInt('selected_company_id');

    print('selected_company_id: $selectedCompanyId');

    setState(() {
      _selectedCompanyId = selectedCompanyId;
    });
  }

  // Method to fetch case types from API using the domain URL
  Future<void> _fetchCaseTypes(String domainUrl) async {
    final taskAccessToken = await _authService.getIdt();
    setState(() {
      _taskAccessToken = taskAccessToken;
    });
    try {
      final String url = '$domainUrl/api/v1/user/company/casetypes?companyId=$_selectedCompanyId';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_taskAccessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('url: cases: $url');
      print('response: cases: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final dynamic caseTypesData = responseData['data']['caseTypes'];
        await _getUserCompanyCases(domainUrl);
        // Assuming the response data has a "data" key containing the list of case types
        setState(() {
          caseTypes = List<Map<String, dynamic>>.from(caseTypesData);
          isLoading = false; // Set loading state to false after fetching data
        });
      } else {
        setState(() {
          isLoading = false;
        });
        throw Exception('Failed to load case types');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching case types: $e');
    }
  }

  Future<void> _getUserCompanyCases(String domainUrl, {String caseType = "", bool starred = false}) async { // Method to fetch cases based on selected case types and other filters
    setState(() {
      isLoading = true; // Start loading state
    });
    try {
      String params = ""; // Build query parameters dynamically
      if ( caseType.isNotEmpty ) {
        params += "&caseType=$caseType";
      }
      if (starred) {
        params += "&starred=1";
      }
      final String url = '$domainUrl/api/v1/user/company/cases?companyId=$_selectedCompanyId$params';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_taskAccessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final dynamic casesData = responseData['data']['cases'];
        setState(() {
          userCompanyCases = List<Map<String, dynamic>>.from(casesData);
          isLoading = false; // Stop loading after fetching cases
        });
      } else {
        setState(() {
          isLoading = false;
        });
        throw Exception('Failed to load user company cases');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      userCompanyCases = [];
      print('Error fetching user company cases: $e');
    }
  }

  List<Map<String, dynamic>> get favoriteCases {
    return userCompanyCases.where((task) => task['isFavorite'] == true).toList();
  }

  // Toggle favorite status
  void toggleFavorite(int index) {
    setState(() {
      userCompanyCases[index]['starred'] = !(userCompanyCases[index]['starred']);
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;  // Get screen width
    double screenHeight = MediaQuery.of(context).size.height; // Get screen height
    double padding = screenWidth * 0.05; // Dynamic padding based on screen size
    final double iconSize = screenWidth * 0.08;

    return Scaffold(
      backgroundColor: Colors.blue,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : userCompanyCases.isEmpty
          ? Center(child: Text('No cases available.'))
          : ListView.builder(
        padding: EdgeInsets.all(padding),
        itemCount: userCompanyCases.length,
        itemBuilder: (context, index) {
          final task = userCompanyCases[index];
          return GestureDetector(
            onTap: () async {
              // final prefs = await SharedPreferences.getInstance();
              // await prefs.setString('caseId', task['id']);
              //
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PanelScreen(task: task),
                ),
              );
            },
            child: Container(
              margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01), // Vertical margin based on screen height
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.04), // Dynamic padding
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.star,
                        color: task['starred'] == 1
                            ? Colors.amber
                            : Colors.grey,
                      ),
                      onPressed: () => toggleFavorite(index),
                    ),

                    SizedBox(width: screenWidth * 0.02), // Gap between icon and task info

                    Container(
                      height: screenHeight * 0.03, // Dynamic divider height
                      child: VerticalDivider(
                        thickness: 1,
                        width: 5,
                        color: Colors.grey,
                      ),
                    ),

                    SizedBox(width: screenWidth * 0.04),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task['name'] ?? 'Task Name',
                            style: TextStyle(
                              fontSize: screenWidth < 600 ? 14 : 16, // Adjust font size based on screen size
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),

                          // Progress Bar
                          Row(
                            children: [
                              Container(
                                height: 10,
                                width: screenWidth * 0.25, // Dynamic width based on screen width
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.blue[600], // Background of the progress bar
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: task['progress'] ?? 0.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: Colors.green, // Blue color for progress
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Text(
                                task['case_type'] ?? 'Job Type',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: screenWidth < 600 ? 12 : 14, // Adjust font size based on screen size
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Info icon to navigate to TaskDetailsScreen
                    IconButton(
                      icon: Icon(Icons.info_rounded,size: iconSize,),
                      color: Colors.blue,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CaseDetailsScreen(task: task),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Widget for loading screen
  Widget bodyWidget() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }
}



