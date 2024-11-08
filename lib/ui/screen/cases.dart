import 'package:flutter/material.dart';
import 'package:flutter_tms/ui/screen/task_details.dart';

class CasesScreen extends StatefulWidget {
  @override
  _CasesScreenState createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {
  // Dummy list of tasks
  final List<Map<String, dynamic>> tasks = [
    {
      'name': 'Flutter Mobile App',
      'jobType':'Web App',
      'assignee': 'karthi Sk',
      'startDate': '2024-11-01',
      'endDate': '2024-11-10',
      'details': 'Detailed description of Task 1',
      'isFavorite': false,
      'progress': 0.4, // Sample progress value (40%)
    },
    {
      'name': 'Rotry and Diverty Valve',
      'jobType':'Mobile App',
      'assignee': 'Murali',
      'startDate': '2024-11-02',
      'endDate': '2024-11-11',
      'details': 'Detailed description of Task 2',
      'isFavorite': false,
      'progress': 0.7, // Sample progress value (70%)
    },
    {
      'name': 'Whatsapp Message Send Meta',
      'jobType':'Mac App',
      'assignee': 'Ajay',
      'startDate': '2024-11-03',
      'endDate': '2024-11-12',
      'details': 'Detailed description of Task 3',
      'isFavorite': false,
      'progress': 0.9, // Sample progress value (90%)
    },
  ];

  // Toggle favorite status
  void toggleFavorite(int index) {
    setState(() {
      tasks[index]['isFavorite'] = !tasks[index]['isFavorite'];
    });
  }

  // Get the favorite tasks
  List<Map<String, dynamic>> get favoriteTasks {
    return tasks.where((task) => task['isFavorite'] == true).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: tasks.isEmpty
          ? bodyWidget() // Show loading widget if tasks are empty
          : ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return GestureDetector(
            onTap: () {
              // Navigate to TaskDetailsScreen when full box is clicked
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskDetailsScreen(task: task),
                ),
              );
            },
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 10),
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
                    // Star icon to mark/unmark as favorite
                    IconButton(
                      icon: Icon(
                        Icons.star,
                        color: task['isFavorite']
                            ? Colors.amber
                            : Colors.grey,
                      ),
                      onPressed: () => toggleFavorite(index),
                    ),

                    SizedBox(width: 1), // Gap between icon and task info

                    Container(
                      height: 30, // Ensure a height for the divider
                      child: VerticalDivider(
                        thickness: 1,
                        width: 5,
                        color: Colors.grey,
                      ),
                    ),

                    SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task['name'] ?? 'Task Name',
                            style: TextStyle(
                              fontSize: 13,
                              color:
                              Colors.blue, // Blue color for progress
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          // Progress Bar
                          Row(
                            children: [
                              Container(
                                height: 10,
                                width: 80,
                                // width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.blue[
                                  600], // Background of the progress bar
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: task['progress'] ??
                                      0.0, // Progress in percentage (0-1)
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: Colors
                                          .green, // Blue color for progress
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 5,),
                              Text(
                                task['jobType'] ?? 'job Type',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 13,
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                    // Info icon to navigate to TaskDetailsScreen
                    IconButton(
                      icon: Icon(Icons.info_outline),
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
