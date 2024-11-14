import 'package:flutter/material.dart';

class TaskDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> task;

  const TaskDetailsScreen({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width; // Get screen width
    final screenHeight = MediaQuery.of(context).size.height; // Get screen height

    // Adjust font sizes and padding based on screen width
    double padding = screenWidth * 0.04;
    double titleFontSize = screenWidth * 0.07;
    double headingFontSize = screenWidth * 0.045;
    double contentFontSize = screenWidth * 0.04;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          "Task Details",
          style: TextStyle(fontSize: titleFontSize),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(padding), // Responsive padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task['name'] ?? 'Task Name',
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: screenHeight * 0.02), // Responsive spacing
            _buildDetailRow('Assigned to:', task['assignee'], headingFontSize, contentFontSize),
            _buildDetailRow('Start Date:', task['startDate'], headingFontSize, contentFontSize),
            _buildDetailRow('End Date:', task['endDate'], headingFontSize, contentFontSize),
            SizedBox(height: screenHeight * 0.02),
            Text(
              'Details:',
              style: TextStyle(fontSize: headingFontSize, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            SizedBox(height: screenHeight * 0.01),
            Container(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                task['details'] ?? 'No additional details available.',
                style: TextStyle(fontSize: contentFontSize, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String heading, String? value, double headingFontSize, double contentFontSize) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: TextStyle(
              fontSize: headingFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(
                fontSize: contentFontSize,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
