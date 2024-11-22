import 'package:flutter/material.dart';
import 'package:flutter_tms/ui/widgets/custom_expansion_tile.dart' as customExpansionTile;

class PanelInfoScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const PanelInfoScreen({Key? key, required this.task}) : super(key: key);

  @override
  _PanelInfoScreenState createState() => _PanelInfoScreenState();
}

class _PanelInfoScreenState extends State<PanelInfoScreen> {
  final TextEditingController _taskNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final screenWidth = MediaQuery.of(context).size.width; // Get screen width
    final screenHeight = MediaQuery.of(context).size.height; // Get screen height

    // Adjust font size and padding based on screen width
    double padding = screenWidth * 0.04; // Dynamic padding
    double fontSizeTitle = screenWidth * 0.045; // Dynamic font size for titles
    double fontSizeContent = screenWidth * 0.04; // Dynamic font size for content
    double avatarSize = screenWidth * 0.05; // Avatar size based on screen width

    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: Text(
          "Panel Details",
          style: TextStyle(fontSize: fontSizeTitle, fontWeight: FontWeight.bold),
        ),
        elevation: 6.0, // Shadow effect
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(padding), // Responsive padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name box (non-expandable)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(screenWidth * 0.04), // Responsive padding
                  margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_rounded, color: Colors.black),
                          SizedBox(width: screenWidth * 0.02), // Adjustable spacing
                          Text(
                            'Name',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045, // Adjust text size
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      // SizedBox(height: screenHeight * 0.02), // Adjustable spacing

                      // Text(
                      //   task['description'] ?? 'No description available.',
                      //   style: TextStyle(
                      //     fontSize: fontSizeContent, // Adjust text size
                      //     color: Colors.black87,
                      //   ),
                      // ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.01),

                // Description box (expandable) with same width as Name
                Container(
                  margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: customExpansionTile.ExpansionTile(
                    title: Row(
                      children: <Widget>[
                        Icon(Icons.description, color: Colors.black),
                        SizedBox(width: screenWidth * 0.02),
                        Text('Description', style: TextStyle(color: Colors.black)),
                      ],
                    ),
                    children: <Widget>[
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.all(padding),
                        child: Text(
                          task['details'] ?? 'No additional details available.',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.01),

                // Members box (expandable) with same width as Name
                Container(
                  margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: customExpansionTile.ExpansionTile(
                    title: Row(
                      children: <Widget>[
                        Icon(Icons.people, color: Colors.black),
                        SizedBox(width: screenWidth * 0.02),
                        Text('Members', style: TextStyle(color: Colors.black)),
                      ],
                    ),
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.all(padding),
                        child: Wrap(
                          spacing: screenWidth * 0.02, // Adjustable spacing between avatars
                          runSpacing: screenHeight * 0.015, // Adjustable spacing
                          children: <Widget>[
                            CircleAvatar(
                              radius: avatarSize, // Adjust avatar size
                              backgroundColor: Colors.blue, // Set blue color
                              child: Text("A", style: TextStyle(color: Colors.white)), // Text color to white
                            ),
                            CircleAvatar(
                              radius: avatarSize, // Adjust avatar size
                              backgroundColor: Colors.blue, // Set blue color
                              child: Text("B", style: TextStyle(color: Colors.white)), // Text color to white
                            ),
                            // Add more member avatars as needed
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
