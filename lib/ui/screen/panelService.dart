import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import '../../api/authService.dart';
import '../../api/apiConfig.dart';

class panelService {
  final AuthService _authService = AuthService();
  final ApiConfig _apiConfig = ApiConfig();

  Future<dynamic> getCasePanelTaskInfo(String appUrl, int companyId, int caseId,
      int panelId, int taskId) async {
    final idt = await _authService.getIdt();
    try {
      final panelInfo = await http.get(
        Uri.parse('$appUrl${ApiConfig
            .casePanelTaskInfo}?companyId=$companyId&caseId=$caseId&panelId=$panelId&taskId=$taskId'),
        headers: {
          'Authorization': 'Bearer $idt',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      if (panelInfo.statusCode == 200) {
        return json.decode(panelInfo.body);
      } else {
        throw Exception(
            'Failed to fetch panels. Status Code: ${panelInfo.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching panel info: $e');
    }
  }

  Future<dynamic> getCompanyCasePanels(String domainUrl, int companyId,
      int caseId) async {
    final idt = await _authService.getIdt();
    try {
      final panelInfo = await http.get(
        Uri.parse('$domainUrl${ApiConfig
            .casePanels}?companyId=$companyId&caseId=$caseId'),
        headers: {
          'Authorization': 'Bearer $idt',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      if (panelInfo.statusCode == 200) {
        return json.decode(panelInfo.body);
      } else {
        throw Exception('Error: Failed to fetch panels (status code: ${panelInfo
            .statusCode})');
      }
    } catch (e) {
      throw Exception('Error fetching panel info: $e');
    }
  }

  Future<void> getPanelDetails(String domainUrl, int companyId, int caseId,
      int panelId) async {
    final idt = await _authService.getIdt();
    try {
      final panelDetails = await http.get(
        Uri.parse('$domainUrl${ApiConfig
            .casePanelInfo}?companyId=$companyId&caseId=$caseId&panelId=$panelId'),
        headers: {
          'Authorization': 'Bearer $idt',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (panelDetails.statusCode == 200) {
        return json.decode(panelDetails.body);
      } else {
        throw Exception(
            'Error: Failed to fetch panel details (status code: ${panelDetails
                .statusCode})');
      }
    } catch (e) {
      throw Exception('Error fetching panel details for panel ID $panelId: $e');
    }
  }

  Future<dynamic> updateTaskInfo(String domainUrl, int companyId, int caseId,
      int panelId, int taskId, Map<String, dynamic> data) async {
    final idt = await _authService.getIdt();
    try {
      data['companyId'] = '$companyId';
      data['caseId'] = caseId;
      data['panelId'] = panelId;
      data['taskId'] = taskId;

      final taskInfo = await http.post(
        Uri.parse('$domainUrl${ApiConfig.panelTaskInfo}'),
        headers: {
          'Authorization': 'Bearer $idt',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(data),
      );

      if (taskInfo.statusCode == 200) {
        return json.decode(taskInfo.body);
      } else {
        throw Exception(
            'Error: Failed to add task (status code: ${taskInfo.statusCode})');
      }
    } catch (e) {
      throw Exception('Error fetching task info: $e');
    }
  }

  Future<dynamic> attachFileToTask(String domainUrl, int companyId, int caseId ,int panelId, int taskId, Map<String, dynamic> data, Map<String, File> files) async {
    final idt = await _authService.getIdt();
    final url = domainUrl + '${ApiConfig.panelTaskInfo}';

    // Set additional request parameters
    data['companyId'] = '$companyId';
    data['caseId'] = caseId;
    data['panelId'] = panelId;
    data['taskId'] = taskId;

    final response = await multipartRequest(url, data, files, header: {'Authorization' : 'Bearer $idt'});

    return response;
  }

  // multipart file request function
  Future<dynamic> multipartRequest(String url, Map<String, dynamic> json, Map<String, File> files, {required Map<String, String> header}) async {
    var responseJson;

    var heads = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };

    if( header != null ) {
      header.forEach((key, value) {
        heads[key] = value;
      });
    }

    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));

      heads.forEach((String key, String value) {
        request.headers[key] = value;
      });

      json.forEach((String name, dynamic value) {
        request.fields[name] = value.toString();
      });

      files.forEach((String fieldName, File _file) async {
        request.files.add(await http.MultipartFile.fromPath(
            fieldName,
            _file.path
        ));
      });

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);
      responseJson = jsonDecode(responseData.body);

    } catch (error, errorContent) {
      print(error);
      print(errorContent);
      throw error;
    }

    return responseJson;
  }

  // download task audio comment function
  Future<String?> downloadTaskAudioComment(String domainUrl, int companyId, int caseId, int panelId, int taskId, Activity _audioComment) async {
    String? _audioFileLocalPath;

    final idt = await _authService.getIdt();

    String _audioCommentURL = _audioComment.content;
    String? _audioFileName = _audioComment.audioFileName;

    Map<String, String> headers = {
      'Authorization' : 'Bearer $idt',
      'Accept': 'application/json',
      'Content-Type': 'audio/x-hx-aac-adts',
    };

    String _audioCommentFolder = await getAudioCommentsStoragePath('$taskId');
    String _audioCommentFilePath = _audioCommentFolder+ '/' + _audioFileName!;

    File _audioFile = File(_audioCommentFilePath);

    await _audioFile.exists().then((isExists) async {
      // if(!isExists) {
        _audioCommentURL += '?companyId=$companyId&caseId=$caseId&panelId=$panelId&taskId=$taskId';

        final Response response = await http.get(Uri.parse(_audioCommentURL), headers: headers);

        await _audioFile.writeAsBytes(response.bodyBytes);
      // }
      _audioFileLocalPath = _audioFile.path;
    });

    return _audioFileLocalPath;
  }

  Future<String> getApplicationDownloadPath() async {
    String path = '';

    if(Platform.isAndroid) {
      path = '/sdcard/download';
    } else {
      Directory _externalDir = await getApplicationDocumentsDirectory();
      path = _externalDir.path;
    }

    path += '/proflujo';

    return path;
  }

  Future<String> getAudioCommentsStoragePath(String taskId) async {
    String path = await getApplicationDownloadPath();
    Directory _audioCommentsDir = Directory(path + '/audioComments/$taskId');

    await _audioCommentsDir.exists().then((bool isExists) async {
      if(!isExists) {
        await _audioCommentsDir.create(recursive: true);
      }
    });

    return _audioCommentsDir.path;
  }

  Future<FetchTaskAdditionalDetailsResponse> fetchTaskAdditionalDetails(String domainUrl, int companyId, int caseId,int panelId,
      int taskId, int type, String additionalDetailName, [String? additionalURLParams]) async
  {
    final idt = await _authService.getIdt();

    if (additionalURLParams != null && additionalURLParams.length > 0) {
      additionalURLParams = '&$additionalURLParams';
    }

    final String url =
        '$domainUrl${ApiConfig.taskAdditionalDetail}?companyId=$companyId&caseId=$caseId&panelId=$panelId&taskId=$taskId&type=$type&get=$additionalDetailName$additionalURLParams';

    print('fetchTaskAdditionalDetails()');
    print('url: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $idt',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        print('data: fetchTaskAdditionalDetails()-> $data');
        return FetchTaskAdditionalDetailsResponse.fromJson(data);
      } catch (e) {
        throw Exception('Error parsing response: $e');
      }
    } else {
      throw Exception('Failed to fetch additional details: ${response.statusCode}');
    }
  }

  Future<String> downloadTaskAttachment(String domainUrl, int companyId, int caseId, int panelId, int taskId, Attachment _attachment, [int? versionHistoryIndex]) async {
    final idt = await _authService.getIdt();
    String _attachLocalPath = '';
    String? comId = '${companyId}';
    String _attachmentUrl = _attachment.url;
    String? version;
    String? downloadFileName;

    Map<String, String> headers = {
      'Authorization' : 'Bearer $idt',
      'Accept': 'application/json',
      'Content-Type': 'image/*',
    };

    if(versionHistoryIndex != null) {
      _attachmentUrl = _attachment.documentHistoryList[versionHistoryIndex].url;
      version = _attachment.documentHistoryList[versionHistoryIndex].versionNo.toString();
      downloadFileName = _attachment.documentHistoryList[versionHistoryIndex].fileName;
    } else {
      downloadFileName = _attachment.fileName;
    }

    String _attachFolder = await getAttachmentsStoragePath('$taskId', '${_attachment.id}', '$version');
    String _attachFilePath = _attachFolder + '/' + downloadFileName!;
    File _attachFile = File(_attachFilePath);

    await _attachFile.exists().then((isExists) async {
      if(!isExists) {
        _attachmentUrl += '?companyId=$comId&caseId=$caseId&panelId=$panelId&taskId=$taskId';

        final response = await http.get((Uri.parse(_attachmentUrl)), headers: headers);
        await _attachFile.writeAsBytes(response.bodyBytes);
      }

      _attachLocalPath = _attachFile.path;
    });
    return _attachLocalPath;
  }

  Future<String> getAttachmentsStoragePath(String taskId, String docId, String version) async {
    String path = await getApplicationDownloadPath();
    version = version.isEmpty ? '' : '/v' + version;
    Directory _attachmentsDir = Directory(path + '/attachments/$taskId/$docId$version');

    await _attachmentsDir.exists().then((bool isExists) async {
      if(!isExists) {
        await _attachmentsDir.create(recursive: true);
      }
    });

    return _attachmentsDir.path;
  }
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
      audioFileName: json['audioFileName'] as String?,
    );
  }

  @override
  String toString() {
    return 'Activity{id: $id, content: $content, type: $type, user: $user, date: $date, time: $time, audioFileName: $audioFileName}';
  }
}

class Attachment {
  final String name, url, type, date, time;
  final String? fileName;
  final int id;
  bool isDocumentHistoryShown = false;
  List<DocumentHistory> documentHistoryList;

  Attachment({required this.id,required this.name, required this.url, required this.type, required this.date, required this.time, this.fileName, this.documentHistoryList = const [],});

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'],
      name: json['name'],
      url: json['url'],
      type: json['type'],
      date: json['date'],
      time: json['time'],
      fileName: json['fileName'] as String?,
      documentHistoryList: (json['documentHistoryList'] as List<dynamic>?)
          ?.map((e) => DocumentHistory.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  @override
  String toString() {
    return 'Attachment{id: $id, name: $name, url: $url, type: $type, date: $date, time: $time, fileName: $fileName, documentHistoryList: $documentHistoryList}';
  }
}

class DocumentHistory {
  final int documentId, versionId, versionNo;
  final String name, url, date, time, fileName;

  DocumentHistory({
    required this.documentId,
    required this.versionId,
    required this.versionNo,
    required this.name,
    required this.url,
    required this.date,
    required this.time,
    required this.fileName,
  });

  factory DocumentHistory.fromJson(Map<String, dynamic> json) {
    return DocumentHistory(
      documentId: json['documentId'],
      versionId: json['versionId'],
      versionNo: json['versionNo'],
      name: json['name'],
      url: json['url'],
      date: json['date'],
      time: json['time'],
      fileName: json['fileName'],
    );
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

class FetchTaskAdditionalDetailsResponse {
  bool success;
  String errorMessage;
  List<DocumentHistory> documentHistory;

  FetchTaskAdditionalDetailsResponse({
    required this.success,
    required this.errorMessage,
    required this.documentHistory,
  });

  /// Factory constructor to safely parse JSON
  factory FetchTaskAdditionalDetailsResponse.fromJson(Map<String, dynamic> response) {
    try {
      // Parse success flag
      final bool success = response['success'] == true;

      // Parse error message if the response indicates failure
      final String errorMessage = success
          ? ''
          : response['message']?.toString() ??
          response['data']?['errorMessage']?.toString() ??
          'Unknown error occurred';

      // Parse documentHistory
      final List<DocumentHistory> documentHistory = [];
      if (success) {
        final dynamic rawDocHistory = response['data']?['documentHistory'];
        if (rawDocHistory is List) {
          for (var history in rawDocHistory) {
            if (history is Map<String, dynamic>) {
              documentHistory.add(DocumentHistory.fromJson(history));
            } else {
              print('Unexpected item in documentHistory: $history');
            }
          }
        } else {
          print('Error: documentHistory is not a list or is missing');
        }
      }

      return FetchTaskAdditionalDetailsResponse(
        success: success,
        errorMessage: errorMessage,
        documentHistory: documentHistory,
      );
    } catch (e, stack) {
      print('Error in FetchTaskAdditionalDetailsResponse: $e');
      print(stack);
      return FetchTaskAdditionalDetailsResponse(
        success: false,
        errorMessage: 'Error parsing response: $e',
        documentHistory: [],
      );
    }
  }
}
