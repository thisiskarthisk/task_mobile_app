import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_tms/api/authService.dart';
import './common/commonService.dart';
import 'case_details.dart';

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Map<String, dynamic>> userCompanyCases = [];
  bool isLoading = true;
  String? _appUrl;
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
    final instances = await _service.getSavedInstances();
    for (var instance in instances) {
      final domainUrl = instance['domain_url'];
      if (domainUrl != null) {
        _appUrl = domainUrl;
        _fetchCases(domainUrl);
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

  Future<void> _fetchCases(String domainUrl) async {
    final taskAccessToken = await _authService.getIdt();

    setState(() {
      _taskAccessToken = taskAccessToken;
    });

    try {
      final String url = '$domainUrl/api/v1/user/company/cases?companyId=$_selectedCompanyId';
      print('Fetching cases from URL: $url');

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
      print('Error fetching cases: $e');
    }
  }

  // Filter for favorite cases
  List<Map<String, dynamic>> get favoriteCases {
    return userCompanyCases.where((task) => task['isFavorite'] == true).toList();
  }

  // Toggle favorite status (add or remove from favorites)
  void _toggleFavorite(Map<String, dynamic> task) {
    setState(() {
      task['isFavorite'] = !(task['isFavorite'] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width and height using MediaQuery
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Define some dynamic values based on screen size
    double padding = screenWidth * 0.05; // 5% padding
    double fontSize = screenWidth < 600 ? 18 : 24; // Smaller font size on smaller screens

    final favoriteCases = userCompanyCases.where((task) => task['starred'] == 1).toList();     // Filter the cases where starred == 1 (true favorite cases)

    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : favoriteCases.isEmpty
          ? const Center(child: Text('No favorite cases available.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: favoriteCases.length,
        itemBuilder: (context, index) {
          final task = favoriteCases[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CaseDetailsScreen(task: task),
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
                      onPressed: () { _toggleFavorite(task);},
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
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.blue[600],
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: task['progress'] ?? 0.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 5),
                              Text(
                                task['case_type'] ?? 'Job Type',
                                style: TextStyle(
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
}
