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

  // Function to scale font size based on screen size
  double getFontSize(BuildContext context, double scale) {
    double screenWidth = MediaQuery.of(context).size.width;
    double baseFontSize = 16.0; // Base font size in logical pixels
    return baseFontSize + (screenWidth / 375.0 - 1) * scale; // 375 is the base width of iPhone 6
  }

  void _showAddTaskModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Task'),
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

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 6.0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              width: screenWidth * 0.85,
              height: screenHeight * 0.85,
              padding: EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header section with task name and info icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              task['status'] ?? 'Task Name',
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
                                  builder: (context) => PanelInfoScreen(task: task),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      Divider(height: 1, color: Colors.grey[400]),

                      // Task cards with avatars
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(), // Prevent ListView from scrolling inside SingleChildScrollView
                        padding: const EdgeInsets.only(top: 10),
                        itemCount: taskData.length,
                        itemBuilder: (context, index) {
                          final taskItem = taskData[index];
                          final taskName = taskItem['task'];
                          final avatar = taskItem['avatar'];

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                title: Flexible(
                                  child: Text(
                                    taskName,
                                    style: TextStyle(
                                      fontSize: getFontSize(context, 2), // Dynamically scaled font size
                                      fontWeight: FontWeight.bold,
                                      overflow: TextOverflow.ellipsis, // Prevent overflow
                                    ),
                                  ),
                                ),
                                trailing: CircleAvatar(
                                  child: Text(
                                    avatar['text'],
                                    style: TextStyle(fontSize: getFontSize(context, 1.5)), // Dynamic avatar text size
                                  ),
                                  backgroundColor: avatar['backgroundColor'],
                                  foregroundColor: Colors.white,
                                  radius: 15,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PanelDetailsScreen(task: taskData[index]),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      Spacer(), // Pushes the Add Task button to the bottom
                      Divider(height: 1, color: Colors.grey[400]),
                      SizedBox(height: 8),
                      // Add Task Button
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: ElevatedButton(
                          onPressed: _showAddTaskModal,
                          style: ElevatedButton.styleFrom(
                            textStyle: TextStyle(fontSize: getFontSize(context, 1.0)), // Dynamically scaled font size for the text
                            padding: EdgeInsets.symmetric(horizontal: 9.0, vertical: 5.0), // Adjust padding for button size
                            minimumSize: Size(15, 15), // Adjust minimum size of the button (width, height)
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add,
                                color: Colors.black,
                                size: 18.0, // Icon size (you can adjust this size as needed)
                              ),
                              SizedBox(width: 8), // Adjust space between icon and text
                              Text(
                                'Add Task',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: getFontSize(context, 1.2), // Dynamically scaled font size for text
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
