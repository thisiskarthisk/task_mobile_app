import 'dart:convert';

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

      print('taskInfo: ${taskInfo.body}');

      if (taskInfo.statusCode == 200) {
        return json.decode(taskInfo.body);
      } else {
        throw Exception('Error: Failed to add task (status code: ${taskInfo.statusCode})');
      }

    } catch (e) {
      throw Exception('Error fetching task info: $e');
    }
  }
}

