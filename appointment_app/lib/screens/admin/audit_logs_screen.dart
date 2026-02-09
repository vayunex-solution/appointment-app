import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/admin_service.dart';
import '../../config/theme.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<AdminService>(context, listen: false).fetchLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Audit Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<AdminService>(context, listen: false).fetchLogs();
            },
          ),
        ],
      ),
      body: Consumer<AdminService>(
        builder: (context, admin, _) {
          if (admin.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (admin.logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text('No login logs yet'),
                  const SizedBox(height: 8),
                  const Text('Logs will appear when users login', style: TextStyle(color: Colors.white54)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => admin.fetchLogs(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: admin.logs.length,
              itemBuilder: (context, index) {
                final log = admin.logs[index];
                return _LogCard(log: log);
              },
            ),
          );
        },
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final Map<String, dynamic> log;

  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final isSuccess = log['success'] == true || log['success'] == 1;
    final createdAt = log['created_at'] != null ? DateTime.tryParse(log['created_at'].toString()) : null;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSuccess ? AppTheme.successColor : Colors.red,
          child: Icon(
            isSuccess ? Icons.login : Icons.error,
            color: Colors.white,
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(log['name'] ?? log['email'] ?? 'Unknown')),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSuccess ? AppTheme.successColor.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isSuccess ? 'SUCCESS' : 'FAILED',
                style: TextStyle(fontSize: 10, color: isSuccess ? AppTheme.successColor : Colors.red),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(log['email'] ?? '', style: const TextStyle(fontSize: 12)),
            Row(
              children: [
                Icon(Icons.computer, size: 12, color: Colors.white54),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    log['ip_address'] ?? 'Unknown IP',
                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ),
              ],
            ),
            if (createdAt != null)
              Row(
                children: [
                  Icon(Icons.access_time, size: 12, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(createdAt),
                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ],
              ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
