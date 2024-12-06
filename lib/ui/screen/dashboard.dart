import 'package:flutter/material.dart';
import 'package:flutter_tms/ui/screen/panel_details.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_tms/api/authService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'common/commonService.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Map<DateTime, List<Map<String, dynamic>>> _events;
  late List<Map<String, dynamic>> _selectedEvents;
  late DateTime _selectedDay;
  late DateTime _focusedDay;

  bool isPanelLoading = true;
  String? _idt;
  String? _appUrl;
  int? _selectedCompanyId;

  final AuthService _authService = AuthService();
  final commonService _service = commonService();

  @override
  void initState() {
    super.initState();
    _events = {};
    _selectedEvents = [];
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _initialize();
  }

  Future<void> _initialize() async {
    await _initializeData();
    await instance();
  }

  Future<void> _initializeData() async {
    await _loadAuthToken();
    if (_idt != null && _idt!.isNotEmpty) {
      _loadSelectedCompanyIdFromPrefs();
      await instance();
    } else {
      print('No valid auth token found.');
    }
  }

  Future<void> instance() async {
    final instances = await _service.getSavedInstances();
    for (var instance in instances) {
      final domainUrl = instance['domain_url'];
      if (domainUrl != null) {
        _appUrl = domainUrl;
        await fetchDashBoardDetails(domainUrl);
      }
    }
  }

  Future<void> _loadAuthToken() async {
    try {
      final token = await _authService.getIdt();
      setState(() {
        _idt = token;
      });
    } catch (e) {
      print('Error loading token: $e');
    }
  }

  Future<void> _loadSelectedCompanyIdFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getInt('selected_company_id');
    setState(() {
      _selectedCompanyId = companyId;
    });
  }

  Future<void> fetchDashBoardDetails(String domainUrl) async {
    try {
      final String url =
          '$_appUrl/api/v1/user/company/dashboard/data?companyId=$_selectedCompanyId';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_idt',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          final List<dynamic> ongoingData = responseData['data']['ongoings'];
          print("ongoingData : $ongoingData");

          Map<DateTime, List<Map<String, dynamic>>> events = {};
          print("events : $events");


          for (var task in ongoingData) {
            print("task $task");
            DateTime startDate = DateTime.parse(task['start']);
            DateTime normalizedDate =
            DateTime(startDate.year, startDate.month, startDate.day);
            if (events[normalizedDate] == null) {
              events[normalizedDate] = [];
            }
            events[normalizedDate]!.add(task);
          }

          setState(() {
            _events = events;
            _selectedEvents = _getTasksForSelectedDate(_selectedDay);
            isPanelLoading = false;
          });
        } else {
          print('Error: ${responseData['message']}');
          setState(() {
            isPanelLoading = false;
          });
        }
      } else {
        print('Failed to fetch dashboard details. Status code: ${response.statusCode}');
        setState(() {
          isPanelLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching panel details: $e');
      setState(() {
        isPanelLoading = false;
      });
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedEvents = _getTasksForSelectedDate(selectedDay);
    });
  }

  List<Map<String, dynamic>> _getTasksForSelectedDate(DateTime selectedDay) {
    DateTime normalizedDay =
    DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    return _events[normalizedDay] ?? [];
  }

  // Function to scale font size based on screen size
  double getFontSize(BuildContext context, double scale) {
    double screenWidth = MediaQuery.of(context).size.width;
    double baseFontSize = 16.0;
    return baseFontSize + (screenWidth / 375.0 - 1) * scale;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        children: [
          // First container - Calendar
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(16.0),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: _onDaySelected,
              calendarFormat: CalendarFormat.month,
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  DateTime normalizedDay = DateTime(day.year, day.month, day.day);
                  int taskCount = _events[normalizedDay]?.length ?? 0;
                  return Stack(
                    children: [
                      Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 20,
                            color: focusedDay == day ? Colors.blue : Colors.black,
                          ),
                        ),
                      ),
                      if (taskCount > 0)
                        Positioned(
                          right: 5,
                          top: 34,
                          child: Container(
                            height: 15, // Set height for the badge
                            width: 15,
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              '$taskCount',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold, // Optional: Make it bolder for visibility
                              ),
                              textAlign: TextAlign.center, // Ensure centered alignment for the text
                            ),
                          ),
                        ),
                    ],
                  );
                },
                selectedBuilder: (context, day, focusedDay) {
                  DateTime normalizedDay = DateTime(day.year, day.month, day.day);
                  int taskCount = _events[normalizedDay]?.length ?? 0;

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (taskCount > 0)
                          Positioned(
                            right: 5,
                            top: 34,
                            child: Container(
                              height: 15, // Set height for the badge
                              width: 15,
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(1),
                              ),
                              child: Text(
                                '$taskCount',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold, // Optional: Make it bolder for visibility
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          // const SizedBox(height: 10.0),

          // Second container - Tasks (full height)
          Expanded(
            child: Container(
              color: Colors.blue,
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child:Text(
                      'Tasks',
                      style: TextStyle(
                        fontSize: screenWidth < 600 ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10.0),
                  isPanelLoading
                      ? Center(child: CircularProgressIndicator())
                      : _selectedEvents.isEmpty
                      ? Center(
                    child: Text(
                      'No tasks available for this date.',
                      style: TextStyle(
                        fontSize: screenWidth < 600 ? 16 : 18,
                        color: Colors.white,
                      ),
                    ),
                  )
                      : Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _selectedEvents.length,
                      itemBuilder: (context, index) {
                        final task = _selectedEvents[index];
                        return TaskCard(task: task);
                      },
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

// Task card widget for displaying individual tasks
class TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;

  TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
          onTap: () {
        // Navigate to PanelDetailsScreen and pass the task object
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PanelDetailsScreen(
              task: task, // Pass the entire task object to PanelDetailsScreen
            ),
          ),
        );
      },
      child:Container(
        width: screenWidth < 600 ? screenWidth * 0.85 : 450,
        margin: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
            ),
          ],
        ),
        padding: EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Task details on the left
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task['title'] ?? 'Task Title',
                    style: TextStyle(
                      fontSize: screenWidth < 600 ? 14 : 16,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Job Type: ${task['caseType'] ?? 'Unknown'}',
                    style: TextStyle(
                      fontSize: screenWidth < 600 ? 12 : 14,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    'Assignee: ${task['assignee'] ?? 'Unknown'}',
                    style: TextStyle(
                      fontSize: screenWidth < 600 ? 12 : 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start Date: ${task['start'] ?? 'Unknown'}',
                    style: TextStyle(
                      fontSize: screenWidth < 600 ? 12 : 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            // Circular avatar at the end
            GestureDetector(
              onTap: () {
                // Navigate to PanelDetailsScreen and pass the taskId
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PanelDetailsScreen(
                      task: task,  // Pass the whole task object
                    ),
                  ),
                );
              },
              child: CircleAvatar(
                backgroundColor: Colors.blue, // Set a default or derived background color
                foregroundColor: Colors.white,
                child: Text(
                  task['assignee'] != null && task['assignee'].isNotEmpty
                      ? task['assignee'][0].toUpperCase() // First letter of assignee name
                      : '?', // Default value if assignee is missing
                  style: TextStyle(
                    fontSize: 14, // Adjust font size as needed
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



