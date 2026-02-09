import 'package:flutter/material.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class AdminService extends ChangeNotifier {
  List<dynamic> _pendingProviders = [];
  List<dynamic> _allUsers = [];
  Map<String, dynamic>? _reports;
  List<dynamic> _logs = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get pendingProviders => _pendingProviders;
  List<dynamic> get allUsers => _allUsers;
  Map<String, dynamic>? get reports => _reports;
  List<dynamic> get logs => _logs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch pending providers for approval
  Future<void> fetchPendingProviders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.get(ApiConfig.adminPendingProviders);
      if (result['success']) {
        _pendingProviders = result['data']['providers'] ?? [];
      } else {
        _error = result['error'];
      }
    } catch (e) {
      _error = 'Failed to fetch pending providers';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Approve provider
  Future<bool> approveProvider(int providerId) async {
    try {
      final result = await ApiService.put(
        '${ApiConfig.baseUrl}/admin/providers/$providerId/approve',
        {},
      );
      if (result['success']) {
        _pendingProviders.removeWhere((p) => p['id'] == providerId);
        notifyListeners();
        return true;
      }
      _error = result['error'];
      return false;
    } catch (e) {
      _error = 'Failed to approve provider';
      return false;
    }
  }

  // Reject provider
  Future<bool> rejectProvider(int providerId) async {
    try {
      final result = await ApiService.put(
        '${ApiConfig.baseUrl}/admin/providers/$providerId/reject',
        {},
      );
      if (result['success']) {
        _pendingProviders.removeWhere((p) => p['id'] == providerId);
        notifyListeners();
        return true;
      }
      _error = result['error'];
      return false;
    } catch (e) {
      _error = 'Failed to reject provider';
      return false;
    }
  }

  // Fetch all users
  Future<void> fetchUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.get(ApiConfig.adminUsers);
      if (result['success']) {
        _allUsers = result['data']['users'] ?? [];
      }
    } catch (e) {
      _error = 'Failed to fetch users';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Block user
  Future<bool> blockUser(int userId) async {
    try {
      final result = await ApiService.put(
        '${ApiConfig.baseUrl}/admin/users/$userId/block',
        {},
      );
      if (result['success']) {
        final index = _allUsers.indexWhere((u) => u['id'] == userId);
        if (index != -1) {
          _allUsers[index]['is_blocked'] = true;
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Unblock user
  Future<bool> unblockUser(int userId) async {
    try {
      final result = await ApiService.put(
        '${ApiConfig.baseUrl}/admin/users/$userId/unblock',
        {},
      );
      if (result['success']) {
        final index = _allUsers.indexWhere((u) => u['id'] == userId);
        if (index != -1) {
          _allUsers[index]['is_blocked'] = false;
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Fetch reports
  Future<void> fetchReports() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.get(ApiConfig.adminReports);
      if (result['success']) {
        _reports = result['data'];
      }
    } catch (e) {
      _error = 'Failed to fetch reports';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Fetch logs
  Future<void> fetchLogs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.get(ApiConfig.adminLogs);
      if (result['success']) {
        _logs = result['data']['logs'] ?? [];
      }
    } catch (e) {
      _error = 'Failed to fetch logs';
    }

    _isLoading = false;
    notifyListeners();
  }
}
