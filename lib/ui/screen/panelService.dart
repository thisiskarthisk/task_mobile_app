import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../../api/authService.dart';
import '../../api/apiConfig.dart';
import '../screen/panel.dart';

class panelService {
  final AuthService _authService = AuthService();
  final ApiConfig _apiConfig = ApiConfig();

  Future<dynamic> getCasePanelTaskInfo(String appUrl, int companyId, int caseId, int panelId, int taskId) async {
    final idt = await _authService.getIdt();
    try {
      final panelInfo = await http.get(
        Uri.parse('$appUrl${ApiConfig.casePanelTaskInfo}?companyId=$companyId&caseId=$caseId&panelId=$panelId&taskId=$taskId'),
        headers: {
          'Authorization': 'Bearer $idt',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      if (panelInfo.statusCode == 200) {
        return json.decode(panelInfo.body);
      } else {
        throw Exception('Failed to fetch panels. Status Code: ${panelInfo.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching panel info: $e');
    }
  }

  Future<dynamic> getCompanyCasePanels(String domainUrl, int companyId, int caseId) async {
    final idt = await _authService.getIdt();
    try {
      final panelInfo = await http.get(
        Uri.parse('$domainUrl${ApiConfig.casePanels}?companyId=$companyId&caseId=$caseId'),
        headers: {
          'Authorization': 'Bearer $idt',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      if (panelInfo.statusCode == 200) {
        return json.decode(panelInfo.body);
      } else {
        throw Exception('Error: Failed to fetch panels (status code: ${panelInfo.statusCode})');
      }
    } catch (e) {
      throw Exception('Error fetching panel info: $e');
    }
  }

  Future<void> getPanelDetails(String domainUrl, int companyId, int caseId, int panelId) async {
    final idt = await _authService.getIdt();
    try {
      final panelDetails = await http.get(
        Uri.parse('$domainUrl${ApiConfig.casePanelInfo}?companyId=$companyId&caseId=$caseId&panelId=$panelId'),
        headers: {
          'Authorization': 'Bearer $idt',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (panelDetails.statusCode == 200) {
        return json.decode(panelDetails.body);
      } else {
        throw Exception('Error: Failed to fetch panel details (status code: ${panelDetails.statusCode})');
      }
    } catch (e) {
      throw Exception('Error fetching panel details for panel ID $panelId: $e');
    }
  }

  Future<dynamic> updateTaskInfo(String domainUrl, int companyId, int caseId ,int panelId, int taskId, Map<String, dynamic> data) async {
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
        throw Exception('Error: Failed to add task (status code: ${taskInfo.statusCode})');
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

}

