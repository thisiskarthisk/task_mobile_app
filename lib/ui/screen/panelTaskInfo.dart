import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_audio/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_audio/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tms/ui/screen/panel.dart';
import 'package:flutter_tms/ui/widgets/custom_expansion_tile.dart' as customExpansionTile;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import '../screen/panelService.dart';
import 'package:device_info_plus/device_info_plus.dart'; // Import device_info_plus
import 'package:just_audio/just_audio.dart' as just_audio;

class PanelDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> task;
  const PanelDetailsScreen({Key? key, required this.task}) : super(key: key);

  @override
  _PanelDetailsScreenState createState() => _PanelDetailsScreenState();
}

class Activity {
  final String content, type, user, date, time;
  final String? audioFileName;
  final int id;

  Activity({required this.id,required this.content, required this.type, required this.user, required this.date, required this.time, this.audioFileName});

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      content: json['content'],
      type: json['type'],
      user: json['user'],
      date: json['date'],
      time: json['time'],
      audioFileName: json['audioFileName'] as String?, // This will handle null values correctly
    );
  }

  @override
  String toString() {
    return 'Activity{id: $id, content: $content, type: $type, user: $user, date: $date, time: $time, audioFileName: $audioFileName}';
  }
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

  int? companyId, caseId, panelId, taskId, completionTypeValue, TaskAssignee;

  String? appUrl, description = '', startDueDate = '', selectedPriority, selectedTaskCompletionType, selectedReminderUnit,
      selectedApprovalRequired, taskCompletionTypeManual, autoStartTaskValue, nameValue, name2Value,
      autoStartTask, currentEditingField, reminderDuration, TaskApprover, selectedTaskApprovalType, selectedTaskCompletionAuto, selectedLinkedTask, selectedNextTask, _fileName, _filePath;
  String? _currentAudioUrl;
  // State to track unsaved changes
  bool hasUnsavedChanges = false;
  bool _isReminderFieldFocused = false;
  bool _isPaused = false;
  FocusNode _reminderFocusNode = FocusNode();

  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player = FlutterSoundPlayer();
  String? _recordedAudioFilePath;
  bool _isRecording = false;
  bool _isPlaying = false;

  Timer? _recordingTimer; // Timer for recording duration
  int _recordingSeconds = 0; // Recording time counter

  var taskDetails;
  // Calendar Info Controllers
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  late TextEditingController _startTimeController = TextEditingController();
  late TextEditingController _endTimeController = TextEditingController();

  List<dynamic> members = [];
  // List<dynamic> taskCompletionAuto = [];
  Map<String, dynamic>? taskCodelists;
  Map<String, dynamic> currEditingFieldValue = {};
  List<ChecklistItem> checklist = [];
  List<String> _attachments = [];
  List<Activity> activities = [];
  List<Activity> _activities = [];
  Map<String, dynamic>? responseData;
  Map<int, bool> _audioPlaybackState = {};

  just_audio.AudioPlayer player = just_audio.AudioPlayer();

  Timer? _keyboardTimer;

  @override
  void initState() {
    super.initState();
    _taskNameController.text = widget.task['task'] ?? 'Task Name';  // Initialize task name
    _newCheckListGroupNameController = TextEditingController();
    _initializeForm();
    _recorder = FlutterSoundRecorder();
    _startTimeController = TextEditingController();
    _endTimeController = TextEditingController();

    _setupKeyboardAutoClose();
    _initializeRecorder();
    _initializePlayer();
    responseData = {};
  }

  Future<void> _initializePlayer() async {
    await _player!.openPlayer();
  }

  Future<void> _initializeForm() async {
    appUrl = widget.task['appUrl'];
    companyId = widget.task['companyId'];
    caseId = widget.task['caseId'];
    panelId = widget.task['panelId'];
    taskId = widget.task['taskId'];

    _fetchCasePanelTaskInfo(appUrl, companyId, caseId, panelId, taskId);
    _player = FlutterSoundPlayer();
  }

  Future<void> _initializeRecorder() async {
    await _recorder!.openRecorder();
    if (await Permission.microphone.request().isDenied) {
      // Request microphone permission
      await Permission.microphone.request();
    }
  }

  Future<void> openAppSettingsIfDenied() async {
    if (await Permission.manageExternalStorage.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  Future<bool> _checkAndRequestStoragePermission() async {
    if (await Permission.storage.isGranted) {
      // Permission already granted
      return true;
    } else if (await Permission.manageExternalStorage.isGranted) {
      // MANAGE_EXTERNAL_STORAGE granted
      return true;
    } else {
      // Request storage or manage external storage permission
      final status = await Permission.manageExternalStorage.request();
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

  Future<void> _startRecording() async {
    try {
      // Ensure the recorder is initialized
      await _initializeRecorder();

      // Get the temporary directory to store the audio file
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/audio_comment.aac';

      // Start recording only if it's not already recording
      if (!_recorder!.isRecording) {
        await _recorder!.startRecorder(
          toFile: filePath,
          codec: Codec.aacADTS,
        );

        setState(() {
          _isRecording = true;
          _recordedAudioFilePath = filePath;
          _recordingSeconds = 0;
        });

        // Start a timer to track recording time
        _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
          setState(() {
            _recordingSeconds++;
          });
        });
      }
    } catch (e) {
      print("Error starting recorder: $e");
    }
  }

  Future<void> _pauseRecording() async {
    if (_recorder != null && _isRecording && !_isPaused) {
      await _recorder!.pauseRecorder();
      setState(() {
        _isPaused = true;
      });
      _recordingTimer?.cancel(); // Stop the timer when paused
      print("Recording paused: $_recordedAudioFilePath");
    }
  }

  Future<void> _resumeRecording() async {
    if (_recorder != null && _isPaused) {
      await _recorder!.resumeRecorder();
      setState(() {
        _isPaused = false;
      });

      // Restart the timer
      _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _recordingSeconds++;
        });
      });

      print("Recording resumed");
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
      print("Recording canceled");
    }
  }

  // Play the recorded audio
  Future<void> _playRecording() async {
    if (_recordedAudioFilePath == null) return;

    if (_isPlaying) {
      // If already playing, pause the audio
      await _player?.pausePlayer();
      setState(() {
        _isPlaying = false;
      });
    } else {
      // If not playing, start or resume playback
      if (_player!.isPaused) {
        // Resume the playback if previously paused
        await _player?.resumePlayer();
      } else {
        // Start playback from the beginning
        await _player?.startPlayer(
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
    _messageController.dispose();
    _startDateController.dispose();
    _startTimeController.dispose();
    _endDateController.dispose();
    _endTimeController.dispose();
    _disposeNewCheckListFields();
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

      print('taskDetails:');
      print(taskDetails);

      var taskCodeLists = taskInfo['data']['codelists'];
      var checklistData = taskInfo['data']['checklist'] ?? [];

      setState(() {
        members = taskInfo['data']['members'] ?? [];
        description = taskDetails['description'] ?? 'No description available.';
        _activities = (taskInfo['data']['activities'] as List<dynamic>)
            .map((activity) => Activity.fromJson(activity))
            .toList();

        for (var activity in _activities) {
          print(activity); // This will call activity.toString()
        }

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
        selectedTaskApprovalType = (taskDetails['approvalType'] == null || taskDetails['approvalType'].toString().isEmpty) ? '': taskDetails['approvalType'].toString();
        selectedTaskCompletionAuto = (taskDetails['closeTaskAutomaticallyAt'] == null || taskDetails['closeTaskAutomaticallyAt'].toString().isEmpty) ? '' : taskDetails['closeTaskAutomaticallyAt'].toString();
        selectedLinkedTask = (taskDetails['linkedTask'] == null || taskDetails['linkedTask'].toString().isEmpty) ? '' : taskDetails['linkedTask'].toString();
        selectedNextTask = (taskDetails['nextTask'] == null || taskDetails['nextTask'].toString().isEmpty) ? '' : taskDetails['nextTask'].toString();
        TaskAssignee = taskDetails['assignee'];
        TaskApprover = taskDetails['approver'].toString();

        print('selectedTaskCompletionAuto: $selectedTaskCompletionAuto');

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

            print('nextTask: $nextTask');

            data = {
              'fieldName': 'nextTask',
              'fieldValue': nextTask != null ? nextTask : ''
            };
            break;
          case 'closeTaskAt':
            String closeTaskAt = _getCurrEditingValue('closeTaskAt');

            data = {
              'fieldName': 'closeTaskAt',
              'fieldValue': closeTaskAt != null ? closeTaskAt : ''
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
            var approver = _getCurrEditingValue('approver');

            var approvalType = selectedTaskApprovalType;
            print('approver: $approvalType');

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

        }
        if (data != null && data.isNotEmpty) {
          bool isSaved = false;
          dynamic response;

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
            isSaved = response['success'];
          }
          // isSaved = response['success'];
          print('response: $response');

          if (response is Map<String, dynamic> && response['success'] == true) {
            await _fetchCasePanelTaskInfo(appUrl, companyId, caseId, panelId, taskId);
            responseData = response['data'] is Map<String, dynamic>
                ? response['data'] as Map<String, dynamic>
                : null;

            switch (currentEditingField) {
              case 'comment':
                _activities = prepareActivities(responseData!.containsKey('updatedValue') ? responseData!['updatedValue'] : []);
                break;
            }
          }
        }
      }

    } catch (e) {
      throw Exception('Error adding task: $e');
    }
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
    final audioPlayer = just_audio.AudioPlayer();
    try {
      if (!await _checkAndRequestStoragePermission()) {
        if (await Permission.storage.isDenied) {
          _showPermissionRationale();
        } else {
          _showAlert('Storage permission is required to play audio.');
        }
        return;
      }

      String localDir = (await getApplicationDocumentsDirectory()).path;

      String? downloadedPath = await _panelService.downloadTaskAudioComment(
          appUrl!, companyId!, caseId!, panelId!, taskId!, activity);

      print('Downloaded Audio Path: $downloadedPath');

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
        if(downloadedPath != null) {
          _openFileInNativeApp(downloadedPath, 'audio/x-aac');
        }
      });

      // await audioPlayer.setAudioSource(just_audio.AudioSource.uri(Uri.file(downloadedPath))); // Use setFilePath for local file
      // await audioPlayer.play();

    } catch (e, stacktrace) {
      print('_downloadAndPlayAudio() Error:');
      print(e);
      print(stacktrace);
      _showAlert('Error occurred while downloading or playing the audio: $e');
    }
  }

  Future<void> _playAudio(String filePath) async {
    try {
      // Verify file existence
      File audioFile = File(filePath.trim());
      if (!await audioFile.exists()) {
        print('Audio file not found at: $filePath');
        _showAlert('Audio file does not exist.');
        return;
      }

      // Check permissions
      int androidVersion = 0;
      if (Platform.isAndroid) {
        DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        androidVersion = int.parse(androidInfo.version.release);
        print('Android Version: $androidVersion');
      }

      bool isStorageDenied = await Permission.storage.request().isDenied;
      print('Permission.storage.isDenied: $isStorageDenied');

      if ((Platform.isAndroid &&
              androidVersion >= 13 &&
              await Permission.audio.request().isDenied)) {
        _showPermissionRationale(); // Show rationale to user
        return;
      }

      // Initialize the FlutterSoundPlayer if not already open
      if (_player == null || !_player!.isOpen()) {
        await _player?.openPlayer();
        print('Player opened.');
      }

      // Determine codec based on file extension
      Codec codec = filePath.endsWith('.aac') ? Codec.aacADTS : Codec.aacMP4;

      // Start playback with explicit codec
      await _player?.startPlayer(
        fromURI: 'file://$filePath',
        codec: codec,
        whenFinished: () {
          print('Audio playback finished.');
          setState(() {
            _isPlaying = false;
          });
        },
      );

      setState(() {
        _isPlaying = true;
      });
      print('Playing audio from: $filePath');
    } catch (e) {
      print('Error while playing audio: $e');
      _showAlert('Error while playing audio: $e');
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


  // Future<void> _playAudio(String filePath) async {
  //   if (_isPlaying) {
  //     await _audioPlayer.stop();
  //   } else {
  //     int result = await _audioPlayer.play(DeviceFileSource(filePath));
  //     if (result == 1) {
  //       setState(() {
  //         _isPlaying = true;
  //         _currentAudioUrl = filePath;
  //       });
  //       _audioPlayer.onPlayerComplete.listen((event) {
  //         setState(() {
  //           _isPlaying = false;
  //           _currentAudioUrl = null;
  //         });
  //       });
  //     }
  //   }
  // }

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
                      _attachments.removeAt(index);
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

  Widget buildTaskCompletionSection() {
    if (taskCodelists == null) {
      return Center(child: CircularProgressIndicator());
    }

    Map<String, String> taskCompletionType = taskCodelists!['taskCompletionType'].cast<String, String>();
    Map<String, String> taskApprovalRequired = taskCodelists!['approvalRequired'].cast<String, String>();
    Map<String, String> taskCompletionAuto = taskCodelists!['taskCompletionAuto'].cast<String, String>();
    Map<String, String> linkedTasks = taskCodelists!['linkedTasks'].cast<String, String>();
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
                              onChanged: (int? newValue) {
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
                        onChanged: (String? newValue) {
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
                              groupValue: selectedTaskApprovalType,
                              onChanged: (String? newValue) {
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

              if (selectedTaskApprovalType != null && selectedTaskApprovalType == '1')
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
                      DropdownButton<String>(
                        value: members.any((member) => member['id'].toString() == TaskApprover)
                            ? TaskApprover
                            : null,
                        items: members.map<DropdownMenuItem<String>>((member) {
                          return DropdownMenuItem<String>(
                            value: member['id']?.toString(),
                            child: Text(member['name'] ?? 'Unknown'),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            TaskApprover = newValue;
                            currentEditingField = 'approver';
                            _putCurrEditingValue('approver', newValue);
                            _onBtnSaveTaskInfoClicked();
                          });
                        },
                        hint: Text('Select a Member'),
                        isExpanded: true,
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
              if (selectedTaskApprovalType != null && selectedTaskApprovalType == '1' && (selectedTaskCompletionAuto == '2' || selectedTaskCompletionAuto == '3'))
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
                          onChanged: (String? newValue) {
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
          SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectedTaskApprovalType != null && selectedTaskApprovalType == '1')
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
                      if (autoStartTask != null && autoStartTask is Map && autoStartTask.isNotEmpty)
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
                          onChanged: (String? newValue) {
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
          SizedBox(height: 20),

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

  Widget buildActivitySection() {
    return SizedBox(
      height: 400, // Fixed height
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


  // Widget buildActivitySection() {
  //   return SizedBox(
  //     height: 400, // Define a fixed height or constrain it dynamically.
  //     child: Padding(
  //       padding: const EdgeInsets.symmetric(vertical: 10.0),
  //       child: Column(
  //         children: [
  //           // Input Section
  //           Padding(
  //             padding: const EdgeInsets.symmetric(vertical: 10.0),
  //             child: Row(
  //               children: [
  //                 IconButton(
  //                   icon: Icon(Icons.message, color: Colors.blue),
  //                   onPressed: () {},
  //                 ),
  //                 Expanded(
  //                   child: Padding(
  //                     padding: const EdgeInsets.symmetric(horizontal: 8.0),
  //                     child: TextField(
  //                       controller: _messageController,
  //                       decoration: InputDecoration(
  //                         hintText: "Enter the comment",
  //                         contentPadding: EdgeInsets.symmetric(
  //                             vertical: 10.0, horizontal: 16.0),
  //                         border: UnderlineInputBorder(
  //                           borderSide: BorderSide(color: Colors.blue),
  //                         ),
  //                         suffixIcon: IconButton(
  //                           icon: Icon(Icons.send, color: Colors.blue),
  //                           onPressed: () {
  //                             // Handle saving activity
  //                             currentEditingField = 'comment';
  //                             _onBtnSaveTaskInfoClicked();
  //                           },
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //                 IconButton(
  //                   icon: Icon(Icons.mic, color: _isRecording ? Colors.red : Colors.blue),
  //                   onPressed: () async {
  //                     // Handle recording audio
  //                     if (_isRecording) {
  //                       await _stopRecording();
  //                       currentEditingField = 'audio-comment';
  //                       _onBtnSaveTaskInfoClicked();
  //                     } else {
  //                       await _startRecording();
  //                     }
  //                   },
  //                 ),
  //                 if (_recordedAudioFilePath != null)
  //                   IconButton(
  //                     icon: Icon(
  //                         _isPlaying ? Icons.pause : Icons.play_arrow,
  //                         color: Colors.green),
  //                     onPressed: () async {
  //                       // Handle playing recorded audio
  //                       if (_player!.isPlaying) {
  //                         await _stopPlaying();
  //                       } else {
  //                         await _playRecordedAudio(_recordedAudioFilePath!);
  //                       }
  //                     },
  //                   ),
  //               ],
  //             ),
  //           ),
  //
  //           // Displaying activity list
  //           if (_activities.isNotEmpty)
  //             Expanded(
  //               child: ListView.builder(
  //                 shrinkWrap: true,
  //                 itemCount: _activities.length,
  //                 itemBuilder: (context, index) {
  //                   final activity = _activities[index];
  //                   String avatarInitial = activity.user.isNotEmpty
  //                       ? activity.user[0].toUpperCase()
  //                       : "?"; // Fallback for empty user names.
  //                   return Card(
  //                     margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
  //                     color: Colors.white,
  //                     child: ListTile(
  //                       leading: CircleAvatar(
  //                         backgroundColor: Colors.blue,
  //                         child: Text(
  //                           avatarInitial,
  //                           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  //                         ),
  //                       ),
  //                       // title: Text(activity.user),
  //                       title:  Row(
  //                         children: [
  //                           if (activity.type == 'audio')
  //                             Icon(Icons.mic, color: Colors.black),
  //                           SizedBox(width: 8.0), // Spacing between icon and title
  //                           Text(activity.type == 'text' ? activity.content : ''),
  //                         ],
  //                       ),
  //                         subtitle: Row(
  //                           crossAxisAlignment: CrossAxisAlignment.center,
  //                           children: [
  //                             // Date Icon and Date Value
  //                             Icon(Icons.calendar_today, color: Colors.grey, size: 16),
  //                             SizedBox(width: 1.0),
  //                             Text(
  //                               "${activity.date}",
  //                               style: TextStyle(fontSize: 12.0, color: Colors.grey),
  //                             ),
  //                             SizedBox(width: 4.0), // Space between date and time
  //
  //                             // Time Icon and Time Value
  //                             Icon(Icons.access_time, color: Colors.grey, size: 16),
  //                             SizedBox(width: 1.0),
  //                             Text(
  //                               "${activity.time}",
  //                               style: TextStyle(fontSize: 12.0, color: Colors.grey),
  //                             ),
  //                             SizedBox(width: 8.0), // Space between time and audio control
  //
  //                             if (activity.type == 'audio')
  //                               IconButton(
  //                                 icon: Icon(
  //                                   _isPlaying && _currentAudioUrl == activity.content
  //                                       ? Icons.pause
  //                                       : Icons.play_arrow,
  //                                   color: Colors.blueAccent,
  //                                 ),
  //                                 onPressed: () {
  //                                   // _playPauseAudio(activity.content);
  //                                   _downloadAndPlayAudio(activity);
  //                                 },
  //                               ),
  //                           ],
  //                       ),
  //                     ),
  //                   );
  //                 },
  //               ),
  //             )
  //           else
  //             Center(child: Text('No activities available.')),
  //         ],
  //       ),
  //     ),
  //   );
  // }

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
}
