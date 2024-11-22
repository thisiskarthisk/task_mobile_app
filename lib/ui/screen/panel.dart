import 'package:flutter/material.dart';
import 'package:flutter_tms/ui/screen/panel_details.dart';
import 'package:flutter_tms/ui/screen/panel_info.dart';

class PanelScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const PanelScreen({Key? key, required this.task}) : super(key: key);

  @override
  _PanelScreenState createState() => _PanelScreenState();
}

class _PanelScreenState extends State<PanelScreen> {
  final TextEditingController _taskNameController = TextEditingController();

  // Sample data for tasks and avatars
  final List<Map<String, dynamic>> taskData = [
    {'task': 'Mobile App', 'avatar': {'text': 'K', 'backgroundColor': Colors.green}},
    {'task': 'WhatsApp Message', 'avatar': {'text': 'A', 'backgroundColor': Colors.blue}},
    {'task': 'Rotary Valve', 'avatar': {'text': 'P', 'backgroundColor': Colors.red}},
  ];

  final List<Map<String, dynamic>> panels = [
    {'panelName': 'onGoing'},
    {'panelName': 'Holding'},
    {'panelName': 'In Process'},
  ];

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

  void _showAddTaskModal() {
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
              onPressed: () {
                String taskName = _taskNameController.text;
                if (taskName.isNotEmpty) {
                  // Add new task logic
                  Navigator.of(context).pop();
                  _taskNameController.clear();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildTaskList(BuildContext context) {
    return ListView.builder(
      itemCount: taskData.length,
      itemBuilder: (context, index) {
        final taskItem = taskData[index];
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
                  Expanded(child: buildTaskList(context)),

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
                          onPressed: _showAddTaskModal,
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
