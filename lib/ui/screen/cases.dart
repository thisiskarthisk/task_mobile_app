import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:flutter_tms/ui/screen/task_details.dart';
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

  void toggleFavorite(int index) {
    setState(() {
      userCompanyCases[index]['starred'] =
      !(userCompanyCases[index]['starred']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : userCompanyCases.isEmpty
          ? Center(child: Text('No cases available.'))
          : ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemCount: userCompanyCases.length,
        itemBuilder: (context, index) {
          final task = userCompanyCases[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      TaskDetailsScreen(task: task),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                    const SizedBox(width: 1),
                    const SizedBox(
                      height: 30,
                      child: VerticalDivider(
                        thickness: 1,
                        width: 5,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task['name'] ?? 'Task Name',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Container(
                                height: 10,
                                width: 80,
                                decoration: BoxDecoration(
                                  borderRadius:
                                  BorderRadius.circular(4),
                                  color: Colors.blue[600],
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: task['progress'] ?? 0.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius:
                                      BorderRadius.circular(4),
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                task['case_type'] ?? 'Job Type',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TaskDetailsScreen(task: task),
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
