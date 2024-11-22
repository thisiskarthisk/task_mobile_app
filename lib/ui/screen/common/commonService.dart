import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../api/api_config.dart';
import '../../../api/authService.dart';

class commonService {
  List<Map<String, String >> instanceList = [];

  Future<List<Map<String, String>>> getSavedInstances() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, String>> savedInstances = [];

    // Loop to check all keys with the prefix `auth_instance_id_`
    int index = 0;
    while (prefs.containsKey('auth_instance_id_$index')) {
      final authInstanceId = prefs.getString('auth_instance_id_$index') ?? '';
      final instanceType = prefs.getString('instance_type_$index') ?? '';
      final domainUrl = prefs.getString('domain_url_$index') ?? '';

      savedInstances.add({
        'auth_instance_id': authInstanceId,
        'instance_type': instanceType,
        'domain_url': domainUrl,
      });

      index++;
    }
    setState(() {
      instanceList = savedInstances;
    });

    return savedInstances;
  }

  void setState(Null Function() param0) {}

}