import 'package:flutter/material.dart';
import 'package:flutter_tms/ui/widgets/custom_expansion_tile.dart' as customExpansionTile;
import 'package:intl/intl.dart';  // Add this line
import 'package:dropdown_search/dropdown_search.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';


class PanelDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const PanelDetailsScreen({Key? key, required this.task}) : super(key: key);

  @override
  _PanelDetailsScreenState createState() => _PanelDetailsScreenState();
}

class ChecklistItem {
  bool isChecked;
  String text;

  ChecklistItem({required this.isChecked, required this.text});
}

class _PanelDetailsScreenState extends State<PanelDetailsScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _taskNameController = TextEditingController();

  int? completionTypeValue;
  int? approvalRequiredValue;

  // Variables for dropdown selections
  String? autoStartTaskValue;
  String? nameValue;
  String? name2Value;

  String? completionType = 'Manual';  // Default Completion Type
  String? approvalRequired = 'Yes';  // Default Approval Required
  String? autoStartTask;  // Auto Start Task dropdown value


  // Calendar Info Controllers
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  // Checklist Data
  List<ChecklistItem> checklist = [
    ChecklistItem(isChecked: false, text: "First item"),
  ];

  // State to track unsaved changes
  bool hasUnsavedChanges = false;


  String? _fileName;
  String? _filePath;


  // List to store file attachments
  List<String> _attachments = [];

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _taskNameController.text = widget.task['task'] ?? 'Task Name';  // Initialize task name

  }

  @override
  void _initializeForm() {
    // super.initState();
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

  // Function to open Task Options Menu
  void _openTaskOptionsMenu() async {
    final result = await showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 48, // Right side of the screen
        kToolbarHeight, // Below the AppBar
        0.0, // Left
        0.0, // Top
      ),
      items: [
        PopupMenuItem<int>(
          value: 1,
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.black), // Icon for "Change Task Name"
              SizedBox(width: 8),
              Text('Change Task Name'),
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: 2,
          child: Row(
            children: [
              Icon(Icons.checklist,color: Colors.black),
              SizedBox(width: 8),
              Text("Add Checklist Group")
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: 3,
          child: Row(
            children: [
              Icon(Icons.attach_file,color: Colors.black),
              SizedBox(width: 8),
              Text("Attach File")
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: 4,
          child: Row(
            children: [
              Icon(Icons.link,color: Colors.black),
              SizedBox(width: 8),
              Text("Attach Link")
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: 5,
          child: Row(
            children: [
              Icon(Icons.close,color: Colors.black),
              SizedBox(width: 8),
              Text("Close Task")
            ],
          ),
        ),
      ],
      elevation: 8.0,
    );

    // Handling the selected option
    if (result != null) {
      switch (result) {
        case 1:
          _showChangeTaskNameDialog();
          break;
        case 2:
          _showAddChecklistGroupDialog();
          break;
        case 3:
          _showAttachFileDialog();
          break;
        case 4:
          _showAttachLinkDialog();
          break;
        case 5:
          _showCloseTaskDialog();
          break;
        default:
          break;
      }
    }
  }

  // Dialog to change task name
  void _showChangeTaskNameDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Change Task Name'),
          content: TextField(
            controller: _taskNameController,
            decoration: InputDecoration(hintText: 'Enter new task name'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Change'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                // Handle saving task name
                setState(() {
                  // Update task name in the task object or other handling logic
                  widget.task['task'] = _taskNameController.text;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Dialog to add checklist group
  void _showAddChecklistGroupDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Checklist Group'),
          content: TextField(
            decoration: InputDecoration(hintText: 'Group Name'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                // Add checklist group logic here
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

// Method to show the file picker and then display the file name and icon
  Future<void> _showAttachFileDialog() async {
    // Open the file picker
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    // Check if the user selected a file
    if (result != null) {
      // Get the file name and path
      String fileName = result.files.single.name;
      String filePath = result.files.single.path ?? 'Unknown Path';

      setState(() {
        _fileName = fileName;
        _filePath = filePath;
      });
      // setState(() {
      //   _attachments.add({
      //     _fileName = fileName,
      //   } as String);
      // });

      // Show a dialog with the selected file details
      _showFileDetails(fileName, filePath);
    } else {
      // No file selected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No file selected')),
      );
    }
  }

  // Method to show selected file details in a dialog
  void _showFileDetails(String fileName, String filePath) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Selected File'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Text('File Name: $fileName'),
              TextField(
                controller: TextEditingController(text: fileName), // Initializes the TextField with the file name
                readOnly: true, // Makes the TextField read-only so users can't edit it
                decoration: InputDecoration(
                  labelText: 'File Name',
                  labelStyle: TextStyle(color: Colors.blue), // Optional: color for the label
                  hintText: 'File Name',
                  hintStyle: TextStyle(color: Colors.black54),
                  border: UnderlineInputBorder(), // Adds the underline
                ),
              )
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Attach'),
              onPressed: () {
                setState(() {
                  // Add file to attachment list
                  _attachments.add(fileName);
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Dialog to attach link
  void _showAttachLinkDialog() {
    TextEditingController groupNameController = TextEditingController();
    TextEditingController groupLinkController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Attach Link',style: TextStyle(fontSize: 25),),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Ensure the dialog doesn't expand unnecessarily
            children: [
              TextField(
                controller: groupNameController, // Controller for the first TextField
                decoration: InputDecoration(hintText: 'Name'),
              ),
              SizedBox(height: 10), // Add some space between the fields
              TextField(
                controller: groupLinkController, // Controller for the second TextField
                decoration: InputDecoration(hintText: 'Link'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Attach'),
              onPressed: () {
                // Attach link logic here
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Dialog to close task
  void _showCloseTaskDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Close Task'),
          content:Row(
            children: [
              Icon(Icons.warning,color: Colors.yellow[700],size: 20,),
              SizedBox(width: 10), // Space between icon and text
              Expanded( // Wrap the text with an Expanded widget to allow it to take up remaining space
                child: Text(
                  'Are you sure you want to close this task?',
                  style: TextStyle(
                    fontSize: 11, // Adjust font size
                    color: Colors.black87, // Text color
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('No'),
              onPressed: () {
                // Close task logic here
                Navigator.of(context).pop();
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
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              _openTaskOptionsMenu();
            },
          ),
          if (hasUnsavedChanges)
            IconButton(
              icon: Icon(Icons.check, color: Colors.white),
              onPressed: () {
                setState(() {
                  hasUnsavedChanges = false; // Simulate save
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Changes saved!')),
                );
              },
            ),
        ],
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
                  // content: task['completionStatus'] ?? 'No status available.',
                  contentWidget: buildTaskCompletionSection(),
                ),

                // Checklist Section
                buildExpandableSection(
                  title: 'Checklist',
                  icon: Icons.checklist,
                  contentWidget: buildChecklistSection(),
                ),


                // Attachments Section
                buildExpandableSection(
                  title: 'Attachments',
                  icon: Icons.attach_file,
                  contentWidget: buildFileAttachment(),
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


  // Function to buildReminderFields
  Widget buildReminderFields() {
    // Example dynamic values for the dropdown
    List<String> timeUnit = ['Minutes', 'Hours', 'Days'];
    List<String> dropdownValues = ['Normal', 'Medium', 'High'];

    return Row(
      children: [
        // First Text Field (Underline)
        Expanded(
          flex: 1,
          child: TextFormField(
            decoration: InputDecoration(
              hintText: 'Before',
              hintStyle: TextStyle(color: Colors.black54),
              border: UnderlineInputBorder(),
            ),
          ),
        ),
        SizedBox(width: 10), // Adjustable spacing

        // Second Field: Searchable Dropdown for Time Unit
        Expanded(
          flex: 2, // Adjust width proportionally
          child: DropdownSearch<String>(
            popupProps: PopupProps.menu(
              showSearchBox: true, // Enable search functionality
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  hintText: 'Search Time Unit',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            items: timeUnit,
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                hintText: "Time Unit",
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2), // Custom underline
                ),
              ),
            ),
            onChanged: (value) {
              print("Selected Time Unit: $value");
            },
          ),
        ),
        SizedBox(width: 10), // Adjustable spacing

        // Third Field: Searchable Dropdown for Priority
        Expanded(
          flex: 2, // Adjust width proportionally
          child: DropdownSearch<String>(
            popupProps: PopupProps.menu(
              showSearchBox: true,
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  hintText: 'Search Priority',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            items: dropdownValues,
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                hintText: "Priority",
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2), // Custom underline
                ),
              ),
            ),
            onChanged: (value) {
              print("Selected Priority: $value");
            },
          ),
        ),
      ],
    );
  }


  // Function to buildTaskCompletionSection
  Widget buildTaskCompletionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row for Completion Type and Approval Required
          Row(
            children: [
              // Left Side - Completion Type with radio buttons
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completion Type',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Radio<int>(
                          value: 1,
                          groupValue: completionTypeValue,
                          onChanged: (int? value) {
                            setState(() {
                              completionTypeValue = value;
                            });
                          },
                        ),
                        Text('Manual'),
                      ],
                    ),
                    Row(
                      children: [
                        Radio<int>(
                          value: 2,
                          groupValue: completionTypeValue,
                          onChanged: (int? value) {
                            setState(() {
                              completionTypeValue = value;
                            });
                          },
                        ),
                        Text('Automatic'),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 20),

              // Right Side - Approval Required with radio buttons
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Approval Required',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Radio<int>(
                          value: 1,
                          groupValue: approvalRequiredValue,
                          onChanged: (int? value) {
                            setState(() {
                              approvalRequiredValue = value;
                            });
                          },
                        ),
                        Text('Yes'),
                      ],
                    ),
                    Row(
                      children: [
                        Radio<int>(
                          value: 2,
                          groupValue: approvalRequiredValue,
                          onChanged: (int? value) {
                            setState(() {
                              approvalRequiredValue = value;
                            });
                          },
                        ),
                        Text('No'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          // Row for Auto Start Task and Name Dropdowns
          Row(
            children: [
              // Left side - Auto Start Task Dropdown
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8),
                    DropdownButton<String>(
                      value: autoStartTaskValue,
                      items: <String>['Option 1', 'Option 2', 'Option 3']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          autoStartTaskValue = newValue;
                        });
                      },
                      hint: Text('Auto Start Task'),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 20),

              // Right side - Name Dropdown
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8),
                    DropdownButton<String>(
                      value: nameValue,
                      items: <String>['John', 'Doe', 'Jane']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          nameValue = newValue;
                        });
                      },
                      hint: Text('Select Name'),
                    ),
                  ],
                ),
              ),


            ],
          ),
          SizedBox(height: 20),
          // Row for Auto Start Task and Name Dropdowns
          Row(
            children: [
              Expanded(child: Column()),
              // Right side - Name 2 Dropdown
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8),
                    DropdownButton<String>(
                      value: name2Value,
                      items: <String>['John', 'Doe', 'Jane']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          name2Value = newValue;
                        });
                      },
                      hint: Text('Select Name 2'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  // Checklist Section Widget
  Widget buildChecklistSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Checklist Items List
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: checklist.length,
          itemBuilder: (context, index) {
            return buildChecklistItem(index);
          },
        ),

        // Add New Checklist Item Field
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Add a new checklist item',
                  hintStyle: TextStyle(color: Colors.black54),
                  border: UnderlineInputBorder(),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.add, color: Colors.blue),
              onPressed: () {
                setState(() {
                  if (_messageController.text.isNotEmpty) {
                    checklist.add(ChecklistItem(isChecked: false, text: _messageController.text));
                    _messageController.clear();
                  }
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  // Checklist Item Widget
  Widget buildChecklistItem(int index) {
    return Row(
      children: [
        // Checkbox
        Checkbox(
          value: checklist[index].isChecked,
          onChanged: (value) {
            setState(() {
              checklist[index].isChecked = value!;
            });
          },
        ),

        // Editable Text Field for Checklist Item
        Expanded(
          child: TextFormField(
            initialValue: checklist[index].text,
            decoration: InputDecoration(
              border: InputBorder.none,
            ),
            onChanged: (value) {
              setState(() {
                checklist[index].text = value;
              });
            },
          ),
        ),

        // Delete Button
        IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            setState(() {
              checklist.removeAt(index);
            });
          },
        ),
      ],
    );
  }




  // buildFileAttachment function in listview
  Widget buildFileAttachment() {
    String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String currentTime = DateFormat('HH:mm:ss').format(DateTime.now());

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _attachments.length,
      itemBuilder: (context, index) {
        final attachment = _attachments[index]; // Assuming this is a Map or String
        print("attachment: $attachment");

        // Use MediaQuery to get the screen size
        double screenWidth = MediaQuery.of(context).size.width;
        double screenHeight = MediaQuery.of(context).size.height;
        double iconSize = screenWidth * 0.07; // Adjust icon size based on screen width
        double spacing = screenWidth * 0.02; // Adjust spacing based on screen width

        return Card(
          margin: EdgeInsets.symmetric(vertical: 10),
          child: ListTile(
            leading: Icon(Icons.file_copy, size: iconSize),
            title: Text(
              attachment,
              style: TextStyle(fontSize: screenWidth * 0.03,fontWeight: FontWeight.bold), // Adjust font size dynamically
            ),
            subtitle: Row(
              children: [
                SizedBox(height: spacing * 5), // Space between date and time
                Icon(Icons.calendar_today, size: iconSize * 0.7, color: Colors.grey),
                SizedBox(width: spacing),
                Text(
                  currentDate,
                  style: TextStyle(fontSize: screenWidth * 0.03),
                ),
                SizedBox(width: spacing * 2), // Space between date and time
                Icon(Icons.access_time, size: iconSize * 0.7, color: Colors.grey), // Time Icon
                SizedBox(width: spacing),
                Text(
                  currentTime,
                  style: TextStyle(fontSize: screenWidth * 0.03),
                ),
              ],
            ),
            trailing: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: screenWidth * 0.4), // Dynamic trailing width
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () => print("Download clicked"),
                            child: Icon(Icons.download, size: iconSize * 0.8),
                          ),
                          SizedBox(width: spacing),
                          GestureDetector(
                            onTap: () => print("History clicked"),
                            child: Icon(Icons.history, size: iconSize * 0.8),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.01), // Adjust space between rows dynamically
                  Flexible(
                    child: FittedBox(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () => print("Edit clicked"),
                            child: Icon(Icons.edit, size: iconSize * 0.8,color: Colors.blueAccent,),
                          ),
                          SizedBox(width: spacing),
                          GestureDetector(
                            onTap: () => print("Delete clicked"),
                            child: Icon(Icons.delete, size: iconSize * 0.8,color: Colors.red,),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
}
