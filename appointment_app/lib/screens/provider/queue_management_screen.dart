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
  Map<String, dynamic>? _currentRunning;
  Map<String, dynamic> _stats = {};
  int _avgServiceTime = 900;
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
        final data = result['data'];
        setState(() {
          _queue = List<Map<String, dynamic>>.from(data['queue'] ?? []);
          _currentRunning = data['currentRunning'];
          _stats = Map<String, dynamic>.from(data['stats'] ?? {});
          _avgServiceTime = data['avgServiceTime'] ?? 900;

          // Fallback: if stats empty but queue has items, calculate from queue
          if (_stats.isEmpty && _queue.isNotEmpty) {
            _stats = {
              'pending_count': _queue.where((t) => t['status'] == 'pending').length,
              'running_count': _queue.where((t) => t['status'] == 'running' || t['status'] == 'confirmed').length,
              'completed_count': _queue.where((t) => t['status'] == 'completed').length,
              'skipped_count': _queue.where((t) => t['status'] == 'skipped').length,
              'total_count': _queue.length,
            };
            // Fallback: currentRunning from queue
            _currentRunning ??= _queue.cast<Map<String, dynamic>?>().firstWhere(
              (t) => t?['status'] == 'running' || t?['status'] == 'confirmed',
              orElse: () => null,
            );
          }
        });
      } else {
        // Show error to user so they know what's wrong
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('API Error: ${result['error'] ?? 'Failed to load queue'}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  String _baseQueueUrl() {
    return ApiConfig.providerQueue.replaceAll('/today', '');
  }

  Future<void> _callNext() async {
    try {
      final result = await ApiService.patch('${_baseQueueUrl()}/call-next', {});
      if (result['success']) {
        if (result['data']?['queue_empty'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Queue is empty — no pending tokens'), backgroundColor: Colors.orange),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Token called!'), backgroundColor: Colors.green),
          );
          _updateFromResponse(result['data']);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed'), backgroundColor: Colors.red),
        );
      }
    } catch (_) {}
  }

  Future<void> _completeToken(int id) async {
    final result = await ApiService.patch('${_baseQueueUrl()}/$id/complete', {});
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Service completed!'), backgroundColor: Colors.blue),
      );
      _updateFromResponse(result['data']);
    }
  }

  Future<void> _skipToken(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Skip Token'),
        content: const Text('Mark this customer as no-show/skipped?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Skip')),
        ],
      ),
    );
    if (confirm == true) {
      final result = await ApiService.patch('${_baseQueueUrl()}/$id/skip', {});
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token skipped'), backgroundColor: Colors.orange),
        );
        _updateFromResponse(result['data']);
      }
    }
  }

  Future<void> _cancelToken(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Token'),
        content: const Text('Cancel this booking?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Cancel Token')),
        ],
      ),
    );
    if (confirm == true) {
      final result = await ApiService.patch('${_baseQueueUrl()}/$id/cancel', {});
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token cancelled'), backgroundColor: Colors.red),
        );
        _updateFromResponse(result['data']);
      }
    }
  }

  Future<void> _togglePriority(int id) async {
    final result = await ApiService.patch('${_baseQueueUrl()}/$id/priority', {});
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Priority updated'), backgroundColor: Colors.purple),
      );
      _updateFromResponse(result['data']);
    }
  }

  void _updateFromResponse(Map<String, dynamic>? data) {
    if (data == null) return;
    setState(() {
      _queue = List<Map<String, dynamic>>.from(data['queue'] ?? _queue);
      _currentRunning = data['currentRunning'];
      _stats = Map<String, dynamic>.from(data['stats'] ?? _stats);
      _avgServiceTime = data['avgServiceTime'] ?? _avgServiceTime;
    });
  }

  String _formatTime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final mins = seconds ~/ 60;
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final pending = _stats['pending_count'] ?? 0;
    final completed = _stats['completed_count'] ?? 0;
    final total = _stats['total_count'] ?? 0;
    final skipped = _stats['skipped_count'] ?? 0;

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
                      _MiniStat(label: 'Pending', value: '$pending', color: Colors.orange),
                      _MiniStat(label: 'Completed', value: '$completed', color: AppTheme.successColor),
                      _MiniStat(label: 'Skipped', value: '$skipped', color: Colors.red),
                      _MiniStat(label: 'Avg Time', value: _formatTime(_avgServiceTime), color: AppTheme.primaryColor),
                    ],
                  ),
                ),

                // CALL NEXT button
                if (_currentRunning == null && pending > 0)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow, size: 28),
                        label: const Text('CALL NEXT TOKEN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _callNext,
                      ),
                    ),
                  ),

                // Currently running banner
                if (_currentRunning != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppTheme.primaryColor, AppTheme.secondaryColor]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text('🔔 NOW SERVING', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text(
                          _currentRunning!['token_number'] ?? '',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          '${_currentRunning!['customer_name'] ?? ''} • ${_currentRunning!['service_name'] ?? ''}',
                          style: const TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.done_all),
                              label: const Text('COMPLETE'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              onPressed: () => _completeToken(_currentRunning!['id']),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.skip_next),
                              label: const Text('SKIP'),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.orange, side: const BorderSide(color: Colors.orange)),
                              onPressed: () => _skipToken(_currentRunning!['id']),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                if (_currentRunning == null && pending == 0)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.inbox, size: 60, color: Colors.white24),
                        const SizedBox(height: 12),
                        Text(total == 0 ? 'No bookings for today' : 'All tokens served!', style: const TextStyle(color: Colors.white54, fontSize: 16)),
                      ],
                    ),
                  ),

                // Queue list
                Expanded(
                  child: _queue.isEmpty
                      ? const SizedBox()
                      : RefreshIndicator(
                          onRefresh: _fetchQueue,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _queue.length,
                            itemBuilder: (context, index) {
                              final item = _queue[index];
                              final status = item['status'] ?? 'pending';
                              if (status == 'running') return const SizedBox.shrink(); // shown in banner
                              if (status == 'completed' || status == 'skipped') return _DoneToken(item: item);
                              return _PendingToken(
                                item: item,
                                onSkip: () => _skipToken(item['id']),
                                onCancel: () => _cancelToken(item['id']),
                                onPriority: () => _togglePriority(item['id']),
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
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
        ],
      ),
    );
  }
}

class _PendingToken extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onSkip, onCancel, onPriority;

  const _PendingToken({required this.item, required this.onSkip, required this.onCancel, required this.onPriority});

  @override
  Widget build(BuildContext context) {
    final isPriority = item['priority_flag'] == 1 || item['priority_flag'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isPriority ? Colors.amber.withOpacity(0.1) : null,
      shape: isPriority ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.amber, width: 1)) : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Queue position badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isPriority ? Colors.amber.withOpacity(0.2) : Colors.white12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '#${item['queue_position'] ?? '-'}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isPriority ? Colors.amber : Colors.white70),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(item['customer_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                      if (isPriority) const Icon(Icons.priority_high, color: Colors.amber, size: 18),
                    ],
                  ),
                  Text(item['token_number'] ?? '', style: TextStyle(fontSize: 12, color: AppTheme.accentColor)),
                  Text('${item['service_name'] ?? ''} • ${item['slot_time']?.toString().substring(0, 5) ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.white54)),
                ],
              ),
            ),

            // Actions
            PopupMenuButton<String>(
              onSelected: (action) {
                if (action == 'skip') onSkip();
                if (action == 'cancel') onCancel();
                if (action == 'priority') onPriority();
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'priority', child: Row(children: [Icon(isPriority ? Icons.arrow_downward : Icons.priority_high, size: 18), const SizedBox(width: 8), Text(isPriority ? 'Remove Priority' : 'Set Priority')])),
                const PopupMenuItem(value: 'skip', child: Row(children: [Icon(Icons.skip_next, size: 18, color: Colors.orange), SizedBox(width: 8), Text('Skip')])),
                const PopupMenuItem(value: 'cancel', child: Row(children: [Icon(Icons.cancel, size: 18, color: Colors.red), SizedBox(width: 8), Text('Cancel')])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DoneToken extends StatelessWidget {
  final Map<String, dynamic> item;
  const _DoneToken({required this.item});

  @override
  Widget build(BuildContext context) {
    final isCompleted = item['status'] == 'completed';

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: Colors.white.withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(isCompleted ? Icons.check_circle : Icons.skip_next, color: isCompleted ? Colors.green : Colors.orange, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${item['customer_name'] ?? ''} — ${item['token_number'] ?? ''}',
                style: const TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
            Text(isCompleted ? 'DONE' : 'SKIPPED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isCompleted ? Colors.green : Colors.orange)),
          ],
        ),
      ),
    );
  }
}
