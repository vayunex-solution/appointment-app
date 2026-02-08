// API Configuration
class ApiConfig {
  // Change this to your backend URL
  static const String baseUrl = 'http://127.0.0.1:5000/api';
  
  // Auth endpoints
  static const String registerCustomer = '$baseUrl/auth/register/customer';
  static const String registerProvider = '$baseUrl/auth/register/provider';
  static const String verifyEmail = '$baseUrl/auth/verify-email';
  static const String login = '$baseUrl/auth/login';
  static const String forgotPassword = '$baseUrl/auth/forgot-password';
  static const String resetPassword = '$baseUrl/auth/reset-password';
  static const String profile = '$baseUrl/auth/profile';
  
  // Provider endpoints
  static const String providerProfile = '$baseUrl/provider/profile';
  static const String providerServices = '$baseUrl/provider/services';
  static const String providerBookings = '$baseUrl/provider/bookings';
  static const String providerWallet = '$baseUrl/provider/wallet';
  
  // Customer endpoints
  static const String providers = '$baseUrl/customer/providers';
  
  // Booking endpoints
  static const String bookings = '$baseUrl/bookings';
  static const String myBookings = '$baseUrl/bookings/my';
  
  // Admin endpoints
  static const String adminPendingProviders = '$baseUrl/admin/providers/pending';
  static const String adminUsers = '$baseUrl/admin/users';
  static const String adminReports = '$baseUrl/admin/reports';
  static const String adminLogs = '$baseUrl/admin/logs';
}
