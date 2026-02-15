import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/biometric_service.dart';
import '../config/api_config.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _biometricAvailable = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get biometricAvailable => _biometricAvailable;

  // Check biometric availability on init
  Future<void> checkBiometricAvailability() async {
    _biometricAvailable = await BiometricService.isAvailable() &&
        await BiometricService.hasSavedCredentials();
    notifyListeners();
  }

  // Login with email/mobile + password
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

        // Save credentials for biometric login
        if (await BiometricService.isAvailable()) {
          await BiometricService.saveCredentials(identifier, password);
          _biometricAvailable = true;
        }

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
      print('LOGIN ERROR: $e');
      _error = 'Connection error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login with Biometric (fingerprint/face)
  Future<bool> loginWithBiometric() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authenticated = await BiometricService.authenticate();
      if (!authenticated) {
        _error = 'Biometric authentication failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final creds = await BiometricService.getSavedCredentials();
      if (creds == null) {
        _error = 'No saved credentials found. Please login with password first.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Use saved credentials to login
      return await login(creds['identifier']!, creds['password']!);
    } catch (e) {
      _error = 'Biometric login failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login with Google Sign-In
  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        _error = 'Google Sign-In cancelled';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        _error = 'Failed to get Google token';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Send token to backend
      final result = await ApiService.post(ApiConfig.googleLogin, {
        'idToken': idToken,
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
      print('GOOGLE LOGIN ERROR: $e');
      _error = 'Google sign-in failed: $e';
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
    // Don't clear biometric credentials on logout so user can use fingerprint next time
    _user = null;
    notifyListeners();
  }

  // Check auth status on app start
  Future<void> checkAuthStatus() async {
    final token = await ApiService.getToken();
    if (token != null) {
      await fetchProfile();
    }
    await checkBiometricAvailability();
  }
}
