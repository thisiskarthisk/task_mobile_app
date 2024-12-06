import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tms/ui/screen/panel.dart';
import 'package:flutter_tms/ui/widgets/custom_expansion_tile.dart' as customExpansionTile;
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:file_picker/file_picker.dart';
import '../screen/panelService.dart';

class PanelDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> task;
  const PanelDetailsScreen({Key? key, required this.task}) : super(key: key);

  @override
  _PanelDetailsScreenState createState() => _PanelDetailsScreenState();
}

// Define the ChecklistItem model
class ChecklistItem {
  bool isChecked;
  String id, text, groupName, groupId;
  TextEditingController textEditingController;

  ChecklistItem({required this.isChecked,required this.id,required this.groupId, required this.text, required this.groupName, TextEditingController? textEditingController,}) : textEditingController = textEditingController ?? TextEditingController(text: text);

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      isChecked: json['checked'] ?? false,
      text: json['name'] ?? '',
      groupName: json['groupName'] ?? '',
      groupId: json['groupId'].toString() ?? '',
      id: json['id'].toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'checked': isChecked,
      'name': text,
      'groupName': groupName,
      'groupId': groupId,
      'id': id,
    };
  }
}

class _PanelDetailsScreenState extends State<PanelDetailsScreen> {
  final panelService _panelService = panelService();
  final PanelScreen _panelScreen = PanelScreen(task: {},);

  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _taskNameController = TextEditingController();
  TextEditingController? _newCheckListGroupNameController;

  int? companyId, caseId, panelId, taskId, completionTypeValue, approvalRequiredValue;

  String? appUrl, description = '', startDueDate = '', selectedPriority, selectedTaskCompletionType, selectedReminderUnit,
      selectedApprovalRequired, taskCompletionTypeManual, approvalRequiredYes, autoStartTaskValue, nameValue, name2Value,
      autoStartTask, currentEditingField, reminderDuration, _fileName, _filePath;

  // State to track unsaved changes
  bool hasUnsavedChanges = false;
  bool _isReminderFieldFocused = false;
  FocusNode _reminderFocusNode = FocusNode();

  var taskDetails;
  // Calendar Info Controllers
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  late TextEditingController _startTimeController = TextEditingController();
  late TextEditingController _endTimeController = TextEditingController();

  List<dynamic> members = [];
  Map<String, dynamic>? taskCodelists;
  Map<String, dynamic> currEditingFieldValue = {};
  List<ChecklistItem> checklist = [];
  List<String> _attachments = [];

  Timer? _keyboardTimer;

  @override
  void initState() {
    super.initState();
    _taskNameController.text = widget.task['task'] ?? 'Task Name';  // Initialize task name
    _newCheckListGroupNameController = TextEditingController();
    _initializeForm();

    _startTimeController = TextEditingController();
    _endTimeController = TextEditingController();

    _setupKeyboardAutoClose();
  }

  Future<void> _initializeForm() async {
    appUrl = widget.task['appUrl'];
    companyId = widget.task['companyId'];
    caseId = widget.task['caseId'];
    panelId = widget.task['panelId'];
    taskId = widget.task['taskId'];

    _fetchCasePanelTaskInfo(appUrl, companyId, caseId, panelId, taskId);
  }

  void _setupKeyboardAutoClose() {
    _keyboardTimer?.cancel();
    _keyboardTimer = Timer(Duration(seconds: 30), () {
      if (_reminderFocusNode.hasFocus) {
        _reminderFocusNode.unfocus();
        setState(() {
          _isReminderFieldFocused = false;
        });
        print("Keyboard closed after 30 seconds.");
      }
    });
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _startTimeController.dispose();
    _endDateController.dispose();
    _endTimeController.dispose();
    _disposeNewCheckListFields();
    _keyboardTimer?.cancel();
    _reminderFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchCasePanelTaskInfo(appUrl, companyId, caseId, panelId, taskId) async {
    if (appUrl == null || companyId == null || caseId == null || panelId == null || taskId == null) {
      // throw Exception('Error: Missing required parameters for API call.');
      return;
    }
    try {
      final taskInfo = await _panelService.getCasePanelTaskInfo(appUrl, companyId, caseId, panelId, taskId);

      if (taskInfo == null || taskInfo['data'] == null || taskInfo['data']['taskInfo'] == null) {
        // print('Error: Unexpected API response format.');
        return;
      }

      taskDetails = taskInfo['data']['taskInfo'];
      var taskCodeLists = taskInfo['data']['codelists'];
      var checklistData = taskInfo['data']['checklist'] ?? [];

      setState(() {
        members = taskInfo['data']['members'] ?? [];
        description = taskDetails['description'] ?? 'No description available.';

        // Set the date and time values if they are available
        _startDateController.text = taskDetails['startDueDate'] ?? 'Select Start Date'; // "25-11-2024"
        _startTimeController.text = taskDetails['startDueTime'] ?? 'Select Start Time'; // "15:45"
        _endDateController.text = taskDetails['endDueDate'] ?? 'Select End Date'; // "26-11-2024"
        _endTimeController.text = taskDetails['endDueTime'] ?? 'Select End Time';

        selectedPriority = taskCodeLists['priority'][taskDetails['priority'].toString()];
        selectedReminderUnit = taskCodeLists['reminderDurationUnit'][taskDetails['reminderDurationUnit'].toString()];
        reminderDuration = taskDetails['reminderDuration']?.toString() ?? '';
        selectedTaskCompletionType = taskCodeLists['taskCompletionType'][taskDetails['taskCompletionType'].toString()];
        selectedApprovalRequired = taskCodeLists['approvalRequired'][taskDetails['approvalRequired'].toString()];

        taskCompletionTypeManual = taskCodeLists['taskCompletionType'][taskDetails['taskCompletionTypeManual'].toString()];
        approvalRequiredYes = taskCodeLists['approvalRequired'][taskDetails['approvalRequiredYes'].toString()];

        checklist = List<ChecklistItem>.from(checklistData.map((item) => ChecklistItem.fromJson(item)));

        taskCodelists = taskCodeLists;
      });
    } catch (e) {
      throw Exception('Error fetching task info: $e');
    }
  }

  _putCurrEditingValue(String key, dynamic value) {
    currEditingFieldValue[key] = value;
  }

  dynamic _getCurrEditingValue(String key) {
    return currEditingFieldValue[key];
  }

  _onBtnSaveTaskInfoClicked() {
    _updateTaskInfo();
  }

  void _disposeNewCheckListFields() {
    if (_newCheckListGroupNameController != null) {
      _newCheckListGroupNameController?.dispose();
      _newCheckListGroupNameController = null;
    }
  }

  Future<void> _updateTaskInfo() async {
    if (appUrl == null || companyId == null || caseId == null || panelId == null || taskId == null) {
      // print('Error: Missing required parameters for API call.');
      return;
    }

    try {
      if (currentEditingField != null) {
        Map<String, dynamic>? data;
        switch (currentEditingField) {
          case 'taskName':
            String? taskName = _getCurrEditingValue('taskName');

            if (taskName != null && taskName.trim().length > 0) {
              data = {'fieldName': 'taskName', 'fieldValue': taskName};
            }
            break;
          case 'startDueDate':
            String startDueDate = _startDateController.text.trim();
            String startDueTime = _startTimeController.text.trim();

            if (startDueDate.isNotEmpty) {
              String combinedStartDateTime = "$startDueDate ${startDueTime.isNotEmpty ? startDueTime : '00:00:00'}";
              data = {
                'fieldName': 'startDueDate',
                'fieldValue': combinedStartDateTime,
              };
            }
            break;
          case 'startDueTime':
            String startDueDate = _startDateController.text.trim();
            String startDueTime = _startTimeController.text.trim();

            if (startDueTime.isNotEmpty) {
              String combinedStartDateTime = "$startDueDate $startDueTime";
              data = {
                'fieldName': 'startDueTime',
                'fieldValue': combinedStartDateTime,
              };
            }
            break;
          case 'endDueDate':
            String endDueDate = _endDateController.text.trim();
            String endDueTime = _endTimeController.text.trim();

            if (endDueDate.isNotEmpty) {
              String combinedEndDateTime = "$endDueDate ${endDueTime.isNotEmpty ? endDueTime : '00:00:00'}";
              data = {
                'fieldName': 'endDueDate',
                'fieldValue': combinedEndDateTime,
              };
            }
            break;
          case 'endDueTime':
            String endDueDate = _endDateController.text.trim();
            String endDueTime = _endTimeController.text.trim();

            if (endDueTime.isNotEmpty) {
              String combinedEndDateTime = "$endDueDate $endDueTime";
              data = {
                'fieldName': 'endDueTime',
                'fieldValue': combinedEndDateTime,
              };
            }
            break;
          case 'reminderDuration':
            String? reminderDurationValue = reminderDuration;
            print('reminderDuration: $reminderDurationValue');
            if(reminderDurationValue != null && reminderDurationValue.trim().length > 0) {
              _putCurrEditingValue('reminderDuration', reminderDurationValue);
              print('reminderDuration: $reminderDuration');

              data = {
                'fieldName': 'reminderDuration',
                'fieldValue': reminderDurationValue
              };
            }
            break;
          case 'reminderDurationUnit':
            String? reminderDurationUnit = _getCurrEditingValue('reminderDurationUnit');

            if(reminderDurationUnit != null && reminderDurationUnit.trim().length > 0) {
              data = {
                'fieldName': 'reminderDurationUnit',
                'fieldValue': reminderDurationUnit
              };
            }
            break;
          case 'priority':
            String? priority = _getCurrEditingValue('priority');

            if(priority != null && priority.trim().length > 0) {
              data = {
                'fieldName': 'priority',
                'fieldValue': priority
              };
            }
            break;
          case 'checkListGroup':
            String groupName = _getCurrEditingValue('checkListGroup');

            if(groupName.isNotEmpty && groupName.trim().length > 0) {
              data = {
                'fieldName': 'checkListGroup',
                'fieldValue': groupName
              };
            }
            break;
          case 'checkList':
            String checkListIndex = _getCurrEditingValue('checkList');

            if(checkListIndex.trim().length > 0 && checkListIndex.trim().isNotEmpty) {
              int index = int.tryParse(checkListIndex) ?? -1;
              if (index >= 0 && index < checklist.length) {
                ChecklistItem _checkList = checklist[index];
                String checkListName = _checkList.textEditingController.text;

                if (checkListName.trim().isNotEmpty) {
                  data = {
                    'fieldName': 'checkList',
                    'fieldValue': {
                      'id': _checkList.id,
                      'name': checkListName,
                      'groupId': _checkList.groupId,
                      'isChecked': _checkList.isChecked,
                    },
                  };
                }
              } else {
                throw Exception("Invalid checklist index: $index");
              }
            }
            break;
          case 'deleteChecklistItem':
            String checklistId = _getCurrEditingValue('deleteChecklistItem');

            if(checklistId.isNotEmpty && checklistId.trim().length > 0) {
              data = {
                'fieldName': 'deleteChecklistItem',
                'fieldValue': checklistId
              };
            }
            break;
        }
        if (data != null && data.isNotEmpty) {
          bool isSaved = false;
          dynamic response;

          response = await _panelService.updateTaskInfo(appUrl!, companyId!, caseId!, panelId!, taskId!, data);
          // isSaved = response['success'];
          print('response: $response');

          if (response is Map<String, dynamic> && response['success'] == true) {
            await _fetchCasePanelTaskInfo(appUrl, companyId, caseId, panelId, taskId);
          }
        }
      }

    } catch (e) {
      throw Exception('Error adding task: $e');
    }
  }

  Future<void> _onFieldValueChange(String fieldName, String fieldValue) async {
    currentEditingField = fieldName;

    if (fieldValue.isNotEmpty) {
      _onBtnSaveTaskInfoClicked();
    }
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
        controller.text = DateFormat('dd-MM-yyyy').format(pickedDate);
      });
    }
  }

  // Time picker function
  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime != null) {
      setState(() {
        controller.text = selectedTime.format(context); // Format as HH:MM AM/PM
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
    _disposeNewCheckListFields();

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
                String _newTaskName = _taskNameController.text;
                if (_newTaskName.isNotEmpty && _newTaskName.length > 0) {
                  currentEditingField = 'taskName';
                  _putCurrEditingValue('taskName', _newTaskName);
                  _onBtnSaveTaskInfoClicked();
                }
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
          title: const Text('Add Checklist Group'),
          content: TextField(
            decoration: const InputDecoration(hintText: 'Group Name'),
            controller: _newCheckListGroupNameController,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                final groupName = _newCheckListGroupNameController?.text.trim() ?? '';
                Navigator.of(context).pop();
                if (groupName.isNotEmpty && groupName.trim().length > 0) {
                  currentEditingField = 'checkListGroup';
                  _putCurrEditingValue('checkListGroup', groupName);
                  _onBtnSaveTaskInfoClicked();
                }
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
                        description ?? 'No description available.',
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
                        children: members.map<Widget>((member) {
                          // Extract required values
                          String avatarInitial = member['name'][0].toUpperCase();
                          String name = member['name'];
                          String roleName = member['roleName'];

                          return buildMemberAvatar(
                            avatarInitial,
                            name,
                            roleName,
                            Colors.blue, // Avatar background color
                            Colors.white, // Text color
                          );
                        }).toList(),
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
                  contentWidget: buildFileAtteachment(),
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
                    onTap: () => _selectDate(_startDateController).then(
                          (_) => _onFieldValueChange('startDueDate', _startDateController.text),
                    ),
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
                    onTap: () => _selectTime(_startTimeController).then(
                          (_) => _onFieldValueChange('startDueTime', _startTimeController.text),
                    ),
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
                    onTap: () async {
                      await _selectDate(_endDateController);
                      _onFieldValueChange('endDueDate', _endDateController.text);
                    },
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
                    onTap: () async {
                      await _selectTime(_endTimeController);
                      print('_endTimeController: $_endTimeController');
                      // _onFieldValueChange('endDueTime', _endTimeController.text);
                    },
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
    if (taskCodelists == null) {
      return Center(child: CircularProgressIndicator());
    }

    List<String> priorityValues = taskCodelists!['priority'].values.toList().cast<String>();
    List<String> reminderUnitValues = taskCodelists!['reminderDurationUnit'].values.toList().cast<String>();

    return Row(
      children: [
        // First Text Field (Underline)
        Expanded(
          flex: 1,
          child: TextFormField(
            initialValue: reminderDuration,
            keyboardType: TextInputType.number,
            focusNode: _reminderFocusNode,
            decoration: InputDecoration(
              hintText: 'Before',
              hintStyle: TextStyle(color: Colors.black54),
              border: UnderlineInputBorder(),
            ),
            onTap: () {
              // When the user taps on the field, ensure the timer starts if it hasn't yet
              if (!_isReminderFieldFocused) {
                _isReminderFieldFocused = true;
                _reminderFocusNode.unfocus();
                _setupKeyboardAutoClose(); // Start the timer for this field
              }
            },
            onChanged: (value) {
              setState(() {
                reminderDuration = value.trim();
                if (reminderDuration!.isNotEmpty) {
                  currentEditingField = 'reminderDuration';
                  _putCurrEditingValue('reminderDuration', reminderDuration);

                  _onBtnSaveTaskInfoClicked(); // Save the updated value.
                }
              });
            },
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
            items: reminderUnitValues,
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                hintText: "Time Unit",
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2), // Custom underline
                ),
              ),
            ),
            selectedItem: selectedReminderUnit,
            onChanged: (value) {
              setState(() {
                if (value != null && reminderUnitValues.contains(value)) {
                  // Map the selected value back to its key.
                  String? selectedKey = taskCodelists!['reminderDurationUnit'].entries
                      .firstWhere((entry) => entry.value == value, orElse: () => MapEntry('', ''),
                  ).key;

                  if (selectedKey != null && selectedKey.isNotEmpty) {
                    selectedReminderUnit = value; // Displayed value.
                    currentEditingField = 'reminderDurationUnit';
                    _putCurrEditingValue('reminderDurationUnit', selectedKey); // Send key to backend.
                    _onBtnSaveTaskInfoClicked(); // Save the updated value.
                  }
                }
              });
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
            items: priorityValues,
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                hintText: "Priority",
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2), // Custom underline
                ),
              ),
            ),
            selectedItem: selectedPriority,
            onChanged: (value) {
              setState(() {
                if (value != null && priorityValues.contains(value)) {

                  String? selectedKey = taskCodelists!['priority'].entries
                      .firstWhere((entry) => entry.value == value, orElse: () => MapEntry('', ''),
                  ).key; // Map the selected value back to its key.

                  if (selectedKey != null && selectedKey.isNotEmpty) {
                    currentEditingField = 'priority';
                    _putCurrEditingValue('priority', selectedKey);
                    _onBtnSaveTaskInfoClicked();
                  }
                }
              });
            },
          ),
        ),
      ],
    );
  }

  Widget buildFileAtteachment() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _attachments.length,
      itemBuilder: (context, index) {
        final attachment = _attachments[index];  // Assuming this is a Map

        return Card(
          margin: EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: Icon(Icons.file_copy),  // File icon
            title: Text(attachment),  // Display file name
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.download),
                  onPressed: () {
                    // Implement your download action here
                  },
                ),
                IconButton(
                  icon: Icon(Icons.history),
                  onPressed: () {
                    // Implement your history action here
                  },
                ),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    // Implement your edit action here
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      _attachments.removeAt(index);  // Remove the selected attachment
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Function to buildTaskCompletionSection
  Widget buildTaskCompletionSection() {
    if (taskCodelists == null) {
      return Center(child: CircularProgressIndicator());
    }

    Map<String, String> taskCompletionType = taskCodelists!['taskCompletionType'].cast<String, String>();
    Map<String, String> taskApprovalRequired = taskCodelists!['approvalRequired'].cast<String, String>();

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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: taskCompletionType.entries.map((entry) {
                        int value = int.parse(entry.key);
                        String label = entry.value;
                        completionTypeValue = int.parse(
                            taskCompletionType.entries
                                .firstWhere((entry) => entry.value == (selectedTaskCompletionType != null ? selectedTaskCompletionType : taskCompletionTypeManual))
                                .key
                        );

                        return Row(
                          children: [
                            Radio<int>(
                              value: value,
                              groupValue: completionTypeValue,
                              onChanged: (int? newValue) {
                                setState(() {
                                  completionTypeValue = newValue;
                                });
                              },
                            ),
                            Text(label),
                          ],
                        );
                      }).toList(),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: taskApprovalRequired.entries.map((entry) {
                        int value = int.parse(entry.key);
                        String label = entry.value;
                        approvalRequiredValue = int.parse(
                            taskApprovalRequired.entries
                                .firstWhere((entry) => entry.value == (selectedApprovalRequired != null ? selectedApprovalRequired : approvalRequiredYes))
                                .key
                        );
                        return Row(
                          children: [
                            Radio<int>(
                              value: value,
                              groupValue: approvalRequiredValue,
                              onChanged: (int? newValue) {
                                setState(() {
                                  approvalRequiredValue = newValue;
                                });
                              },
                            ),
                            Text(label),
                          ],
                        );
                      }).toList(),
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
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteCheckListItemModal(BuildContext context, String checklistItemId) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Delete Checklist',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.warning, color: Colors.amber),
              const SizedBox(width: 10),
              Expanded(
                child: const Text(
                  'Are you sure you want to delete the checklist?',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Close the dialog without any action
                Navigator.of(context).pop();
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                // Perform delete action
                setState(() {
                  currentEditingField = 'deleteChecklistItem';
                  _putCurrEditingValue('deleteChecklistItem', checklistItemId);
                });

                // Close the dialog
                Navigator.of(context).pop();

                // Trigger save task info
                _onBtnSaveTaskInfoClicked();
              },
              child: const Text(
                'Yes',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }


  // Build grouped checklist section
  Widget buildChecklistSection() {
    // Group checklist items by `groupName`
    final groupedChecklist = <String, List<ChecklistItem>>{};
    for (var item in checklist) {
      if (!groupedChecklist.containsKey(item.groupName)) {
        groupedChecklist[item.groupName] = [];
      }
      groupedChecklist[item.groupName]?.add(item);
    }

    // Create a map to hold TextEditingControllers for each group
    final Map<String, TextEditingController> controllers = {};

    return Column(
      children: groupedChecklist.entries.map((entry) {
        final groupName = entry.key;
        final items = entry.value;

        controllers[groupName] = TextEditingController();

        return Stack(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              padding: const EdgeInsets.only(top: 16.0, left: 12.0, right: 12.0, bottom: 12.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1.5),
                borderRadius: BorderRadius.circular(12.0),
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10.0), // Spacer for groupName
                  // Checklist Items within this group
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return buildChecklistItem(items[index]);
                    },
                  ),
                  // Add New Checklist Item to the Group
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: controllers[groupName],
                            decoration: InputDecoration(
                              hintText: 'Add a new item to $groupName',
                              hintStyle: TextStyle(color: Colors.black54),
                              border: UnderlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add, color: Colors.blue),
                          onPressed: () {
                            setState(() {
                              final newText = controllers[groupName]!.text;
                              if (newText.isNotEmpty) {

                                final groupId = checklist
                                    .firstWhere((item) => item.groupName == groupName, orElse: () => ChecklistItem(
                                        isChecked: false,
                                        text: '',
                                        groupName: groupName,
                                        groupId: 'Unknown', // Default fallback groupId
                                        id: '',
                                      ),)
                                    .groupId;

                                final newItem = ChecklistItem(
                                  isChecked: false,
                                  text: newText,
                                  groupName: groupName,
                                  groupId: groupId,
                                  id: '',
                                );
                                // items.add(newItem);
                                groupedChecklist[groupName]?.add(newItem);
                                checklist.add(newItem); // Update main checklist
                                controllers[groupName]!.clear();

                                currentEditingField = 'checkList';
                                final checklistIndex = checklist.indexOf(newItem).toString();
                                _putCurrEditingValue('checkList', checklistIndex);
                                _onBtnSaveTaskInfoClicked();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Group Name in the Border Line
            Positioned(
              left: 20.0, // Adjust to position inside the border
              top: -5.0, // Adjust to align on the border
              child: Container(
                color: Colors.white, // Background color to overlap the border
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                child: Text(
                  groupName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // Checklist Item Widget
  Widget buildChecklistItem(ChecklistItem item) {
    return item.text.isNotEmpty  // Check if the text field is not empty
        ? Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Checkbox(
            value: item.isChecked,
            onChanged: (value) {
              setState(() {
                item.isChecked = value!;
                currentEditingField = 'checkList';
                final checklistIndex = checklist.indexOf(item).toString();
                _putCurrEditingValue('checkList', '$checklistIndex');
                _onBtnSaveTaskInfoClicked();
              });
            },
          ),
          // Editable Text Field for Checklist Item
          Expanded(
            child: TextFormField(
              initialValue: item.text,
              decoration: InputDecoration(
                border: InputBorder.none,
              ),
              style: TextStyle(
                decoration: item.isChecked ? TextDecoration.lineThrough : TextDecoration.none, // Strikethrough when checked
                color: item.isChecked ? Colors.black : Colors.black, // Optional: Change color for checked items
              ),
              onChanged: (value) {
                setState(() {
                  item.text = value;
                  currentEditingField = 'checkList';
                  final checklistIndex = checklist.indexOf(item).toString();
                  _putCurrEditingValue('checkList', '$checklistIndex');
                  _onBtnSaveTaskInfoClicked();
                });
              },
            ),
          ),
          // Delete Button
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              setState(() {
                _showDeleteCheckListItemModal(context, item.id);
              });
            },
          ),
        ],
      ),
    )
        : Container(); // If text is empty, do not display anything (return an empty container)
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
