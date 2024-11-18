import 'package:flutter/material.dart';
import 'package:flutter_tms/ui/widgets/custom_expansion_tile.dart' as customExpansionTile;
import 'package:intl/intl.dart';  // Add this line

class PanelDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const PanelDetailsScreen({Key? key, required this.task}) : super(key: key);

  @override
  _PanelDetailsScreenState createState() => _PanelDetailsScreenState();
}
class _PanelDetailsScreenState extends State<PanelDetailsScreen> {
  final TextEditingController _messageController = TextEditingController();

  // Calendar Info Controllers
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize fields with existing data or placeholders
    _startDateController.text =
        widget.task['calendarInfo'] ? ['startDate'] ?? 'Select Start Date';
    _endDateController.text =
        widget.task['calendarInfo'] ? ['startTime'] ?? 'Select Start Time';
    _startTimeController.text =
        widget.task['calendarInfo'] ? ['endDate'] ?? 'Select End Date';
    _endTimeController.text =
        widget.task['calendarInfo'] ? ['endTime'] ?? 'Select End Time';
  }

  // Data Picker Function
  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101)
    );
    if (pickedDate != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  // Time picker function
  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        controller.text = pickedTime.format(context); // Format time for display
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600; // Example of determining small screen

    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: Text(
          task['name'] ?? task['task'] ?? 'Task Name',
          style: TextStyle(
            fontSize: screenWidth * 0.05, // Adjust font size based on screen width
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        elevation: 6.0,
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04), // Responsive padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Non-expandable Description Section
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
                          Icon(Icons.description, color: Colors.black),
                          SizedBox(width: screenWidth * 0.02), // Adjustable spacing
                          Text(
                            'Description',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045, // Adjust text size
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.02), // Adjustable spacing
                      Text(
                        task['description'] ?? 'No description available.',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04, // Adjust text size
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                // Members Section (Expandable)
                buildExpandableSection(
                  title: 'Members',
                  icon: Icons.people,
                  contentWidget: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: screenWidth * 0.02, // Adjustable spacing
                        runSpacing: screenHeight * 0.015, // Adjustable spacing
                        children: [
                          buildMemberAvatar(
                              'P', 'Praveen', 'Member', Colors.blue,
                              Colors.white),
                          buildMemberAvatar(
                              'K', 'Karthik', 'Member', Colors.blue,
                              Colors.white),
                          buildMemberAvatar(
                              'A', 'Ajay', 'Member', Colors.blue, Colors.white),
                          buildMemberAvatar(
                              'A', 'Abinash', 'Member', Colors.blue,
                              Colors.white),
                          buildMemberAvatar(
                              'M', 'Murali', 'Member', Colors.blue,
                              Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),

                // Calendar Info Section
                buildExpandableSection(
                  title: 'Calendar Info',
                  icon: Icons.calendar_today,
                  contentWidget: buildCalendarInfoContent(),
                ),


                // Reminder Section
                buildExpandableSection(
                  title: 'Reminder',
                  icon: Icons.alarm,
                  contentWidget: buildReminderFields(),
                ),

                // Task Completion Section
                buildExpandableSection(
                  title: 'Task Completion',
                  icon: Icons.check_circle_outline,
                  content: task['completionStatus'] ?? 'No status available.',
                ),

                // Checklist Section
                buildExpandableSection(
                  title: 'Checklist',
                  icon: Icons.checklist,
                ),


                // Attachments Section
                buildExpandableSection(
                  title: 'Attachments',
                  icon: Icons.attach_file,
                ),

                // Activity Section
                buildExpandableSection(
                  title: 'Activity',
                  icon: Icons.history,
                  contentWidget: buildActivitySection(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // Helper function to build each expandable section
  Widget buildExpandableSection({
    required String title,
    required IconData icon,
    String? content,
    Widget? contentWidget,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: customExpansionTile.ExpansionTile(
        title: Row(
          children: [
            Icon(icon, color: Colors.black),
            SizedBox(width: 8),
            Text(title, style: TextStyle(color: Colors.black)),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: contentWidget ??
                Text(content ?? '', style: TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  // Calendar Info Section with Date and Time Pickers
  Widget buildCalendarInfoContent() {
    return Column(
      children: [
        Row(
          children: [
            // Start Date Field
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Start Date:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  TextFormField(
                    controller: _startDateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'Select Start Date',
                      hintStyle: TextStyle(color: Colors.black54),
                      suffixIcon: Icon(
                          Icons.calendar_today, color: Colors.blue),
                      border: UnderlineInputBorder(),
                    ),
                    onTap: () => _selectDate(_startDateController),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10),

            // Start Time Field
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Start Time:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  TextFormField(
                    controller: _startTimeController,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'Select Start Time',
                      hintStyle: TextStyle(color: Colors.black54),
                      suffixIcon: Icon(Icons.access_time, color: Colors.blue),
                      border: UnderlineInputBorder(),
                    ),
                    onTap: () => _selectTime(_startTimeController),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 15),

        Row(
          children: [
            // End Date Field
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('End Date:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  TextFormField(
                    controller: _endDateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'Select End Date',
                      hintStyle: TextStyle(color: Colors.black54),
                      suffixIcon: Icon(Icons.calendar_today, color: Colors.blue),
                      border: UnderlineInputBorder(),
                    ),
                    onTap: () => _selectDate(_endDateController),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10),

            // End Time Field
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('End Time:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  TextFormField(
                    controller: _endTimeController,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'Select End Time',
                      hintStyle: TextStyle(color: Colors.black54),
                      suffixIcon: Icon(Icons.access_time, color: Colors.blue),
                      border: UnderlineInputBorder(),
                    ),
                    onTap: () => _selectTime(_endTimeController),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Function to build three fields in a row (two text fields and one dropdown)
  Widget buildReminderFields() {
    // Example dynamic values for the dropdown
    List<String> dropdownValues = ['Normal', 'Medium', 'High'];

    return Row(
      children: [
        // First Text Field (Underline)
        Expanded(
          child: TextFormField(
            decoration: InputDecoration(
              hintText: 'Enter text here',
              hintStyle: TextStyle(color: Colors.black54),
              border: UnderlineInputBorder(),
            ),
          ),
        ),
        SizedBox(width: 10),

        // Second Text Field (Underline)
        Expanded(
          child: TextFormField(
            decoration: InputDecoration(
              hintText: 'Enter text here',
              hintStyle: TextStyle(color: Colors.black54),
              border: UnderlineInputBorder(),
            ),
          ),
        ),
        SizedBox(width: 10),

        // Dropdown Field (Dynamic values)
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              border: UnderlineInputBorder(),
            ),
            value: null, // Default value (null means no value selected initially)
            items: dropdownValues.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (value) {
              // Handle dropdown selection change
              print('Selected value: $value');
            },
            hint: Text('Select Option'),
          ),
        ),
      ],
    );
  }


  // Function to build Activity Section
  Widget buildActivitySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              children: [
                // Message Icon on the left
                IconButton(
                  icon: Icon(Icons.message, color: Colors.blue), onPressed: () {  },
                ),

                // TextField with placeholder text
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Enter the comment", // Placeholder text
                        contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue), // Underline style
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.send, color: Colors.blue),  // Send icon
                          onPressed: () {
                            // Action for send button, could be to send the message
                            print('Message sent: ${_messageController.text}');
                            _messageController.clear(); // Clear the text after sending
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // Mic Icon on the right
                IconButton(
                  icon: Icon(Icons.mic, color: Colors.blue),
                  onPressed: () {
                    // Add functionality for mic icon, e.g., start voice recording
                    print('Mic icon pressed');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Function to create CircleAvatar with onTap that opens a modal showing the full name
  Widget buildMemberAvatar(String initial, String fullName,String role, Color backgroundColor, Color foregroundColor) {
    return GestureDetector(
      onTap: () {
        // Show a dialog with the full name
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Member Details'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(fullName, style: TextStyle(fontSize: 16)),
                  Divider(height: 1, color: Colors.grey[400]),

                  // Name and Role Gap
                  SizedBox(height: 20,),

                  // Role
                  Text('Role', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(role, style: TextStyle(fontSize: 16)),
                  Divider(height: 1, color: Colors.grey[400]),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text('Close'),
                ),
              ],
            );
          },
        );
      },

      child: CircleAvatar(
        backgroundColor: backgroundColor,  // Set the background color dynamically
        foregroundColor: foregroundColor,   // Set the text color dynamically
        child: Text(initial),
      ),
    );
  }
}
