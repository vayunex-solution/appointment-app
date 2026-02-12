import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/provider_service.dart';
import '../../config/theme.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final svc = Provider.of<ProviderService>(context, listen: false);
      svc.fetchDashboard();
      svc.fetchBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final svc = Provider.of<ProviderService>(context, listen: false);
              svc.fetchDashboard();
              svc.fetchBookings();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              }
            },
          ),
        ],
      ),
      body: Consumer<ProviderService>(
        builder: (context, providerSvc, _) {
          if (providerSvc.isLoading && providerSvc.stats == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = providerSvc.stats;
          final todayBookings = stats?['todayBookings']?.toString() ?? '0';
          final totalBookings = stats?['totalBookings']?.toString() ?? '0';
          final pendingBookings = stats?['pendingBookings']?.toString() ?? '0';
          final totalServices = stats?['totalServices']?.toString() ?? '0';
          final upcomingBookings = providerSvc.bookings
              .where((b) => b['status'] == 'pending' || b['status'] == 'confirmed')
              .take(5)
              .toList();

          return RefreshIndicator(
            onRefresh: () async {
              await providerSvc.fetchDashboard();
              await providerSvc.fetchBookings();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome
                  Text(
                    'Welcome, ${providerSvc.profile?['name'] ?? 'Provider'}!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (providerSvc.profile?['shop_name'] != null)
                    Text(providerSvc.profile!['shop_name'], style: const TextStyle(color: Colors.white60)),
                  const SizedBox(height: 20),

                  // Stats cards
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.calendar_today,
                          label: "Today's Bookings",
                          value: todayBookings,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.pending,
                          label: 'Pending',
                          value: pendingBookings,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.miscellaneous_services,
                          label: 'Active Services',
                          value: totalServices,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.event_available,
                          label: 'Total Bookings',
                          value: totalBookings,
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Quick actions
                  Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.add,
                          label: 'Add Service',
                          onTap: () => Navigator.pushNamed(context, '/provider/add-service'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.schedule,
                          label: 'Set Slots',
                          onTap: () => Navigator.pushNamed(context, '/provider/availability'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.build,
                          label: 'Services',
                          onTap: () => Navigator.pushNamed(context, '/provider/services'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Upcoming bookings
                  Row(
                    children: [
                      Text('Upcoming Appointments', style: Theme.of(context).textTheme.titleLarge),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/provider/bookings'),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (upcomingBookings.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.event_busy, size: 40, color: Colors.white24),
                              const SizedBox(height: 8),
                              const Text('No upcoming bookings', style: TextStyle(color: Colors.white54)),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ...upcomingBookings.map((booking) => _BookingCard(booking: booking)),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: AppTheme.surfaceColor,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.white54,
        onTap: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0: break; // Already on dashboard
            case 1: Navigator.pushNamed(context, '/provider/bookings');
            case 2: Navigator.pushNamed(context, '/provider/services');
            case 3: Navigator.pushNamed(context, '/provider/profile');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Services'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;

  const _BookingCard({required this.booking});

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return AppTheme.primaryColor;
      case 'completed': return AppTheme.successColor;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = booking['status'] ?? 'pending';
    final customerName = booking['customer_name'] ?? 'Unknown';
    final serviceName = booking['service_name'] ?? '';
    final slotTime = booking['slot_time'] ?? '';
    final tokenNumber = booking['token_number'] ?? '';
    final bookingDate = booking['booking_date']?.toString().split('T')[0] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: Text(customerName[0].toUpperCase()),
        ),
        title: Text(customerName),
        subtitle: Text('$serviceName • $bookingDate • $slotTime'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(tokenNumber, style: const TextStyle(fontSize: 11)),
            ),
            const SizedBox(height: 4),
            Text(status.toUpperCase(), style: TextStyle(fontSize: 10, color: _statusColor(status), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
