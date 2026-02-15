import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/provider_service.dart';
import '../../config/theme.dart';

class ProviderBookingsScreen extends StatefulWidget {
  const ProviderBookingsScreen({super.key});

  @override
  State<ProviderBookingsScreen> createState() => _ProviderBookingsScreenState();
}

class _ProviderBookingsScreenState extends State<ProviderBookingsScreen> {
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<ProviderService>(context, listen: false).fetchBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Bookings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<ProviderService>(context, listen: false).fetchBookings();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Filter
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(label: 'All', value: 'all', selected: _statusFilter, onSelect: (v) => setState(() => _statusFilter = v)),
                  _FilterChip(label: 'Pending', value: 'pending', selected: _statusFilter, onSelect: (v) => setState(() => _statusFilter = v)),
                  _FilterChip(label: 'Running', value: 'running', selected: _statusFilter, onSelect: (v) => setState(() => _statusFilter = v)),
                  _FilterChip(label: 'Completed', value: 'completed', selected: _statusFilter, onSelect: (v) => setState(() => _statusFilter = v)),
                  _FilterChip(label: 'Skipped', value: 'skipped', selected: _statusFilter, onSelect: (v) => setState(() => _statusFilter = v)),
                  _FilterChip(label: 'Cancelled', value: 'cancelled', selected: _statusFilter, onSelect: (v) => setState(() => _statusFilter = v)),
                ],
              ),
            ),
          ),

          // Bookings List
          Expanded(
            child: Consumer<ProviderService>(
              builder: (context, providerSvc, _) {
                if (providerSvc.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                var bookings = providerSvc.bookings;
                if (_statusFilter != 'all') {
                  bookings = bookings.where((b) => b['status'] == _statusFilter).toList();
                }

                if (bookings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 80, color: Colors.white24),
                        const SizedBox(height: 16),
                        const Text('No bookings found'),
                        const SizedBox(height: 8),
                        Text(
                          _statusFilter == 'all' ? 'You have no customer bookings yet' : 'No $_statusFilter bookings',
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => providerSvc.fetchBookings(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      return _BookingCard(booking: booking);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final Function(String) onSelect;

  const _FilterChip({required this.label, required this.value, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected == value,
        onSelected: (_) => onSelect(value),
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
      case 'confirmed': case 'running': return AppTheme.primaryColor;
      case 'completed': return AppTheme.successColor;
      case 'skipped': return Colors.deepOrange;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.pending;
      case 'confirmed': case 'running': return Icons.play_circle_fill;
      case 'completed': return Icons.done_all;
      case 'skipped': return Icons.skip_next;
      case 'cancelled': return Icons.cancel;
      default: return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = booking['status'] ?? 'pending';
    final tokenNumber = booking['token_number'] ?? '';
    final customerName = booking['customer_name'] ?? 'Unknown';
    final serviceName = booking['service_name'] ?? '';
    final bookingDate = booking['booking_date']?.toString().split('T')[0] ?? '';
    final slotTime = booking['slot_time'] ?? '';
    final customerMobile = booking['customer_mobile'] ?? '';
    final lockedPrice = booking['locked_price'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Token + Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(tokenNumber, style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(status), size: 14, color: _statusColor(status)),
                      const SizedBox(width: 4),
                      Text(status.toUpperCase(), style: TextStyle(fontSize: 11, color: _statusColor(status), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Customer Info
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(customerName[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(customerMobile, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Details
            Row(
              children: [
                Icon(Icons.miscellaneous_services, size: 14, color: Colors.white54),
                const SizedBox(width: 6),
                Expanded(child: Text(serviceName, style: const TextStyle(fontSize: 13))),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.white54),
                const SizedBox(width: 6),
                Text(bookingDate, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 14, color: Colors.white54),
                const SizedBox(width: 6),
                Text(slotTime, style: const TextStyle(fontSize: 13)),
              ],
            ),
            if (lockedPrice != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.currency_rupee, size: 14, color: Colors.white54),
                  const SizedBox(width: 6),
                  Text('₹$lockedPrice', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ],

            // Action Buttons
            if (status == 'pending' || status == 'running') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (status == 'pending') ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: const Text('Serve Now'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
                        onPressed: () async {
                          final svc = Provider.of<ProviderService>(context, listen: false);
                          final success = await svc.updateBookingStatus(booking['id'], 'running');
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Now serving!'), backgroundColor: Colors.green),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (status == 'running') ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.done_all, size: 16),
                        label: const Text('Complete'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        onPressed: () async {
                          final svc = Provider.of<ProviderService>(context, listen: false);
                          final success = await svc.updateBookingStatus(booking['id'], 'completed');
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Booking completed!'), backgroundColor: Colors.blue),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.skip_next, size: 16),
                        label: const Text('Skip'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.orange, side: const BorderSide(color: Colors.orange)),
                        onPressed: () async {
                          final svc = Provider.of<ProviderService>(context, listen: false);
                          final success = await svc.updateBookingStatus(booking['id'], 'skipped');
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Token skipped'), backgroundColor: Colors.orange),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Cancel Booking'),
                            content: Text('Cancel booking for $customerName?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text('Yes, Cancel'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          final svc = Provider.of<ProviderService>(context, listen: false);
                          final success = await svc.updateBookingStatus(booking['id'], 'cancelled');
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Booking cancelled'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
