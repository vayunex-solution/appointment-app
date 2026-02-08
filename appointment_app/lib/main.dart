import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Config
import 'config/theme.dart';

// Services
import 'services/auth_provider.dart';

// Screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/customer/home_screen.dart';
import 'screens/provider/dashboard_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';

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
      ],
      child: MaterialApp(
        title: 'Appointment App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/customer/home': (context) => const CustomerHomeScreen(),
          '/provider/dashboard': (context) => const ProviderDashboardScreen(),
          '/admin/dashboard': (context) => const AdminDashboardScreen(),
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
