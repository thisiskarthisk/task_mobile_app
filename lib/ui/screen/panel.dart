import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_tms/ui/screen/panelTaskInfo.dart';
import 'package:flutter_tms/ui/screen/panel_info.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/authService.dart';
import '../../api/apiConfig.dart';
import '../screen/panelService.dart';
import 'common/commonService.dart';

class PanelScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const PanelScreen({Key? key, required this.task}) : super(key: key);

  @override
  _PanelScreenState createState() => _PanelScreenState();
}

class _PanelScreenState extends State<PanelScreen> {
  String? _idt;
  int? _selectedCompanyId;
  int? _caseId;
  String? _appUrl;
  int? _taskType = 1;
  bool isAddTaskLoading = false;

  final commonService _service = commonService();
  final AuthService _authService = AuthService();
  final panelService _panelService = panelService();
  final ApiConfig _apiConfig = ApiConfig();

  final TextEditingController _taskNameController = TextEditingController();

  List<Map<String, dynamic>> panels = [];
  List<Map<String, dynamic>> taskData = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadAuthToken();

    final caseDetails = widget.task;
    _caseId = caseDetails['id'];

    if (_idt != null && _idt!.isNotEmpty) {
      _loadSelectedCompanyIdFromPrefs();
      await instance();
    } else {
      print('No valid auth token found.');
    }
  }

  Future<void> _loadAuthToken() async {
    try {
      final taskAccessToken = await _authService.getIdt();
      setState(() {
        _idt = taskAccessToken;
      });
    } catch (e) {
      print('Error loading token: $e');
    }
  }

  Future<void> instance() async {
    final instances = await _service.getSavedInstances(); // This method retrieves all instances.
    for (var instance in instances) {
      final domainUrl = instance['domain_url'];
      if (domainUrl != null) {
        _appUrl = domainUrl;
        _fetchCompanyCasePanelInfo();
        await _getCasesTasks(domainUrl);
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

  Future<void> _fetchCompanyCasePanelInfo() async {
    String? appUrl = _appUrl;
    int? companyId = _selectedCompanyId;
    int? caseId = _caseId;

    if (appUrl == null || companyId == null || caseId == null) {
      print('Error: Missing required parameters for API call.');
      return;
    }

    try {
      final casePanelRes = await _panelService.getCompanyCasePanels(appUrl, companyId, caseId);

      if (casePanelRes['success'] == true && casePanelRes['data'] != null) {
        final List<dynamic> fetchedPanels = casePanelRes['data']['panels'];
        for (var panel in fetchedPanels) {
          final panelId = panel['id'];
          final panelName = panel['name'];
          await _panelService.getPanelDetails(appUrl, companyId, caseId, panelId); // Fetch additional info for each panel
          setState(() {
            panels.add({'panelName': panelName, 'panelId': panelId});
          });
        }
      } else {
        throw Exception('Error: Invalid response format');
      }
    } catch (e) {
      throw Exception('Error fetching panel info: $e');
    }
  }

  // Helper method to assign colors based on the first letter of the name
  Color _getLetterColor(String letter) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.brown,
      Colors.teal,
      Colors.cyan,
      Colors.indigo,
      Colors.lime,
      Colors.amber,
      Colors.deepOrange,
      Colors.lightBlue,
      Colors.deepPurple,
      Colors.lightGreen,
      Colors.grey,
      Colors.black,
      Colors.white, // Use this with text color to avoid conflicts
      Colors.blueGrey,
      Colors.redAccent,
      Colors.greenAccent,
      Colors.yellowAccent,
      Colors.purpleAccent,
      Colors.orangeAccent,
    ];

    // Ensure the letter is uppercase
    letter = letter.toUpperCase();

    // Map A-Z to 0-25 using ASCII values
    int index = letter.codeUnitAt(0) - 'A'.codeUnitAt(0);

    // Return the corresponding color, default to black if not a letter
    return (index >= 0 && index < colors.length) ? colors[index] : Colors.black;
  }

  Future<void> _getCasesTasks(String domainUrl, [bool? showClosedTasks]) async {
    showClosedTasks = showClosedTasks == null ? false : showClosedTasks;

    try {
      final casesTasksDetails = await http.get(
        Uri.parse('$domainUrl${ApiConfig.caseTasks}?companyId=$_selectedCompanyId&caseId=$_caseId'+'${(showClosedTasks ? '&showClosedTasks=yes' : '')}'),
        headers: {
          'Authorization': 'Bearer $_idt',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (casesTasksDetails.statusCode == 200) {
        final detailsData = json.decode(casesTasksDetails.body);
        print(' details: $detailsData');
        if (detailsData['data']['panels'] != null) {
          final List<Map<String, dynamic>> newTaskData = []; // Extract and process tasks

          for (var panel in detailsData['data']['panels']) {
            for (var task in panel['tasks']) {
              final assigneeName = task['assignee'] ?? ''; // Handle missing assignee
              final firstLetter = assigneeName.isNotEmpty ? assigneeName[0].toUpperCase() : '';

              newTaskData.add({
                'task': task['name'],
                'avatar': {
                  'text': firstLetter.isNotEmpty ? firstLetter : '?',
                  'backgroundColor': Colors.blue,
                },
                'panelId': panel['id'],
                'companyId': _selectedCompanyId,
                'caseId': _caseId,
                'taskId': task['id'],
                'appUrl': _appUrl,
              });
            }
          }
          setState(() {
            taskData = newTaskData; // Update the state with new task data
          });
        } else {
          print('Error: No panels found in the response');
        }
      } else {
        print('Error: Failed to fetch task details (status code: ${casesTasksDetails.statusCode})');
      }
    } catch (e) {
      print('Error fetching task details : $e');
    }
  }

  Future<void> _addTask(int panelId, String taskName, int taskType) async {
    setState(() {
      isAddTaskLoading = true;
    });

    try {
      final addTaskUrl = '$_appUrl${ApiConfig.panelTaskAdd}'; // API Endpoint for adding a task
      final requestBody = {
        'companyId': _selectedCompanyId,
        'caseId': _caseId,
        'panelId': panelId,
        'taskName': taskName,
        'taskType': taskType,
      };

      // Send POST request
      final response = await http.post(
        Uri.parse(addTaskUrl),
        headers: {
          'Authorization': 'Bearer $_idt',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      // Handle the response
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          setState(() {
            isAddTaskLoading = false;

            _getCasesTasks(_appUrl!);
          });


        } else {
          print('Failed to add task: ${responseData['message']}');
        }
      } else {
        print('Error: Failed to add task (status code: ${response.statusCode})');
      }
    } catch (e) {
      print('Error adding task: $e');
    } finally {
      setState(() {
        isAddTaskLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    super.dispose();
  }

  // Function to scale font size based on screen size
  double getFontSize(BuildContext context, double scale) {
    double screenWidth = MediaQuery.of(context).size.width;
    double baseFontSize = 16.0;
    return baseFontSize + (screenWidth / 375.0 - 1) * scale;
  }

  void _showAddTaskModal(int panelId, int taskType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Task'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: TextField(
            controller: _taskNameController,
            decoration: InputDecoration(labelText: 'Task Name'),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add Task'),
              onPressed: () async {
                String taskName = _taskNameController.text;
                if (taskName.isNotEmpty) {
                  // Add new task logic
                  Navigator.of(context).pop();
                  _taskNameController.clear();
                  await _addTask(panelId, taskName, taskType);
                }
              },
            ),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _getTasksForPanel(int panelId) {
    return taskData.where((task) => task['panelId'] == panelId).toList();
  }

  Widget buildTaskList(BuildContext context, int panelId) {
    final filteredTasks = _getTasksForPanel(panelId);
    return ListView.builder(
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final taskItem = filteredTasks[index];
        final taskName = taskItem['task'];
        final avatar = taskItem['avatar'];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.0),
          child: Card(
            color: Colors.white,
            elevation: 0.1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            child: ListTile(
              title: Text(
                taskName,
                style: TextStyle(
                  fontSize: getFontSize(context, 1.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              trailing: CircleAvatar(
                child: Text(
                  avatar['text'],
                  style: TextStyle(
                    fontSize: getFontSize(context, 1.2),
                  ),
                ),
                backgroundColor: avatar['backgroundColor'],
                foregroundColor: Colors.white,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PanelDetailsScreen(task: taskItem),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 4.0,
      ),

      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // Enable horizontal scrolling
        child: Row(
          children: panels.map((panel) {
            return Container(
              width: screenWidth * 0.75,
              height: screenHeight * 0.95,
              margin: EdgeInsets.all(8.0),
              // padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Color(0xFFF5F5F5), // Gray background for content area
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            panel['panelName'],
                            style: TextStyle(
                              fontSize: getFontSize(context, 2), // Dynamically scaled font size
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              overflow: TextOverflow.ellipsis, // Prevent overflow
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.info_outline, color: Colors.black54),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PanelInfoScreen(task: panel),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Task List Area with gray background, scrollable content
                  Expanded(child: buildTaskList(context, panel['panelId'])),

                  // Footer section with Add Task button
                  Container(
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
                    ),

                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            // _showAddTaskModal;
                            _showAddTaskModal(panel['panelId'], _taskType!);
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add,
                                color: Colors.black, // Color for the icon, matching the link style
                                size: 18.0, // Icon size (you can adjust this size as needed)
                              ),
                              SizedBox(width: 3), // Adjust space between icon and text
                              Text(
                                'Add Task',
                                style: TextStyle(
                                  color: Colors.black, // Text color (same as link color)
                                  fontSize: getFontSize(context, 1.2), // Dynamically scaled font size for text
                                  // decoration: TextDecoration.underline, // Underline the text like a link
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
