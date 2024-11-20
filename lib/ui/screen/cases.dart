import 'package:flutter/material.dart';
import 'package:flutter_tms/ui/screen/panel.dart';
import 'package:flutter_tms/ui/screen/task_details.dart';
import 'package:flutter_tms/data/jobs_data.dart';

class CasesScreen extends StatefulWidget {
  @override
  _CasesScreenState createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {

  // Toggle favorite status
  void toggleFavorite(int index) {
    setState(() {
      jobs[index]['isFavorite'] = !jobs[index]['isFavorite'];
    });
  }

  // Get the favorite tasks
  List<Map<String, dynamic>> get favoriteTasks {
    return jobs.where((job) => job['isFavorite'] == true).toList();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;  // Get screen width
    double screenHeight = MediaQuery.of(context).size.height; // Get screen height
    double padding = screenWidth * 0.05; // Dynamic padding based on screen size
    final double iconSize = screenWidth * 0.08;

    return Scaffold(
      backgroundColor: Colors.blue,
      body: jobs.isEmpty
          ? bodyWidget() // Show loading widget if tasks are empty
          : ListView.builder(
        padding: EdgeInsets.all(padding), // Apply dynamic padding
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PanelScreen(task: job),
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
                    // Star icon to mark/unmark as favorite
                    IconButton(
                      icon: Icon(
                        Icons.star,
                        color: job['isFavorite'] ? Colors.amber : Colors.grey,
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
                            job['name'] ?? 'Task Name',
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
                                  widthFactor: job['progress'] ?? 0.0, // Progress in percentage (0-1)
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
                                job['jobType'] ?? 'job Type',
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
                            builder: (context) => TaskDetailsScreen(task: job),
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



