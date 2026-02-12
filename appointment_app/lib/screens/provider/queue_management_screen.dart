import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';

class QueueManagementScreen extends StatefulWidget {
  const QueueManagementScreen({super.key});

  @override
  State<QueueManagementScreen> createState() => _QueueManagementScreenState();
}

class _QueueManagementScreenState extends State<QueueManagementScreen> {
  List<Map<String, dynamic>> _queue = [];
  Map<String, dynamic>? _currentServing;
  int _totalPending = 0;
  int _completed = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchQueue();
  }

  Future<void> _fetchQueue() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.get(ApiConfig.providerQueue);
      if (result['success']) {
        setState(() {
          _queue = List<Map<String, dynamic>>.from(result['data']['queue'] ?? []);
          _currentServing = result['data']['currentServing'];
          _totalPending = result['data']['totalInQueue'] ?? 0;
          _completed = result['data']['completed'] ?? 0;
        });
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _serveToken(int id) async {
    final result = await ApiService.patch('${ApiConfig.providerQueue.replaceAll('/today', '')}/$id/serve', {});
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Now serving this customer'), backgroundColor: Colors.green),
      );
      _fetchQueue();
    }
  }

  Future<void> _completeToken(int id) async {
    final result = await ApiService.patch('${ApiConfig.providerQueue.replaceAll('/today', '')}/$id/complete', {});
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service completed!'), backgroundColor: Colors.blue),
      );
      _fetchQueue();
    }
  }

  Future<void> _skipToken(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Skip Customer'),
        content: const Text('Mark this customer as no-show/skipped?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Skip')),
        ],
      ),
    );
    if (confirm == true) {
      final result = await ApiService.patch('${ApiConfig.providerQueue.replaceAll('/today', '')}/$id/skip', {});
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer skipped'), backgroundColor: Colors.orange),
        );
        _fetchQueue();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue Management'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchQueue),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats bar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppTheme.cardColor,
                  child: Row(
                    children: [
                      _MiniStat(label: 'In Queue', value: '$_totalPending', color: Colors.orange),
                      _MiniStat(label: 'Completed', value: '$_completed', color: AppTheme.successColor),
                      _MiniStat(label: 'Total', value: '${_queue.length}', color: AppTheme.primaryColor),
                    ],
                  ),
                ),

                // Currently serving banner
                if (_currentServing != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text('NOW SERVING', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text(
                          _currentServing!['token_number'] ?? '',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          _currentServing!['customer_name'] ?? '',
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.done_all),
                          label: const Text('COMPLETE'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primaryColor),
                          onPressed: () => _completeToken(_currentServing!['id']),
                        ),
                      ],
                    ),
                  ),

                if (_currentServing == null && _totalPending > 0)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.play_circle, size: 40, color: Colors.orange),
                        const SizedBox(height: 8),
                        const Text('No customer being served', style: TextStyle(color: Colors.orange)),
                        const Text('Tap "Serve" on next customer in queue', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),

                // Queue list
                Expanded(
                  child: _queue.isEmpty
                      ? const Center(child: Text('No bookings for today'))
                      : RefreshIndicator(
                          onRefresh: _fetchQueue,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _queue.length,
                            itemBuilder: (context, index) {
                              final item = _queue[index];
                              final status = item['status'] ?? 'pending';
                              if (status == 'completed') return _CompletedToken(item: item);
                              return _QueueToken(
                                item: item,
                                isServing: status == 'confirmed',
                                onServe: () => _serveToken(item['id']),
                                onComplete: () => _completeToken(item['id']),
                                onSkip: () => _skipToken(item['id']),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
        ],
      ),
    );
  }
}

class _QueueToken extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isServing;
  final VoidCallback onServe, onComplete, onSkip;

  const _QueueToken({required this.item, required this.isServing, required this.onServe, required this.onComplete, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isServing ? AppTheme.primaryColor.withOpacity(0.15) : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Token number badge
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isServing ? AppTheme.primaryColor : Colors.white12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${item['queue_number'] ?? '-'}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isServing ? Colors.white : Colors.white70),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Customer info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['customer_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(item['token_number'] ?? '', style: TextStyle(fontSize: 12, color: AppTheme.accentColor)),
                  Text('${item['service_name'] ?? ''} • ${item['slot_time'] ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.white54)),
                ],
              ),
            ),

            // Actions
            if (isServing)
              IconButton(icon: const Icon(Icons.done_all, color: Colors.green), onPressed: onComplete, tooltip: 'Complete')
            else ...[
              IconButton(icon: const Icon(Icons.play_arrow, color: Colors.green), onPressed: onServe, tooltip: 'Serve'),
              IconButton(icon: const Icon(Icons.skip_next, color: Colors.orange), onPressed: onSkip, tooltip: 'Skip'),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompletedToken extends StatelessWidget {
  final Map<String, dynamic> item;
  const _CompletedToken({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check, color: Colors.green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['customer_name'] ?? '', style: const TextStyle(color: Colors.white54)),
                  Text(item['token_number'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.white38)),
                ],
              ),
            ),
            const Text('DONE', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
