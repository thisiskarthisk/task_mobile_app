import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final url = Uri.parse(ApiConfig.loginEndpoint);

      final response = await http.post(
        url,
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
        }),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json'
        },
      );

      if (response.statusCode == 200) { // Check for success or specific error handling
        print("User Login Successfully");

        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final prefs = await SharedPreferences.getInstance(); // If login is successful, save the token to SharedPreferences
          final token = responseData['data']?['token'];
          final idt = responseData['data']?['idt'];
          final name = responseData['data']?['name'];
          final email = responseData['data']?['email'];

          if (token != null) { // Ensure token is not empty before saving
            await prefs.setString('authToken', token);
            await prefs.setString('taskAccessToken', idt);
            await prefs.setString('userName', name);
            await prefs.setString('userEmail', email);

            print('Auth token saved successfully: $token');
          } else {
            print('Token is empty or invalid.');
          }
        }
        return responseData;

      } else {

        print("Failed to login. Status Code: ${response.statusCode}"); // Log error for debugging purposes
        print("Error Body: ${response.body}");

        return {
          'success': false,
          'message': 'Failed to login',
          'statusCode': response.statusCode
        };
      }
    } catch (error) { // Catch network errors and other exceptions

      print("Connection error: $error");
      return {
        'success': false,
        'message': 'An error occurred during login',
        'error': error.toString()
      };
    }
  }

  Future<void> logout() async { // Logout method
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
  }

  Future<bool> isLoggedIn() async { // Method to check if user is logged in
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('authToken');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
  }

  Future<String?> getToken() async { // Retrieve the saved token (if needed for further API calls)
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<String?> getIdt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('taskAccessToken');
  }

  Future<Map<String, String?>> getUserData() async { // Retrieve saved user data
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('userName');
    final userEmail = prefs.getString('userEmail');

    return {'userName': userName, 'userEmail': userEmail};
  }
}
