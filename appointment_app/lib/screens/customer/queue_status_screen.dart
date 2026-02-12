import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';

class QueueStatusScreen extends StatefulWidget {
  const QueueStatusScreen({super.key});

  @override
  State<QueueStatusScreen> createState() => _QueueStatusScreenState();
}

class _QueueStatusScreenState extends State<QueueStatusScreen> {
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchQueueStatus();
  }

  Future<void> _fetchQueueStatus() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.get(ApiConfig.customerQueueStatus);
      if (result['success']) {
        setState(() {
          _bookings = List<Map<String, dynamic>>.from(result['data']['bookings'] ?? []);
        });
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Queue Status'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchQueueStatus),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.queue, size: 80, color: Colors.white24),
                      const SizedBox(height: 16),
                      const Text('No active queue', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      const Text("You don't have any bookings for today", style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchQueueStatus,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _bookings.length,
                    itemBuilder: (context, index) {
                      final booking = _bookings[index];
                      return _QueueCard(booking: booking);
                    },
                  ),
                ),
    );
  }
}

class _QueueCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  const _QueueCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final tokenNumber = booking['token_number'] ?? '';
    final status = booking['status'] ?? 'pending';
    final shopName = booking['shop_name'] ?? '';
    final serviceName = booking['service_name'] ?? '';
    final slotTime = booking['slot_time'] ?? '';
    final queueNumber = booking['queue_number'] ?? 0;
    final peopleAhead = booking['people_ahead'] ?? 0;
    final currentServingToken = booking['current_serving_token'];
    final isMyTurn = status == 'confirmed';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isMyTurn
            ? LinearGradient(colors: [AppTheme.primaryColor.withOpacity(0.3), AppTheme.secondaryColor.withOpacity(0.3)])
            : null,
        color: isMyTurn ? null : AppTheme.cardColor,
        border: isMyTurn ? Border.all(color: AppTheme.primaryColor, width: 2) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Shop name + service
            Row(
              children: [
                Icon(Icons.store, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shopName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('$serviceName • $slotTime', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Your token
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('YOUR TOKEN', style: TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.bold)),
                  Text(tokenNumber, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
                  Text('Queue #$queueNumber', style: const TextStyle(color: Colors.white54)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Status
            if (isMyTurn)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.primaryColor, AppTheme.secondaryColor]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.notifications_active, color: Colors.white, size: 32),
                    SizedBox(height: 4),
                    Text("🎉 IT'S YOUR TURN!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Please proceed to the counter', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              )
            else
              Row(
                children: [
                  // People ahead
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text('$peopleAhead', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
                          const Text('People Ahead', style: TextStyle(fontSize: 11, color: Colors.white54)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Currently serving
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            currentServingToken ?? 'None',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                          const Text('Now Serving', style: TextStyle(fontSize: 11, color: Colors.white54)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
