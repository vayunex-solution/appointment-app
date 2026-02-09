import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/admin_service.dart';
import '../../config/theme.dart';

class PendingProvidersScreen extends StatefulWidget {
  const PendingProvidersScreen({super.key});

  @override
  State<PendingProvidersScreen> createState() => _PendingProvidersScreenState();
}

class _PendingProvidersScreenState extends State<PendingProvidersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<AdminService>(context, listen: false).fetchPendingProviders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Approvals'),
      ),
      body: Consumer<AdminService>(
        builder: (context, admin, _) {
          if (admin.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (admin.pendingProviders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: AppTheme.successColor),
                  const SizedBox(height: 16),
                  const Text('No pending approvals!'),
                  const SizedBox(height: 8),
                  const Text('All providers have been reviewed', style: TextStyle(color: Colors.white54)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => admin.fetchPendingProviders(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: admin.pendingProviders.length,
              itemBuilder: (context, index) {
                final provider = admin.pendingProviders[index];
                return _ProviderApprovalCard(provider: provider);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ProviderApprovalCard extends StatelessWidget {
  final Map<String, dynamic> provider;

  const _ProviderApprovalCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    (provider['shop_name'] ?? 'P')[0].toUpperCase(),
                    style: const TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider['shop_name'] ?? 'Unknown',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        provider['category'] ?? '',
                        style: TextStyle(color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Details
            _DetailRow(icon: Icons.person, label: 'Owner', value: provider['name'] ?? ''),
            _DetailRow(icon: Icons.email, label: 'Email', value: provider['email'] ?? ''),
            _DetailRow(icon: Icons.phone, label: 'Mobile', value: provider['mobile'] ?? ''),
            _DetailRow(icon: Icons.location_on, label: 'Location', value: provider['location'] ?? ''),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text('REJECT'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Reject Provider'),
                          content: Text('Are you sure you want to reject ${provider['shop_name']}?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Reject'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        final success = await Provider.of<AdminService>(context, listen: false)
                            .rejectProvider(provider['id']);
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Provider rejected'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('APPROVE'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
                    onPressed: () async {
                      final success = await Provider.of<AdminService>(context, listen: false)
                          .approveProvider(provider['id']);
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${provider['shop_name']} approved!'), backgroundColor: AppTheme.successColor),
                        );
                      }
                    },
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white54),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
