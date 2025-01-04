import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:open_file/open_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:flutter_tms/ui/widgets/custom_expansion_tile.dart' as customExpansionTile;
import 'package:url_launcher/url_launcher.dart';

import '../screen/panel.dart';
import '../../api/authService.dart';
import '../screen/panelService.dart';

class PanelDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> task;
  const PanelDetailsScreen({Key? key, required this.task}) : super(key: key);

  @override
  _PanelDetailsScreenState createState() => _PanelDetailsScreenState();
}

class _PanelDetailsScreenState extends State<PanelDetailsScreen> {
  final panelService _panelService = panelService();
  final PanelScreen _panelScreen = PanelScreen(task: {},);
  final AuthService _authService = AuthService();

  final TextEditingController _messageController = TextEditingController(), commentsController = TextEditingController(), _taskNameController = TextEditingController();
  TextEditingController? _newCheckListGroupNameController;

  // Calendar Info Controllers
  final TextEditingController _startDateController = TextEditingController(), _endDateController = TextEditingController();
  late TextEditingController _startTimeController = TextEditingController(), _endTimeController = TextEditingController();

  just_audio.AudioPlayer player = just_audio.AudioPlayer();

  int? companyId, caseId, panelId, taskId, completionTypeValue, approvalRequiredValue ,_editingAttachmentIndex = -1,
      _deletingAttachmentIndex = -1, TaskAssignee;

  String? appUrl, description = '', startDueDate = '', selectedPriority, selectedTaskCompletionType, selectedReminderUnit,
      selectedApprovalRequired, taskCompletionTypeManual, approvalRequiredYes, autoStartTaskValue, nameValue, name2Value,
      autoStartTask, currentEditingField, reminderDuration, TaskApprover, selectedTaskApprovalType, selectedTaskCompletionAuto,
      selectedLinkedTask, _recordedAudioFilePath, _currentAudioUrl, selectedNextTask, _fileName, _filePath, taskInfoTitleName, loginUserName;

  bool hasUnsavedChanges = false, _isApprover = false, _isReminderFieldFocused = false, _isCommentsFieldFocused = false, isLoadingShown = false, _isPaused = false, _isRecording = false, _isPlaying = false, isHistoryVisible = true;

  FocusNode _reminderFocusNode = FocusNode(), editTaskNameFocusNode = FocusNode(), commentsNameFocusNode = FocusNode();
  FlutterSoundPlayer? _player = FlutterSoundPlayer();
  FlutterSoundRecorder? _recorder;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  var taskDetails;
  var sApprovers;
  List<dynamic> members = [];
  Map<String, dynamic>? taskCodelists;
  Map<String, dynamic> currEditingFieldValue = {};
  List<ChecklistItem> checklist = [];
  List<Activity> activities = [];
  List<Activity> _activities = [];
  Map<String, dynamic>? responseData;

  // File Attachment
  List<Attachment> _attachments = [];
  List<ApprovalHistory> _approvalHistory = [];
  Map<String, String>? _selectedFile;
  Timer? _keyboardTimer;
  File? newAttachFile;
  String? newAttachingFilePath;
  PlatformFile? newAttachingFile;  // Declare as nullable to safely check if it's initialized
  Map<String, bool> historyVisibility = {};
  bool refreshLayout = false;
  List<String> selectedMembers = [];

  BuildContext? get pageContext => null;

  @override
  void initState() {
    super.initState();
    _newCheckListGroupNameController = TextEditingController();
    _initializeForm();
    _recorder = FlutterSoundRecorder();
    _startTimeController = TextEditingController();
    _endTimeController = TextEditingController();
    _taskNameController.text = widget.task['task'] ?? taskInfoTitleName ?? 'Task Name';  // Initialize task name
    _setupKeyboardAutoClose();
    _initializeRecorder();
    _isCurrentUser();
    responseData = {};
  }

  Future<void> _initializeForm() async {
    appUrl = widget.task['appUrl'];
    companyId = widget.task['companyId'];
    caseId = widget.task['caseId'];
    panelId = widget.task['panelId'];
    taskId = widget.task['taskId'];

    _fetchCasePanelTaskInfo(appUrl, companyId, caseId, panelId, taskId);

    await _player!.openPlayer();
    _player = FlutterSoundPlayer();
  }

  Future<void> _initializeRecorder() async {
    await _recorder!.openRecorder();
    if (await Permission.microphone.request().isDenied) {
      await Permission.microphone.request();// Request microphone permission
    }
  }

  Future<void> openAppSettingsIfDenied() async {
    if (await Permission.manageExternalStorage.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  Future<bool> _checkAndRequestStoragePermission() async {
    if (await Permission.storage.isGranted) {
      return true; // Permission already granted
    } else if (await Permission.manageExternalStorage.isGranted) {
      return true; // MANAGE_EXTERNAL_STORAGE granted
    } else {
      final status = await Permission.manageExternalStorage.request(); // Request storage or manage external storage permission
      return status.isGranted;
    }
  }

  List<Activity> prepareActivities(dynamic rawActivities) {
    List<Activity> activities = [];

    (rawActivities as List).forEach((dynamic activity) {
      activities.add(Activity(type: activity['type'], content: activity['content'], user: activity['user'], date: activity['date'], time: activity['time'],
          audioFileName: activity['type'] == 'audio' ? activity['audioFileName'] : null, id: activity['id']));
    });
    return activities;
  }

  List<Attachment> prepareAttachments(dynamic rawAttachments) {
    List<Attachment> attachments = [];

    (rawAttachments as List).forEach((dynamic attachment) {
      attachments.add(Attachment(id: attachment['id'], name: attachment['name'], url: attachment['url'], fileName: attachment['fileName'], type: attachment['type'], date: attachment['date'], time: attachment['time']));
    });
    return attachments;
  }

  Future<void> _startRecording() async {
    try {
      await _initializeRecorder(); // Ensure the recorder is initialized
      final directory = await getTemporaryDirectory(); // Get the temporary directory to store the audio file
      final filePath = '${directory.path}/audio_comment.aac';

      if (!_recorder!.isRecording) { // Start recording only if it's not already recording
        await _recorder!.startRecorder(
          toFile: filePath,
          codec: Codec.aacADTS,
        );
        setState(() {
          _isRecording = true;
          _recordedAudioFilePath = filePath;
          _recordingSeconds = 0;
        });
        _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) { // Start a timer to track recording time
          setState(() {
            _recordingSeconds++;
          });
        });
      }
    } catch (e) {
      throw Exception("Error starting recorder: $e");
    }
  }

  Future<void> _pauseRecording() async {
    if (_recorder != null && _isRecording && !_isPaused) {
      await _recorder!.pauseRecorder();
      setState(() {
        _isPaused = true;
      });
      _recordingTimer?.cancel(); // Stop the timer when paused
    }
  }

  Future<void> _resumeRecording() async {
    if (_recorder != null && _isPaused) {
      await _recorder!.resumeRecorder();
      setState(() {
        _isPaused = false;
      });

      _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) { // Restart the timer
        setState(() {
          _recordingSeconds++;
        });
      });
    }
  }

  Future<void> _cancelRecording() async {
    if (_recorder != null && (_isRecording || _isPaused)) {
      await _recorder!.stopRecorder();
      _recordingTimer?.cancel();
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _recordingSeconds = 0;
      });
    }
  }

  Future<void> _playRecording() async { // Play the recorded audio
    if (_recordedAudioFilePath == null) return;

    if (_isPlaying) { // If already playing, pause the audio
      await _player?.pausePlayer();
      setState(() {
        _isPlaying = false;
      });
    } else {
      if (_player!.isPaused) { // If not playing, start or resume playback
        await _player?.resumePlayer(); // Resume the playback if previously paused
      } else {
        await _player?.startPlayer( // Start playback from the beginning
          fromURI: _recordedAudioFilePath,
          whenFinished: () {
            setState(() {
              _isPlaying = false; // Reset the playing state when finished
            });
          },
        );
      }
      setState(() {
        _isPlaying = true;
      });
    }
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  void _setupKeyboardAutoClose() {
    _keyboardTimer?.cancel();
    _keyboardTimer = Timer(Duration(seconds: 10), () {
      if (_reminderFocusNode.hasFocus) {
        _reminderFocusNode.unfocus();
        setState(() {
          _isReminderFieldFocused = false;
        });
      }
      if (commentsNameFocusNode.hasFocus) {
        commentsNameFocusNode.unfocus();
        setState(() {
          _isCommentsFieldFocused = false;
        });
      }
    });
  }

  void _onApproveButtonClicked(String comment) {
    // Logic for Approve action
    print("Approved with comment: $comment");
    _showApproveDialog(comment);
  }

  _hideLoadingDialog() {
    if(isLoadingShown) {
      Navigator.pop(pageContext!);
      isLoadingShown = false;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _startDateController.dispose();
    _startTimeController.dispose();
    _endDateController.dispose();
    _endTimeController.dispose();
    _disposeNewCheckListFields();
    _taskNameController.dispose();
    _keyboardTimer?.cancel();
    _reminderFocusNode.dispose();
    _recorder!.closeRecorder();
    _player!.closePlayer();
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
      var approvalHistory = taskInfo['data']['approvalHistory'] ?? [];

      if (!mounted) return;

      setState(() {
        members = taskInfo['data']['members'] ?? [];
        description = taskDetails['description'] ?? 'No description available.';
        _activities = (taskInfo['data']['activities'] as List<dynamic>)
            .map((activity) => Activity.fromJson(activity))
            .toList();
        if (approvalHistory is List) {
          _approvalHistory = approvalHistory
              .map((entry) => ApprovalHistory.fromJson(entry))
              .toList();
          _checkApproverStatus();
        } else {
          _approvalHistory = [];
        }

        _attachments = (taskInfo['data']['attachments'] as List<dynamic>)
            .map((attachments) => Attachment.fromJson(attachments))
            .toList();
        taskInfoTitleName = taskDetails['name'] ?? 'Task Name';

        // Set the date and time values if they are available
        _startDateController.text = taskDetails['startDueDate'] ?? 'Select Start Date'; // "25-11-2024"
        _startTimeController.text = taskDetails['startDueTime'] ?? 'Select Start Time'; // "15:45"
        _endDateController.text = taskDetails['endDueDate'] ?? 'Select End Date'; // "26-11-2024"
        _endTimeController.text = taskDetails['endDueTime'] ?? 'Select End Time';

        selectedPriority = taskCodeLists['priority'][taskDetails['priority'].toString()];
        selectedReminderUnit = taskCodeLists['reminderDurationUnit'][taskDetails['reminderDurationUnit'].toString()];
        reminderDuration = taskDetails['reminderDuration']?.toString() ?? '';
        selectedTaskCompletionType = taskCodeLists['taskCompletionType'][taskDetails['taskCompletionType'].toString()];

        taskCompletionTypeManual = taskCodeLists['taskCompletionType'][taskDetails['taskCompletionTypeManual'].toString()];
        selectedTaskApprovalType = (taskDetails['approvalType'] == null || taskDetails['approvalType'].toString().isEmpty) ? '': taskDetails['approvalType'].toString();
        selectedApprovalRequired = (taskDetails['approvalRequired'] == null || taskDetails['approvalRequired'].toString().isEmpty) ? '': taskDetails['approvalRequired'].toString();
        approvalRequiredYes = (taskDetails['approvalRequired'] == null || taskDetails['approvalRequiredYes'].toString().isEmpty) ? '': taskDetails['approvalRequiredYes'].toString();

        selectedTaskCompletionAuto = (taskDetails['closeTaskAutomaticallyAt'] == null || taskDetails['closeTaskAutomaticallyAt'].toString().isEmpty) ? '' : taskDetails['closeTaskAutomaticallyAt'].toString();
        selectedLinkedTask = (taskDetails['linkedTask'] == null || taskDetails['linkedTask'].toString().isEmpty) ? '' : taskDetails['linkedTask'].toString();
        selectedNextTask = (taskDetails['nextTask'] == null || taskDetails['nextTask'].toString().isEmpty) ? '' : taskDetails['nextTask'].toString();
        TaskAssignee = taskDetails['assignee'];

        if (taskDetails.containsKey('approver') && taskDetails['approver'] is String) {
          List<String> sApprovers = taskDetails['approver'].split(',').toList();
          print('Approvers: $sApprovers');
          selectedMembers = sApprovers;
        } else {
          print('Approver key not found or not a string');
        }

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

            print('startDueTime: $startDueTime');

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
            if(reminderDurationValue != null && reminderDurationValue.trim().length > 0) {
              _putCurrEditingValue('reminderDuration', reminderDurationValue);

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
          case 'taskCompletionType':
            data = {
              'fieldName': 'completionType',
              'fieldValue': completionTypeValue
            };
            break;
          case 'nextTask':
            String nextTask = _getCurrEditingValue('nextTask');

            data = {
              'fieldName': 'nextTask',
              'fieldValue': nextTask != null ? nextTask : ''
            };
            break;
          case 'closeTaskAt':
            String closeTaskAt = _getCurrEditingValue('closeTaskAt');
            print('closeTaskAt: selectedTaskCompletionAuto: $closeTaskAt');
            data = {
              'fieldName': 'closeTaskAt',
              'fieldValue': closeTaskAt != null ? closeTaskAt : ''
            };
            break;
          case 'approval':
            String approvalComment = _getCurrEditingValue('approvalComment');
            data = {
              'fieldName': 'approveTask',
              'fieldValue': approvalComment != null ? approvalComment : ''
            };
            break;
          case 'reject':
            String approvalComment = _getCurrEditingValue('approvalComment');

            data = {
              'fieldName': 'rejectTask',
              'fieldValue': approvalComment != null ? approvalComment : ''
            };
            break;
          case 'linkedTask':
            String linkedTask = _getCurrEditingValue('linkedTask');

            data = {
              'fieldName': 'linkedTask',
              'fieldValue': linkedTask != null ? linkedTask : ''
            };
            break;
          case 'approvalType':
            data = {
              'fieldName': 'approvalType',
              'fieldValue': selectedTaskApprovalType
            };
            break;
          case 'approver':
            List<int> approver = selectedMembers.map((e) => int.parse(e)).toList();
            // var approver = _getCurrEditingValue('approver');
            print('approver: $approver');
            var approvalType = selectedTaskApprovalType;
            data = {
              'fieldName': 'approver',
              'fieldValue': {
                'approver':approver,
                'approvalType':approvalType
              }
            };
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
          case 'comment':
            String comment = _messageController.text.trim();

            if(comment.isNotEmpty) {
              _putCurrEditingValue('comment', comment);

              data = {
                'fieldName': 'comment',
                'fieldValue': comment
              };
            }
            break;
          case 'audio-comment':
            if(_recordedAudioFilePath != null) {
              data = {
                'fieldName': 'audio-comment',
              };
            }
            break;
          case 'attachFile':
            String attachName = _getCurrEditingValue('attachFile');

            if(attachName.trim().length > 0) {
              //
            } else {
              // attachName = path.basename(newAttachingFile!.path!);
              attachName = path.basename(newAttachFile!.path);
            }

            data = {
              'fieldName': 'attachFile',
              'fieldValue': attachName
            };

            if(_editingAttachmentIndex! > -1) {
              var _editingAttachment = _attachments[_editingAttachmentIndex!];
              data['attachmentId'] = _editingAttachment.id;
            }
            break;
          case 'deleteAttachment':
            String attachmentId = _getCurrEditingValue('deleteAttachment');

            data = {
              'fieldName': 'deleteAttachment',
              'fieldValue': attachmentId
            };
            break;
          case 'attachLink':
            String attachName = _getCurrEditingValue('attachLinkName') ?? '';
            String attachLink = _getCurrEditingValue('attachLinkText') ?? '';

            if (attachLink.trim().isNotEmpty) {
              data = {
                'fieldName': 'attachLink',
                'fieldValue': attachLink,
              };

              if (attachName.trim().isNotEmpty) {
                data['attachName'] = attachName;
              }
            }
            break;
        }
        if (data != null && data.isNotEmpty) {
          bool isSaved = false;
          dynamic response;

          if(currentEditingField == 'attachFile') {
            File attachFile = File(newAttachFile!.path);
            Map<String, File> files = {
              'attachFile': attachFile
            };

            final response = await panelService().attachFileToTask(
              appUrl!, companyId!, caseId!, panelId!, taskId!,data, files,
            );

            if (response is Map<String, dynamic>) {
              isSaved = response['success'] ?? false; // Safely access the 'success' key
            }
          } else {

            if (currentEditingField == 'audio-comment' && _recordedAudioFilePath != null) {
            Map<String, File> files = {
              'audioFile': File(_recordedAudioFilePath!), // Ensure the path is converted to a File
            };

            response = await _panelService.attachFileToTask(
                appUrl!, companyId!, caseId!, panelId!, taskId!, data, files);
            isSaved = response['success'];
          } else {
            response = await _panelService.updateTaskInfo(
                appUrl!, companyId!, caseId!, panelId!, taskId!, data);
            print('response: ${response}');
            isSaved = response['success'];
          }

            if (response is Map<String, dynamic>) {
              isSaved = response['success'] ?? false; // Safely access the 'success' key
            }
          }

          if (isSaved) {
            await _fetchCasePanelTaskInfo(appUrl, companyId, caseId, panelId, taskId);
            responseData = response['data'] is Map<String, dynamic>
                ? response['data'] as Map<String, dynamic>
                : null;
            print('responseData: $responseData');

            switch (currentEditingField) {
              case 'taskName':
                taskInfoTitleName = _getCurrEditingValue('taskName');
                _taskNameController.text = taskInfoTitleName!;
                break;
              case 'comment':
                _activities = prepareActivities(responseData!.containsKey('updatedValue') ? responseData!['updatedValue'] : []);
                break;
            }
            print("Task info updated successfully.");
          }
        }
      }

    } catch (e) {
      throw Exception('Error adding task: $e');
    }
  }

  _closeTask() async {
    String messageToShow = '';
    bool isTaskClosed = false;

    if (appUrl == null || companyId == null || caseId == null || panelId == null || taskId == null) {
      return;
    }

    try {
      final response = await panelService().closeTask(appUrl!, companyId!, caseId!, panelId!, taskId!);
      final Map<String, dynamic> responseData = json.decode(response.body);

      print('responseData: $responseData');

      isTaskClosed = responseData['success'];
      messageToShow = responseData['message'];

      await Future.delayed(Duration(milliseconds: 1000));
    } catch (e1, e2) {
      print('Close task error: ${e1.toString()}');
      print(e2.toString());

      messageToShow = 'Some error has occurred. Unable to close task';
    }

    if(isTaskClosed) {
      // Go to previous screen
      // Navigator.of(pageContext).pop();
      Navigator.of(context).pop();
    } else {
      // Dialogs().alert(messageToShow, pageContext, () {
      //   Navigator.of(pageContext).pop();
      // });
      Navigator.of(context).pop();
    }
  }

  _reSubmitTask() async {
    String messageToShow = '';
    bool isTaskClosed = false;

    if (appUrl == null || companyId == null || caseId == null || panelId == null || taskId == null) {
      return;
    }

    try {
      dynamic response = await panelService().reSubmitTask(appUrl!, companyId!, caseId!, panelId!, taskId!);

      isTaskClosed = response['success'];
      messageToShow = response['message'];

      await Future.delayed(Duration(milliseconds: 1000));
    } catch (e1, e2) {
      print('Close task error: ${e1.toString()}');
      print(e2.toString());

      messageToShow = 'Some error has occurred. Unable to Resubmit the task';
    }
    if(isTaskClosed) {
      // Go to previous screen
      Navigator.of(context).pop(messageToShow);
    }
  }

  void _checkApproverStatus() async {
    final isApprover = await _isCurrentUserApprover();
    setState(() {
      _isApprover = isApprover;
    });
  }

  // Helper methods to check the current user's role and status
  Future<bool> _isCurrentUserApprover() async {
    final userData = await _authService.getUserData();

    if (userData == null || userData['userName'] == null) {
      print("User data or username is null.");
      return false;
    }

    final currentUserName = userData['userName']?.trim(); // Remove any extra spaces
    if (_approvalHistory.isEmpty) {
      return false;
    }
    // Normalize comparison to be case-insensitive and ignore leading/trailing spaces
    return _approvalHistory.any((entry) =>
    entry.approver?.trim().toLowerCase() == currentUserName?.toLowerCase());
  }

  bool _isApprovalPending() {
    if (_approvalHistory.isEmpty) {
      return false; // No entries, so no pending approval
    }
    // // Get the last entry in the approval history
    // final lastApprovalEntry = _approvalHistory.last;
    // // Check if the status of the last entry is 'Pending Approval'
    // return lastApprovalEntry.status == 'Pending Approval';

    // Check if any entry in the approval history has the status 'Pending Approval'
    return _approvalHistory.any((entry) => entry.status == 'Pending Approval');

  }

  bool _isApprovalRejected() {
    if (_approvalHistory.isEmpty) {
      return false; // No entries, so no Rejected
    }
    // Get the last entry in the approval history
    final lastApprovalEntry = _approvalHistory.last;
    // Check if the status of the last entry is 'Rejected'
    return lastApprovalEntry.status == 'Rejected';
  }

  _isCurrentUser() async {
    final userData = await _authService.getUserData();

    if (userData.isEmpty || userData['userName'] == null) {
      print("User data or username is null.");
      return false;
    }

    loginUserName = userData['userName']?.trim();
  }

  _openFileInNativeApp(String filePath, [String? fileType]) async {
    if (await _checkAndRequestStoragePermission()) {
      File file = File(filePath);
      if (await file.exists()) {
        if (fileType == null) {
          await OpenFile.open(filePath);
        } else {
          OpenFile.open(filePath, type: fileType);
          // convertAacToMp3(filePath);
        }
      } else {
        _showAlert('File not found at $filePath');
      }
    } else {
      print('Permission denied');
    }
  }

  Future<void> _downloadAndPlayAudio(Activity activity) async {
    try {
      if (!await _checkAndRequestStoragePermission()) {
        if (await Permission.storage.isDenied) {
          _showPermissionRationale();
        } else {
          _showAlert('Storage permission is required to play audio.');
        }
        return;
      }

      String? downloadedPath = await _panelService.downloadTaskAudioComment(
          appUrl!, companyId!, caseId!, panelId!, taskId!, activity);

      if (downloadedPath == null || downloadedPath.isEmpty) {
        _showAlert('Failed to download the audio file.');
        return;
      }

      File audioFile = File(downloadedPath);

      if (!await audioFile.exists()) {
        _showAlert('Downloaded audio file not found.');
        return;
      }

      Future.delayed(Duration(milliseconds: 1000), () async {
        if(downloadedPath.isNotEmpty) {
          _openFileInNativeApp(downloadedPath, 'audio/x-aac');
        }
      });
    } catch (e, stacktrace) {
      throw Exception('Error occurred while downloading or playing the audio: $e');
    }
  }

  void _showPermissionRationale() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission Required'),
        content: Text(
            'Storage permission is required to download and play audio files. Please grant the permission.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings(); // Request permission after the explanation
            },
            child: Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Alert'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
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
    List<List<dynamic>> menuOptions = [];

    if (_isApprovalRejected() && _approvalHistory.isNotEmpty) {
      menuOptions.add([2, Icons.checklist, 'Add Checklist Group']);
      menuOptions.add([6, Icons.refresh, 'Resubmit']);
    } else if (_isApprovalPending() && _approvalHistory.isNotEmpty){
      menuOptions.add([7, Icons.supervised_user_circle, 'Members']);
    } else {
      menuOptions.add([1, Icons.edit, 'Change Task Name']);
      menuOptions.add([2, Icons.checklist, 'Add Checklist Group']);
      menuOptions.add([3, Icons.attach_file, 'Attach File']);
      menuOptions.add([4, Icons.link, 'Attach Link']);
      menuOptions.add([5, Icons.close, 'Close Task']);
      menuOptions.add([7, Icons.supervised_user_circle, 'Members']);
    }

    final result = await showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 48, kToolbarHeight, 0.0, 0.0,
      ),
      items: [
        for (var option in menuOptions)
          PopupMenuItem<int>(
            value: option[0] as int,
            child: Row(
              children: [
                Icon(option[1] as IconData?, color: Colors.black),
                SizedBox(width: 8),
                Text('${option[2]}'),
              ],
            ),
          ),
      ],
      elevation: 8.0,
    );

    if (result != null) {
      switch (result) {
        case 1: _showChangeTaskNameDialog(); break;
        case 2: _showAddChecklistGroupDialog(); break;
        case 3: _showAttachFileDialog(); break;
        case 4: _showAttachLinkDialog(); break;
        case 5: _showCloseTaskDialog(); break;
        case 6: _showReSubmitTaskWarning(); break;
      }
    }
  }

  Future<void> _showChangeTaskNameDialog() async {
    _taskNameController.text = taskInfoTitleName ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Change Task Name'),
          content: TextField(
            controller: _taskNameController,
            focusNode: editTaskNameFocusNode,
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
                  setState(() {
                    widget.task['task'] = _taskNameController.text;
                  });
                }
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
  
  void _showFileDetails(String fileName, String filePath) async {
    TextEditingController groupFileNameController = TextEditingController(text: fileName);

    Attachment? _editingAttachment = _editingAttachmentIndex! > -1 ? _attachments[_editingAttachmentIndex!] : null;
    String modalTitle = _editingAttachment != null ? 'Change Attached File' : 'Attach File';
    String okBtnText = _editingAttachment != null ? 'Change' : 'Attach';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(modalTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: groupFileNameController,
                readOnly: true, // Make the field non-editable
                decoration: InputDecoration(
                  labelText: 'File Name',
                  labelStyle: TextStyle(color: Colors.blue),
                  border: UnderlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(okBtnText),
              onPressed: () async {

                Navigator.of(context).pop();
                String _attachName = groupFileNameController.text;

                currentEditingField = 'attachFile';
                _putCurrEditingValue('attachFile', _attachName);
                _onBtnSaveTaskInfoClicked();

              },
            ),
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
                newAttachFile = null;
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAttachFileDialog() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      String filePath = result.files.single.path!;
      String fileName = path.basename(filePath);
      newAttachFile = File(filePath);

      _showFileDetails(fileName, filePath);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected')),
      );
    }
  }

  void _showAttachLinkDialog() {
    TextEditingController groupNameController = TextEditingController();
    TextEditingController groupLinkController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Attach Link', style: TextStyle(fontSize: 25)),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Ensure the dialog doesn't expand unnecessarily
            children: [
              TextField(
                controller: groupNameController, // Controller for the first TextField
                decoration: InputDecoration(
                  hintText: 'Name',
                ),
              ),
              SizedBox(height: 10), // Add some space between the fields
              TextField(
                controller: groupLinkController, // Controller for the second TextField
                decoration: InputDecoration(
                  hintText: 'Link',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Attach'),
              onPressed: () {
                String _attachName = groupNameController.text;
                String _attachLink = groupLinkController.text;

                if(_attachLink.isNotEmpty && _attachLink.trim().length > 0) {
                  currentEditingField = 'attachLink';
                  _putCurrEditingValue(
                      'attachLinkName', _attachName);
                  _putCurrEditingValue(
                      'attachLinkText', _attachLink);
                  _onBtnSaveTaskInfoClicked();
                  Navigator.of(context).pop();
                }
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

  // _DeleteAttachFile dialog
  Future<void> _showDeleteAttachmentModal(BuildContext context, String attachmentId) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Delete Attachment',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.delete, color: Colors.red),
              const SizedBox(width: 10),
              Expanded(
                child: const Text(
                  'Are you sure you want to delete this attachment?',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                // Perform delete action
                setState(() {
                  currentEditingField = 'deleteAttachment';
                  _putCurrEditingValue('deleteAttachment', attachmentId); // You can call your delete function here
                });

                // Close the dialog
                Navigator.of(context).pop();

                // Trigger save task info or any other action after deletion
                _onBtnSaveTaskInfoClicked(); // This could be a function to save task info after deletion
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

  void _showReSubmitTaskWarning() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Resubmit Task'),
          content:Row(
            children: [
              Icon(Icons.warning,color: Colors.yellow[700],size: 20,),
              SizedBox(width: 10), // Space between icon and text
              Expanded( // Wrap the text with an Expanded widget to allow it to take up remaining space
                child: Text(
                  'Are you sure you want to submit the task again for approval?',
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
                _reSubmitTask();
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
                _closeTask();
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

  void _showApproveDialog(String comment) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Task Approval', style: TextStyle(fontSize: 20),),
          content:Row(
            children: [
              Icon(Icons.warning,color: Colors.yellow[700],size: 20,),
              SizedBox(width: 10), // Space between icon and text
              Expanded( // Wrap the text with an Expanded widget to allow it to take up remaining space
                child: Text(
                  'Are you sure you want to approve this task?',
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
                currentEditingField = 'approval';
                _putCurrEditingValue('approvalComment', comment);
                _onBtnSaveTaskInfoClicked();
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

  void _showApprovalRejectDialog() {
    print('Reject dialog opened');
    FocusScope.of(context).unfocus();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Task Reject', style: TextStyle(fontSize: 20)),
          content:Row(
            children: [
              Icon(Icons.warning,color: Colors.yellow[700],size: 20,),
              SizedBox(width: 10), // Space between icon and text
              Expanded( // Wrap the text with an Expanded widget to allow it to take up remaining space
                child: Text(
                  'Are you sure you want to reject this task?',
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
                var comment = commentsController.text;
                currentEditingField = 'reject';
                _putCurrEditingValue('approvalComment', comment);
                _onBtnSaveTaskInfoClicked();
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

  _toggleDocumentHistory(int _attachmentIndex) async {
    try {
      if(_attachments[_attachmentIndex].isDocumentHistoryShown) {
        _attachments[_attachmentIndex].isDocumentHistoryShown = false;
        setState(() {});
      } else {
        final attachment = _attachments[_attachmentIndex];
        final response = await panelService().fetchTaskAdditionalDetails(
          appUrl!, companyId!, caseId!, panelId!, taskId!, 1,
          'documentHistory','documentId=${_attachments[_attachmentIndex].id}',
        );

        if (response.success) {
          attachment.documentHistoryList = response.documentHistory.cast<DocumentHistory>();
          attachment.isDocumentHistoryShown = true;
          historyVisibility[attachment.id.toString()] = true;

          refreshLayout = true;
          setState(() {});
        } else {
          print("Failed to fetch document history: ${response.errorMessage}");
        }
      }
    } catch (e, stackTrace) {
      print('Error: ${e.toString()}');
      print(stackTrace.toString());
    }
  }

  _downloadAttachment(int _attachmentIndex, int? _versionHistoryIndex) async {
    final attachment = _attachments[_attachmentIndex];
    String _attachmentType = attachment.type;

    if(_attachmentType == 'file'){
      try{
        if (appUrl != null && companyId != null && caseId != null &&
            panelId != null && taskId != null ) {
          if (await _checkAndRequestStoragePermission()) {
            await _panelService.downloadTaskAttachment(
                appUrl!, companyId!, caseId!, panelId!, taskId!, attachment, _versionHistoryIndex).then((String downloadedFilePath) {
              Future.delayed(Duration(milliseconds: 1000), () {
                _openFileInNativeApp(downloadedFilePath, 'image/*');
              });
            });
          }
        }  else {
          print('Error: One or more required values are null');
        }
      }catch(e){
        print('File download error: $e');

      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: Text(
          task['name'] ?? task['task'] ?? _taskNameController.text ?? taskInfoTitleName ?? 'Task Name',
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

                // Approval History
                buildExpandableSection(
                  title: 'Approval History',
                  icon: Icons.history,
                  // content: task['completionStatus'] ?? 'No status available.',
                  contentWidget: buildApprovalHistory(),
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
                    onTap: (taskDetails != null && taskDetails['taskStatus'] == "8") ? null : () => _selectDate(_startDateController).then(
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
                    onTap: (taskDetails != null && taskDetails['taskStatus'] == "8") ? null : () => _selectTime(_startTimeController).then(
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
                    onTap: (taskDetails != null && taskDetails['taskStatus'] == "8") ? null : () => _selectTime(_endTimeController).then(
                            (_) => _onFieldValueChange('endDueTime', _endTimeController.text)),
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

  // Function to buildTaskCompletionSection
  Widget buildTaskCompletionSection() {
    if (taskCodelists == null) {
      return Center(child: CircularProgressIndicator());
    }

    Map<String, String> taskCompletionType = taskCodelists!['taskCompletionType'].cast<String, String>();
    Map<String, String> taskApprovalRequired = taskCodelists!['approvalRequired'].cast<String, String>();
    Map<String, String> taskApprovalType = taskCodelists!['approvalTypes'].cast<String, String>();
    Map<String, String> taskCompletionAuto = taskCodelists!['taskCompletionAuto'].cast<String, String>();
    // Map<String, String> linkedTasks = taskCodelists!['linkedTasks'].cast<String, String>();
    Map<String, String> linkedTasks = {};

    print('taskCodelists: ${taskCodelists}');

    if (taskCodelists != null && taskCodelists!['linkedTasks'] != null) {
      var rawLinkedTasks = taskCodelists!['linkedTasks'];
      if (rawLinkedTasks is Map) {
        // If it's already a Map
        linkedTasks = Map<String, String>.from(rawLinkedTasks);
      } else if (rawLinkedTasks is List) {
        // If it's a List, convert it to a Map
        for (var item in rawLinkedTasks) {
          if (item is Map && item.containsKey('key') && item.containsKey('value')) {
            linkedTasks[item['key'].toString()] = item['value'].toString();
          } else {
            print("Invalid item in linkedTasks list: $item");
          }
        }
      } else {
        print("Error: linkedTasks is of unexpected type: ${rawLinkedTasks.runtimeType}");
      }
    } else {
      print("taskCodelists or linkedTasks is null");
    }


    var autoStartTask = taskCodelists?['autoStartTasks'];

    if (autoStartTask != null && autoStartTask is Map && autoStartTask.isNotEmpty) {
      Map<String, String> autoStartTasks = Map<String, String>.from(taskCodelists?['autoStartTasks']);
      List<MapEntry<String, String>> tasksListEntries = autoStartTasks.entries.toList();

    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                              onChanged: taskDetails['taskStatus'] == "8" ? null : (int? newValue) {
                                setState(() {
                                  completionTypeValue = newValue;
                                  currentEditingField = 'taskCompletionType';
                                  _onBtnSaveTaskInfoClicked();
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

              if (completionTypeValue == 2 && selectedTaskCompletionAuto != null)
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Complete Task Automatically At',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      if (taskCompletionAuto.isNotEmpty)
                        DropdownButton<String>(
                          value: taskCompletionAuto.containsKey(selectedTaskCompletionAuto)
                              ? selectedTaskCompletionAuto
                              : null,
                          items: taskCompletionAuto.entries.map((entry) {
                            String value = entry.key;
                            String label = entry.value;
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(label),
                            );
                          }).toList(),
                          onChanged: taskDetails['taskStatus'] == "8" ? null : (String? newValue) {
                            setState(() {
                              selectedTaskCompletionAuto = newValue;

                              currentEditingField = 'closeTaskAt';
                              _putCurrEditingValue('closeTaskAt', newValue);
                              _onBtnSaveTaskInfoClicked();
                            });
                          },
                          hint: Text('--Select--'),
                        ),
                    ],
                  ),
                ),
              if (completionTypeValue == 2)
                SizedBox(width: 20),
            ],
          ),
          SizedBox(height: 20),


          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        String value = entry.key;
                        String label = entry.value;

                        return Row(
                          children: [
                            Radio<String>(
                              value: value,
                              groupValue: selectedApprovalRequired != null ? selectedApprovalRequired : approvalRequiredYes,
                              onChanged: taskDetails['taskStatus'] == "8" ? null : (String? newValue) {
                                setState(() {
                                  selectedApprovalRequired = newValue != null ? newValue.toString() : null;
                                  // currentEditingField = 'approvalType';
                                  // _onBtnSaveTaskInfoClicked();
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
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Approval Type',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: taskApprovalType.entries.map((entry) {
                        String value = entry.key;
                        String label = entry.value;

                        return Row(
                          children: [
                            Radio<String>(
                              value: value,
                              groupValue: selectedTaskApprovalType != null ? selectedTaskApprovalType : '2',
                              onChanged: taskDetails['taskStatus'] == "8" ? null : (String? newValue) {
                                setState(() {
                                  selectedTaskApprovalType = newValue != null ? newValue.toString() : null;
                                  currentEditingField = 'approvalType';
                                  _onBtnSaveTaskInfoClicked();
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
          SizedBox(height: 10),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /*Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8),
                    if (TaskAssignee != null)
                      DropdownButton<int>(
                        value: TaskAssignee,
                        items: members.map<DropdownMenuItem<int>>((member) {
                          return DropdownMenuItem<int>(
                            value: member['id'] as int,
                            child: Text(member['name'] ?? 'Unknown'),
                          );
                        }).toList(),
                        onChanged: (int? newValue) {
                          setState(() {
                            TaskAssignee = newValue;
                          });
                        },
                      ),
                  ],
                ),
              ),*/

              if (selectedApprovalRequired != null && selectedApprovalRequired == '1')
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Approver',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 0),
                      if (members.isNotEmpty)
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: null,
                            items: members
                                .where((member) => member['name'] != loginUserName)
                                .map<DropdownMenuItem<String>>((member) {
                              return DropdownMenuItem<String>(
                                value: member['id']?.toString(),
                                child: Text(member['name'] ?? 'Unknown'),
                              );
                            }).toList(),
                            onChanged: (String? selectedValue) {
                              setState(() {
                                if (selectedMembers.contains(selectedValue)) {
                                  selectedMembers.remove(selectedValue); // Deselect if already selected
                                } else {
                                  selectedMembers.add(selectedValue!); // Select if not selected
                                }

                                currentEditingField = 'approver';
                                _putCurrEditingValue('approver', selectedMembers);
                                _onBtnSaveTaskInfoClicked();
                              });
                            },
                            hint: Text(
                              selectedMembers.isEmpty
                                  ? 'Select Approvers'
                                  : selectedMembers
                                  .map((id) =>
                              members.firstWhere((member) => member['id'].toString() == id)['name'])
                                  .join(', '),
                              maxLines: 100,
                              overflow: TextOverflow.ellipsis,
                            ),
                            isExpanded: true,
                          ),
                        )
                      else
                        Text('No approvers available'),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectedApprovalRequired != null && selectedApprovalRequired == '1' && (selectedTaskCompletionAuto == '2' || selectedTaskCompletionAuto == '3') && selectedTaskCompletionType != 'Manual')
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Linked Task',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 0),
                      if (linkedTasks.isNotEmpty)
                        DropdownButton<String>(
                          value: linkedTasks.containsKey(selectedLinkedTask) ? selectedLinkedTask : null,
                          items: linkedTasks.entries.map((entry) {
                            String value = entry.key;
                            String label = entry.value;
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(label),
                            );
                          }).toList(),
                          onChanged: taskDetails['taskStatus'] == "8" ? null : (String? newValue) {
                            setState(() {
                              selectedLinkedTask = newValue;

                              currentEditingField = 'linkedTask';
                              _putCurrEditingValue('linkedTask', newValue);
                              _onBtnSaveTaskInfoClicked();
                            });
                          },
                          hint: Text('--Select a Task--'),
                          isExpanded: true,
                        ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 10),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectedApprovalRequired != null && selectedApprovalRequired == '1' && selectedTaskCompletionType != 'Manual')
                if (autoStartTask != null && autoStartTask is Map && autoStartTask.isNotEmpty)
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'On Completion of task, Automatically Start',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 0),
                        DropdownButton<String>(
                          value: autoStartTask.containsKey(selectedNextTask)
                              ? selectedNextTask
                              : null,
                          items: autoStartTask.entries.map((entry) {
                            String value = entry.key;
                            String label = entry.value;
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(label),
                            );
                          }).toList(),
                          onChanged: taskDetails['taskStatus'] == "8" ? null : (String? newValue) {
                            setState(() {
                              selectedNextTask = newValue;
                              currentEditingField = 'nextTask';
                              _putCurrEditingValue('nextTask', newValue);
                              _onBtnSaveTaskInfoClicked();
                            });
                          },
                          hint: Text('--Select a Next Task--'),
                          isExpanded: true,
                        ),
                      ],
                    ),
                  ),
            ],
          ),
          SizedBox(height: 10),
          /*Row(
            children: [
              Expanded(child: Column()),
              // Right side - Name 2 Dropdown


            ],
          ),*/
        ],
      ),
    );
  }

  Widget buildApprovalHistory() {
    if (taskCodelists == null) {
      return Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_approvalHistory.isNotEmpty)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text(
                      //   'Approval History',
                      //   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      // ),
                      SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Table(
                          border: TableBorder.all(color: Colors.grey),
                          columnWidths: const <int, TableColumnWidth>{
                            0: FlexColumnWidth(5),
                            1: FlexColumnWidth(5),
                            2: FlexColumnWidth(5),
                            3: FlexColumnWidth(5),
                            4: FlexColumnWidth(5),
                            5: FlexColumnWidth(5),
                          },
                          children: [
                            TableRow(
                              decoration: BoxDecoration(color: Colors.grey[200]),
                              children: [
                                _buildTableHeader('Submitted By'),
                                _buildTableHeader('Date'),
                                _buildTableHeader('Approver'),
                                _buildTableHeader('Approval Status'),
                                _buildTableHeader('Comments'),
                                _buildTableHeader('Approval Date'),
                              ],
                            ),
                            ..._approvalHistory.map((entry) {
                              return TableRow(
                                children: [
                                  _buildTableCell(entry.proposer ?? 'N/A'),
                                  _buildTableCell(entry.submittedDate ?? 'N/A'),
                                  _buildTableCell(entry.approver ?? 'N/A'),
                                  _buildTableCell(entry.status ?? 'N/A'),
                                  _buildTableCell(entry.comments ?? 'N/A'),
                                  _buildTableCell(entry.approvalDate ?? 'N/A'),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text('No approval history available'),
              SizedBox(height: 20),
            ],
          ),
          SizedBox(height: 20),

          if (_isApprover && _isApprovalPending())
            Row(
              children: [
                // Comments Section
                Expanded(
                  child: Card(
                    elevation: 5,  // Shadow effect for the card
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),  // Rounded corners
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),  // Padding inside the card
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,  // Icon before the text (you can change this)
                                color: Colors.black,
                                size: 18,// Icon color
                              ),
                              SizedBox(width: 4),  // Space between the icon and text
                              Text(
                                'Approval',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          TextField(
                            focusNode: commentsNameFocusNode,
                            controller: commentsController,
                            decoration: InputDecoration(
                              hintText: 'comments',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  // Logic for Approve button
                                  _onApproveButtonClicked(commentsController.text);

                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,  // Background color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(1),  // Border radius for rounded corners
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center, // Center the content
                                  children: [
                                    Icon(
                                      Icons.check_circle,  // Icon for the Approve button
                                      color: Colors.white,  // Icon color
                                    ),
                                    SizedBox(width: 5),  // Space between the icon and the text
                                    Text(
                                      'Approve',
                                      style: TextStyle(
                                        color: Colors.white,  // Text color
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () {
                                  // FocusScope.of(context).unfocus();
                                  if (!_isCommentsFieldFocused) {
                                    _isCommentsFieldFocused = true;
                                    commentsNameFocusNode.unfocus();
                                    _setupKeyboardAutoClose(); // Start the timer for this field
                                  }
                                  _showApprovalRejectDialog();
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(1),  // Border radius for rounded corners
                                ),),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,  // Center the content
                                  children: [
                                    Icon(
                                      Icons.cancel,  // Icon for the Reject button
                                      color: Colors.blueAccent,  // Icon color
                                    ),
                                    SizedBox(width: 5),  // Space between the icon and the text
                                    Text(
                                      'Reject',
                                      style: TextStyle(
                                        color: Colors.blueAccent,  // Text color
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: TextStyle(fontSize: 9), // Handle overflow
      ),
    );
  }

  // Function to build Activity Section
  Widget buildActivitySection() {
    double screenHeight = MediaQuery.of(context).size.height;
    return SizedBox(
      height: screenHeight * 0.5, // Fixed height
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Column(
          children: [
            // Input Section
            if (!_isRecording) // Show comment input when not recording
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.message, color: Colors.blue),
                      onPressed: () {},
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: "Enter the comment",
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 16.0),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.send, color: Colors.blue),
                              onPressed: () {
                                currentEditingField = 'comment';
                                _onBtnSaveTaskInfoClicked();
                                _messageController.clear();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.mic, color: Colors.blue),
                      onPressed: () async {
                        await _startRecording();
                        setState(() {
                          _isRecording = true;
                        });
                      },
                    ),
                  ],
                ),
              )
            else // Show recording controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.message, color: Colors.blue),
                    onPressed: () {},
                  ),
                  if (_recordedAudioFilePath != null && _isRecording)
                    IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.blue, // Choose color based on state
                      ),
                      onPressed: _playRecording,
                    ),
                    Text(
                      "${_formatTime(_recordingSeconds)}",
                      style: TextStyle(fontSize: 14.0, color: Colors.black),
                    ),
                    SizedBox(width: 5),
                  // Pause/Resume Toggle
                  IconButton(
                    icon: Icon(
                      _isPaused ? Icons.restore_outlined : Icons.stop,
                      color: _isPaused ? Colors.black : Colors.blue,
                    ),
                    onPressed: () async {
                      if (_isPaused) {
                        await _resumeRecording();
                      } else {
                        await _pauseRecording();
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.cancel, color: Colors.red),
                    onPressed: () async {
                      await _cancelRecording();
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.blue),
                    onPressed: () {
                      _pauseRecording();
                      currentEditingField = 'audio-comment';
                      _onBtnSaveTaskInfoClicked();

                      setState(() {
                        _isRecording = false;
                        _recordingSeconds = 0;
                      });
                    },
                  ),
                ],
              ),

            // Displaying activity list
            if (_activities.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _activities.length,
                  itemBuilder: (context, index) {
                    final activity = _activities[index];
                    String avatarInitial = activity.user.isNotEmpty
                        ? activity.user[0].toUpperCase()
                        : "?";
                    return Card(
                      color: Colors.white,
                      elevation: 2,
                      margin:
                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            avatarInitial,
                            style: TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Row(
                          children: [
                            if (activity.type == 'audio')
                              Icon(Icons.mic, color: Colors.black),
                            SizedBox(width: 8.0),
                            Text(activity.type == 'text' ? activity.content : ''),
                          ],
                        ),
                        subtitle: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today,
                                color: Colors.grey, size: 16),
                            SizedBox(width: 2.0),
                            Text(
                              "${activity.date}",
                              style:
                              TextStyle(fontSize: 12.0, color: Colors.grey),
                            ),
                            SizedBox(width: 4.0),
                            Icon(Icons.access_time,
                                color: Colors.grey, size: 16),
                            SizedBox(width: 2.0),
                            Text(
                              "${activity.time}",
                              style:
                              TextStyle(fontSize: 12.0, color: Colors.grey),
                            ),
                            if (activity.type == 'audio')
                              IconButton(
                                icon: Icon(
                                  _isPlaying &&
                                      _currentAudioUrl == activity.content
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: Colors.blueAccent,
                                ),
                                onPressed: () {
                                  _downloadAndPlayAudio(activity);
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Center(child: Text('No activities available.')),
          ],
        ),
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

  Widget buildFileAttachment() {
    final idt = _authService.getIdt();
    // Use MediaQuery to get the screen size
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double iconSize = screenWidth * 0.07; // Adjust icon size based on screen width
    double spacing = screenWidth * 0.02; // Adjust spacing based on screen width

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _attachments.length,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final attachment = _attachments[index];
        if (attachment.type == 'file') {
          return Card(
            color: Colors.white,
            elevation: 6.0,
            margin: EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.file_copy, size: 30),
                  title: Text(
                    attachment.fileName!,
                    style: TextStyle(fontSize: screenWidth * 0.03, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Row(
                    children: [
                      SizedBox(height: spacing * 3),
                      Icon(Icons.calendar_today, size: iconSize * 0.5, color: Colors.grey),
                      SizedBox(width: spacing),
                      Text(
                        attachment.date,
                        style: TextStyle(fontSize: screenWidth * 0.03, color: Colors.grey),
                      ),
                      SizedBox(width: spacing * 1),
                      Icon(Icons.access_time, size: iconSize * 0.5, color: Colors.grey),
                      SizedBox(width: spacing),
                      Text(
                        attachment.time,
                        style: TextStyle(fontSize: screenWidth * 0.03, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    color: Colors.white,
                    icon: Icon(Icons.more_vert, color: Colors.black87),
                    onSelected: (value, [int? versionHistoryIndex]) async {
                      switch (value) {
                        case 'download':
                          _downloadAttachment(index, versionHistoryIndex);
                          break;
                        case 'history':
                          _toggleDocumentHistory(index);
                          break;
                        case 'edit':
                          _editingAttachmentIndex = index;
                          _showAttachFileDialog();
                          break;
                        case 'delete':
                          String attachmentId = attachment.id.toString();
                          _showDeleteAttachmentModal(context, attachmentId);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'download',
                        child: _menuItemRow(Icons.download, iconColor:Colors.black, "Download"),
                      ),
                      PopupMenuItem(
                        value: 'history',
                        child: _menuItemRow(Icons.history,  iconColor:Colors.black,"History"),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: _menuItemRow(Icons.edit,  iconColor:Colors.black,"Edit"),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: _menuItemRow(Icons.delete, iconColor:Colors.red, "Delete"),
                      ),
                    ],
                  ),
                ),
                // Show the history design only if the history visibility is true for this card
                if (historyVisibility[attachment.id.toString()] ?? false) ...[
                  if (attachment.isDocumentHistoryShown)
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            padding: const EdgeInsets.only(top: 16.0, left: 12.0, right: 12.0, bottom: 12.0),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey, width: 1.0),
                              borderRadius: BorderRadius.circular(5.0),
                              color: Colors.white,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 10.0),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: _renderDocumentHistoryList(attachment.documentHistoryList, index),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 14.0,
                            top: -4.0,
                            child: Container(
                              constraints: BoxConstraints(maxWidth: 200),
                              color: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min, // To prevent it from occupying full width
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _attachments[index].isDocumentHistoryShown = false;
                                      });
                                    },
                                    child: Icon(Icons.history, size: iconSize * 0.7, color: Colors.black),  // History Icon
                                  ),
                                  SizedBox(width: 8.0),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _attachments[index].isDocumentHistoryShown = false;
                                      });
                                    },
                                    child: Text(
                                      'History',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.03,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          );

        } else if (attachment.type == 'link') {
          // For link attachments
          return Card(
            color: Colors.white,
            elevation: 6.0,
            margin: EdgeInsets.symmetric(vertical: 10),
            child: ListTile(
              leading: Icon(Icons.link, size: 30),
              title: Text(
                attachment.name,
                style: TextStyle(fontSize: screenWidth * 0.03, fontWeight: FontWeight.bold),  // Adjust font size dynamically
              ),
              subtitle: Text(attachment.url),
              trailing: IconButton(
                icon: Icon(Icons.open_in_new),
                onPressed: () async {
                  String url = attachment.url ?? '';
                  if (url.isNotEmpty) {
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url));
                    } else {
                    print("Could not launch URL: $url");
                    }
                  }
                },
              ),
            ),
          );
        } else {
          return Container(); // For unsupported types
        }
      },
    );
  }

  List<Widget> _renderDocumentHistoryList(List<DocumentHistory> documentHistoryList, int attachmentIndex) {
    return documentHistoryList.asMap().entries.map((entry) {
      final int historyIndex = entry.key;
      final DocumentHistory history = entry.value;
      final bool hasNextItem = historyIndex + 1 < documentHistoryList.length;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(top: historyIndex > 0 ? 10 : 0),
            child: Row(
              children: [
                Expanded(
                  flex: 9,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        history.name,
                        style: TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            'Version: ${history.versionNo}',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                          SizedBox(width: 5),
                          Icon(Icons.calendar_today, size: 11, color: Colors.grey),
                          SizedBox(width: 5),
                          Text(
                            history.date,
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                          SizedBox(width: 5),
                          Icon(Icons.access_time, size: 11, color: Colors.grey),
                          SizedBox(width: 5),
                          Text(
                            history.time,
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: () =>
                        _downloadAttachment(attachmentIndex, historyIndex),
                    child: Icon(Icons.file_download, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          if (hasNextItem) Divider(color: Colors.grey.shade200,thickness: 1.0,),
        ],
      );
    })
        .toList();
  }


  Widget _menuItemRow(IconData icon, String text, {Color iconColor = Colors.blueAccent}) {
    return Row(
      children: [
        Icon(icon, color: iconColor), // Icon with customizable color
        SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(color: Colors.black87), // Consistent text color
        ),
      ],
    );
  }
}
