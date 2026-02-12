import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Config
import 'config/theme.dart';

// Services
import 'services/auth_provider.dart';
import 'services/provider_service.dart';
import 'services/customer_service.dart';
import 'services/admin_service.dart';

// Screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/customer/home_screen.dart';
import 'screens/customer/browse_providers_screen.dart';
import 'screens/customer/provider_details_screen.dart';
import 'screens/customer/my_bookings_screen.dart';
import 'screens/provider/dashboard_screen.dart';
import 'screens/provider/services_screen.dart';
import 'screens/provider/add_service_screen.dart';
import 'screens/provider/profile_screen.dart';
import 'screens/provider/availability_screen.dart';
import 'screens/provider/provider_bookings_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/pending_providers_screen.dart';
import 'screens/admin/manage_users_screen.dart';
import 'screens/admin/reports_screen.dart';
import 'screens/admin/audit_logs_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProviderService()),
        ChangeNotifierProvider(create: (_) => CustomerService()),
        ChangeNotifierProvider(create: (_) => AdminService()),
      ],
      child: MaterialApp(
        title: 'BookNex',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/customer/home': (context) => const CustomerHomeScreen(),
          '/customer/browse': (context) => const BrowseProvidersScreen(),
          '/customer/provider-details': (context) => const ProviderDetailsScreen(),
          '/customer/my-bookings': (context) => const MyBookingsScreen(),
          '/provider/dashboard': (context) => const ProviderDashboardScreen(),
          '/provider/services': (context) => const ProviderServicesScreen(),
          '/provider/add-service': (context) => const AddServiceScreen(),
          '/provider/profile': (context) => const ProviderProfileScreen(),
          '/provider/availability': (context) => const AvailabilityScreen(),
          '/provider/bookings': (context) => const ProviderBookingsScreen(),
          '/admin/dashboard': (context) => const AdminDashboardScreen(),
          '/admin/pending-providers': (context) => const PendingProvidersScreen(),
          '/admin/users': (context) => const ManageUsersScreen(),
          '/admin/reports': (context) => const ReportsScreen(),
          '/admin/logs': (context) => const AuditLogsScreen(),
        },
      ),
    );
  }
}

// Wrapper to handle auth state
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Check auth status on app start
    Future.microtask(() {
      Provider.of<AuthProvider>(context, listen: false).checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Not logged in
        if (auth.user == null) {
          return const LoginScreen();
        }

        // Route based on role
        if (auth.user!.isAdmin) {
          return const AdminDashboardScreen();
        } else if (auth.user!.isCustomer) {
          return const CustomerHomeScreen();
        } else if (auth.user!.isProvider) {
          return const ProviderDashboardScreen();
        }

        // Default to login
        return const LoginScreen();
      },
    );
  }
}
