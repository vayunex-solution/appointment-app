import 'package:flutter/material.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class ProviderService extends ChangeNotifier {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _stats;
  List<dynamic> _services = [];
  List<dynamic> _availability = [];
  List<dynamic> _bookings = [];
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get profile => _profile;
  Map<String, dynamic>? get stats => _stats;
  List<dynamic> get services => _services;
  List<dynamic> get availability => _availability;
  List<dynamic> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch dashboard data
  Future<void> fetchDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.get(ApiConfig.providerDashboard);
      if (result['success']) {
        _stats = result['data']['stats'];
        _profile = result['data']['provider'];
      } else {
        _error = result['error'];
      }
    } catch (e) {
      _error = 'Failed to fetch dashboard';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Fetch profile
  Future<void> fetchProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.get(ApiConfig.providerProfile);
      if (result['success']) {
        _profile = result['data']['provider'];
      }
    } catch (e) {
      _error = 'Failed to fetch profile';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Update profile
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.put(ApiConfig.providerProfile, data);
      _isLoading = false;
      notifyListeners();
      
      if (result['success']) {
        await fetchProfile();
        return true;
      }
      _error = result['error'];
      return false;
    } catch (e) {
      _error = 'Failed to update profile';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Fetch services
  Future<void> fetchServices() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.get(ApiConfig.providerServices);
      if (result['success']) {
        _services = result['data']['services'] ?? [];
      }
    } catch (e) {
      _error = 'Failed to fetch services';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Add service
  Future<bool> addService(Map<String, dynamic> serviceData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.post(ApiConfig.providerServices, serviceData);
      _isLoading = false;
      
      if (result['success']) {
        await fetchServices();
        notifyListeners();
        return true;
      }
      _error = result['error'];
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to add service';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update service
  Future<bool> updateService(int serviceId, Map<String, dynamic> serviceData) async {
    try {
      final result = await ApiService.put(
        '${ApiConfig.providerServices}/$serviceId',
        serviceData,
      );
      
      if (result['success']) {
        await fetchServices();
        return true;
      }
      _error = result['error'];
      return false;
    } catch (e) {
      _error = 'Failed to update service';
      return false;
    }
  }

  // Delete service
  Future<bool> deleteService(int serviceId) async {
    try {
      final result = await ApiService.delete('${ApiConfig.providerServices}/$serviceId');
      
      if (result['success']) {
        await fetchServices();
        return true;
      }
      _error = result['error'];
      return false;
    } catch (e) {
      _error = 'Failed to delete service';
      return false;
    }
  }

  // Fetch availability
  Future<void> fetchAvailability() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.get(ApiConfig.providerAvailability);
      if (result['success']) {
        _availability = result['data']['availability'] ?? [];
      }
    } catch (e) {
      _error = 'Failed to fetch availability';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Set availability for a day
  Future<bool> setAvailability(Map<String, dynamic> data) async {
    try {
      final result = await ApiService.post(ApiConfig.providerAvailability, data);
      
      if (result['success']) {
        await fetchAvailability();
        return true;
      }
      _error = result['error'];
      return false;
    } catch (e) {
      _error = 'Failed to set availability';
      return false;
    }
  }

  // Fetch bookings
  Future<void> fetchBookings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.get(ApiConfig.providerBookings);
      if (result['success']) {
        _bookings = result['data']['bookings'] ?? [];
      }
    } catch (e) {
      _error = 'Failed to fetch bookings';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Update booking status
  Future<bool> updateBookingStatus(int bookingId, String status) async {
    try {
      final result = await ApiService.put(
        '${ApiConfig.providerBookings}/$bookingId/status',
        {'status': status},
      );
      
      if (result['success']) {
        await fetchBookings();
        return true;
      }
      _error = result['error'];
      return false;
    } catch (e) {
      _error = 'Failed to update booking';
      return false;
    }
  }
}
