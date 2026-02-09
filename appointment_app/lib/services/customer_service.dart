import 'package:flutter/material.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class CustomerService extends ChangeNotifier {
  List<dynamic> _providers = [];
  List<dynamic> _categories = [];
  List<dynamic> _bookings = [];
  Map<String, dynamic>? _selectedProvider;
  List<dynamic> _providerServices = [];
  List<dynamic> _availableSlots = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get providers => _providers;
  List<dynamic> get categories => _categories;
  List<dynamic> get bookings => _bookings;
  Map<String, dynamic>? get selectedProvider => _selectedProvider;
  List<dynamic> get providerServices => _providerServices;
  List<dynamic> get availableSlots => _availableSlots;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch all approved providers
  Future<void> fetchProviders({String? category, String? location, String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String url = ApiConfig.providers;
      List<String> params = [];
      if (category != null && category.isNotEmpty) params.add('category=$category');
      if (location != null && location.isNotEmpty) params.add('location=$location');
      if (search != null && search.isNotEmpty) params.add('search=$search');
      if (params.isNotEmpty) url += '?${params.join('&')}';

      final result = await ApiService.get(url);
      if (result['success']) {
        _providers = result['data']['providers'] ?? [];
      } else {
        _error = result['error'];
      }
    } catch (e) {
      _error = 'Failed to fetch providers';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Fetch categories
  Future<void> fetchCategories() async {
    try {
      final result = await ApiService.get(ApiConfig.categories);
      if (result['success']) {
        _categories = result['data']['categories'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      // Silent fail for categories
    }
  }

  // Fetch provider details
  Future<void> fetchProviderDetails(int providerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.get('${ApiConfig.providers}/$providerId');
      if (result['success']) {
        _selectedProvider = result['data']['provider'];
      }
    } catch (e) {
      _error = 'Failed to fetch provider details';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Fetch provider services
  Future<void> fetchProviderServices(int providerId) async {
    try {
      final result = await ApiService.get('${ApiConfig.providers}/$providerId/services');
      if (result['success']) {
        _providerServices = result['data']['services'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to fetch services';
    }
  }

  // Fetch available slots
  Future<void> fetchAvailableSlots(int providerId, String date) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.get('${ApiConfig.providers}/$providerId/slots?date=$date');
      if (result['success']) {
        _availableSlots = result['data']['slots'] ?? [];
      }
    } catch (e) {
      _error = 'Failed to fetch slots';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Create booking
  Future<Map<String, dynamic>?> createBooking({
    required int providerId,
    required int serviceId,
    required String bookingDate,
    required String slotTime,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.post(ApiConfig.bookings, {
        'provider_id': providerId,
        'service_id': serviceId,
        'booking_date': bookingDate,
        'slot_time': slotTime,
      });

      _isLoading = false;
      notifyListeners();

      if (result['success']) {
        return result['data']['booking'];
      }
      _error = result['error'];
      return null;
    } catch (e) {
      _error = 'Failed to create booking';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Fetch my bookings
  Future<void> fetchMyBookings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.get(ApiConfig.myBookings);
      if (result['success']) {
        _bookings = result['data']['bookings'] ?? [];
      }
    } catch (e) {
      _error = 'Failed to fetch bookings';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Cancel booking
  Future<bool> cancelBooking(int bookingId) async {
    try {
      final result = await ApiService.put('${ApiConfig.bookings}/$bookingId/cancel', {});
      if (result['success']) {
        await fetchMyBookings();
        return true;
      }
      _error = result['error'];
      return false;
    } catch (e) {
      _error = 'Failed to cancel booking';
      return false;
    }
  }

  // Clear selected provider
  void clearSelection() {
    _selectedProvider = null;
    _providerServices = [];
    _availableSlots = [];
  }
}
