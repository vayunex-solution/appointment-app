import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  // Login
  Future<bool> login(String identifier, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.post(ApiConfig.login, {
        'identifier': identifier,
        'password': password,
      });

      if (result['success']) {
        await ApiService.saveToken(result['data']['token']);
        _user = User.fromJson(result['data']['user']);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('LOGIN ERROR: $e'); // Debug log
      _error = 'Connection error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register Customer
  Future<Map<String, dynamic>> registerCustomer({
    required String name,
    required String email,
    required String mobile,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.post(ApiConfig.registerCustomer, {
        'name': name,
        'email': email,
        'mobile': mobile,
        'password': password,
      });

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': 'Connection error'};
    }
  }

  // Register Provider
  Future<Map<String, dynamic>> registerProvider({
    required String name,
    required String email,
    required String mobile,
    required String password,
    required String shopName,
    required String category,
    required String location,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.post(ApiConfig.registerProvider, {
        'name': name,
        'email': email,
        'mobile': mobile,
        'password': password,
        'shop_name': shopName,
        'category': category,
        'location': location,
      });

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': 'Connection error'};
    }
  }

  // Verify Email
  Future<bool> verifyEmail(String email, String code) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.post(ApiConfig.verifyEmail, {
        'email': email,
        'code': code,
      });

      if (result['success']) {
        await ApiService.saveToken(result['data']['token']);
        // Fetch user profile
        await fetchProfile();
      }

      _isLoading = false;
      notifyListeners();
      return result['success'];
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Fetch Profile
  Future<void> fetchProfile() async {
    try {
      final result = await ApiService.get(ApiConfig.profile);
      if (result['success']) {
        _user = User.fromJson(result['data']['user']);
        notifyListeners();
      }
    } catch (e) {
      // Silent fail
    }
  }

  // Logout
  Future<void> logout() async {
    await ApiService.removeToken();
    _user = null;
    notifyListeners();
  }

  // Check auth status on app start
  Future<void> checkAuthStatus() async {
    final token = await ApiService.getToken();
    if (token != null) {
      await fetchProfile();
    }
  }
}
