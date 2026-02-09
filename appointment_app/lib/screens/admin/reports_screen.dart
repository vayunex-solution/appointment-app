import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/admin_service.dart';
import '../../config/theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<AdminService>(context, listen: false).fetchReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
      ),
      body: Consumer<AdminService>(
        builder: (context, admin, _) {
          if (admin.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = admin.reports;
          if (reports == null) {
            return const Center(child: Text('No reports available'));
          }

          final userStats = reports['users'] as List? ?? [];
          final bookingStats = reports['bookings'] as List? ?? [];
          final totalRevenue = reports['totalRevenue'] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Revenue Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.successColor, AppTheme.successColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.currency_rupee, size: 40, color: Colors.white),
                      const SizedBox(height: 8),
                      Text(
                        '₹$totalRevenue',
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const Text('Total Revenue', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // User Statistics
                Text('User Statistics', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ...userStats.map((stat) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getRoleColor(stat['role'] ?? ''),
                      child: Icon(_getRoleIcon(stat['role'] ?? ''), color: Colors.white),
                    ),
                    title: Text((stat['role'] ?? 'Unknown').toString().toUpperCase()),
                    trailing: Text(
                      '${stat['count']}',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _getRoleColor(stat['role'] ?? '')),
                    ),
                  ),
                )),
                const SizedBox(height: 24),

                // Booking Statistics
                Text('Booking Statistics', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ...bookingStats.map((stat) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(stat['status'] ?? ''),
                      child: Icon(_getStatusIcon(stat['status'] ?? ''), color: Colors.white),
                    ),
                    title: Text((stat['status'] ?? 'Unknown').toString().toUpperCase()),
                    trailing: Text(
                      '${stat['count']}',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _getStatusColor(stat['status'] ?? '')),
                    ),
                  ),
                )),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin': return Colors.purple;
      case 'provider': return AppTheme.primaryColor;
      case 'customer': return AppTheme.successColor;
      default: return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin': return Icons.admin_panel_settings;
      case 'provider': return Icons.store;
      case 'customer': return Icons.person;
      default: return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed': return AppTheme.successColor;
      case 'pending': return Colors.orange;
      case 'completed': return Colors.blue;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'confirmed': return Icons.check_circle;
      case 'pending': return Icons.pending;
      case 'completed': return Icons.done_all;
      case 'cancelled': return Icons.cancel;
      default: return Icons.help;
    }
  }
}
