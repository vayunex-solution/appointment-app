import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';

class QueueStatusScreen extends StatefulWidget {
  const QueueStatusScreen({super.key});

  @override
  State<QueueStatusScreen> createState() => _QueueStatusScreenState();
}

class _QueueStatusScreenState extends State<QueueStatusScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _tokens = [];
  bool _isLoading = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _fetchStatus();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchStatus() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.get(ApiConfig.customerQueueStatus);
      if (result['success']) {
        setState(() {
          _tokens = List<Map<String, dynamic>>.from(result['data']['bookings'] ?? []);
        });
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  String _formatWait(int? minutes) {
    if (minutes == null || minutes <= 0) return 'Now';
    if (minutes < 60) return '~$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '~${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue Status'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchStatus),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tokens.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 60, color: Colors.white24),
                      const SizedBox(height: 12),
                      const Text('No active queue tokens for today', style: TextStyle(color: Colors.white54)),
                      const SizedBox(height: 24),
                      OutlinedButton(onPressed: _fetchStatus, child: const Text('Refresh')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchStatus,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tokens.length,
                    itemBuilder: (context, index) => _TokenCard(
                      token: _tokens[index],
                      formatWait: _formatWait,
                      pulseController: _pulseController,
                    ),
                  ),
                ),
    );
  }
}

class _TokenCard extends StatelessWidget {
  final Map<String, dynamic> token;
  final String Function(int?) formatWait;
  final AnimationController pulseController;

  const _TokenCard({required this.token, required this.formatWait, required this.pulseController});

  @override
  Widget build(BuildContext context) {
    final isMyTurn = token['is_my_turn'] == true;
    final tokensAhead = token['tokens_ahead'] ?? 0;
    final estimatedWaitMins = token['estimated_wait_minutes'];
    final currentServing = token['current_serving'];
    final isPriority = token['priority_flag'] == 1 || token['priority_flag'] == true;

    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: isMyTurn
                ? LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.6 + pulseController.value * 0.4),
                      AppTheme.secondaryColor.withOpacity(0.6 + pulseController.value * 0.4),
                    ],
                  )
                : null,
            color: isMyTurn ? null : AppTheme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: isPriority ? Border.all(color: Colors.amber, width: 1.5) : null,
            boxShadow: isMyTurn
                ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Your turn banner
                if (isMyTurn)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_active, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('🎉 YOUR TURN!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),

                // Shop name
                Text(
                  token['shop_name'] ?? '',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(token['service_name'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.white54)),
                const SizedBox(height: 16),

                // Token number (big)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isPriority) const Icon(Icons.priority_high, color: Colors.amber, size: 20),
                    Text(
                      token['token_number'] ?? '',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isMyTurn ? Colors.white : AppTheme.accentColor),
                    ),
                  ],
                ),
                Text('Queue #${token['queue_position'] ?? '-'}', style: const TextStyle(fontSize: 13, color: Colors.white54)),
                const SizedBox(height: 16),

                // Stats row
                if (!isMyTurn)
                  Row(
                    children: [
                      // Tokens ahead
                      Expanded(
                        child: _StatBlock(
                          icon: Icons.people,
                          value: '$tokensAhead',
                          label: 'Ahead',
                          color: tokensAhead <= 1 ? Colors.green : tokensAhead <= 3 ? Colors.orange : Colors.redAccent,
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.white12),
                      // Estimated wait
                      Expanded(
                        child: _StatBlock(
                          icon: Icons.timer,
                          value: formatWait(estimatedWaitMins),
                          label: 'Est. Wait',
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.white12),
                      // Now serving
                      Expanded(
                        child: _StatBlock(
                          icon: Icons.play_circle_fill,
                          value: currentServing?['token_number']?.toString().substring(4, 10) ?? '—',
                          label: 'Serving',
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatBlock extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;

  const _StatBlock({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
      ],
    );
  }
}
