import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  // Get stored token
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Save token
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Remove token (logout)
  static Future<void> removeToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // GET request
  static Future<Map<String, dynamic>> get(String url) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    return _handleResponse(response);
  }

  // POST request
  static Future<Map<String, dynamic>> post(String url, Map<String, dynamic> body) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // PUT request
  static Future<Map<String, dynamic>> put(String url, Map<String, dynamic> body) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // DELETE request
  static Future<Map<String, dynamic>> delete(String url) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    return _handleResponse(response);
  }

  // Handle response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': data};
    } else {
      return {
        'success': false,
        'error': data['error'] ?? 'Something went wrong',
        'statusCode': response.statusCode,
      };
    }
  }
}
