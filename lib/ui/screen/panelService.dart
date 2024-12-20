import 'dart:convert';
import 'dart:io';

import 'package:flutter_tms/ui/screen/panelTaskInfo.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import '../../api/authService.dart';
import '../../api/apiConfig.dart';
import '../screen/panel.dart';

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

    print('Attach file Request: ' + jsonEncode(data));

    final response = await multipartRequest(url, data, files, header: {'Authorization' : 'Bearer $idt'});

    print('Attach file Response: ');
    // print(response);

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
      // return await http.Response.fromStream(response);
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
    String? _audioFileDate = _audioComment.date;
    String? _audioFileTime = _audioComment.time;

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

        print('_audioCommentURL: $_audioCommentURL');
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

}


  Future<FetchTaskAdditionalDetailsResponse> fetchTaskAdditionalDetails(String domainUrl, int companyId, String caseId, String panelId, String taskId, int type,
      String additionalDetailName, String additionalURLParams) async {
    final idt = await _authService.getIdt();

    if(additionalURLParams.trim().isNotEmpty && additionalURLParams.length > 0) {
      additionalURLParams = '&' + additionalURLParams;
    }

    print('companyId: $companyId, caseId: $caseId, panelId: $panelId,taskId: $taskId, type: $type, get: $additionalDetailName, $additionalURLParams');

    final String url = '$domainUrl/api/v1/user/company/case/panel/task/additional-details?'
        '&companyId=$companyId&caseId=$caseId&panelId=$panelId&taskId=$taskId&type=$type&get=$additionalDetailName$additionalURLParams';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $idt',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    print('Task Additional Details fetch response: ');
    print(response.body);

    return FetchTaskAdditionalDetailsResponse(response);
  }

}

class FetchTaskAdditionalDetailsResponse {
  bool success = false;
  String errorMessage = '';
  List<History> attachmentHistory = [];

  FetchTaskAdditionalDetailsResponse(dynamic response) {
    try {
      // Check for success
      if (response['success'] == true) {
        success = true;

        // Safely parse documentHistory
        final _rawDocHistory = response['data']?['documentHistory'];
        print("_rawDocHistory : $_rawDocHistory");
        if (_rawDocHistory is List) {
          for (var _history in _rawDocHistory) {
            if (_history is Map<String, dynamic>) {
              attachmentHistory.add(History(
                documentId: _history['documentId']?.toString() ?? '',
                versionId: _history['versionId']?.toString() ?? '',
                versionNo: _history['versionNo']?.toString() ?? '',
                name: _history['name']?.toString() ?? '',
                url: _history['url']?.toString() ?? '',
                date: _history['date']?.toString() ?? '',
                time: _history['time']?.toString() ?? '',
                fileName: _history['fileName']?.toString() ?? '',
              ));
            } else {
              print('Unexpected item in documentHistory: $_history');
            }
          }
        } else {
          print('Error: documentHistory is not a list or is missing');
        }
      } else {
        // Handle error message
        errorMessage = response['message']?.toString() ??
            response['data']?['errorMessage']?.toString() ??
            'Unknown error occurred';
        print('Error from server: $errorMessage');
      }
    } catch (e) {
      // Catch unexpected errors
      errorMessage = 'Error parsing response: $e';
      print('Error in FetchTaskAdditionalDetailsResponse: $e');
    }
  }

  
}

class History {
  final String documentId;
  final String versionId;
  final String versionNo;
  final String name;
  final String url;
  final String date;
  final String time;
  final String fileName;

  History({
    required this.documentId,
    required this.versionId,
    required this.versionNo,
    required this.name,
    required this.url,
    required this.date,
    required this.time,
    required this.fileName,
  });

  @override
  String toString() {
    return 'History(documentId: $documentId, versionId: $versionId, versionNo: $versionNo, name: $name, url: $url, date: $date, time: $time, fileName: $fileName)';
  }
}
