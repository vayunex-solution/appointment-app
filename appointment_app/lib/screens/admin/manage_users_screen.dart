import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/admin_service.dart';
import '../../config/theme.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  String _filterRole = 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<AdminService>(context, listen: false).fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
      ),
      body: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _filterRole == 'all',
                    onSelected: (_) => setState(() => _filterRole = 'all'),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Customers'),
                    selected: _filterRole == 'customer',
                    onSelected: (_) => setState(() => _filterRole = 'customer'),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Providers'),
                    selected: _filterRole == 'provider',
                    onSelected: (_) => setState(() => _filterRole = 'provider'),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Admins'),
                    selected: _filterRole == 'admin',
                    onSelected: (_) => setState(() => _filterRole = 'admin'),
                  ),
                ],
              ),
            ),
          ),

          // Users List
          Expanded(
            child: Consumer<AdminService>(
              builder: (context, admin, _) {
                if (admin.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                var users = admin.allUsers;
                if (_filterRole != 'all') {
                  users = users.where((u) => u['role'] == _filterRole).toList();
                }

                if (users.isEmpty) {
                  return const Center(child: Text('No users found'));
                }

                return RefreshIndicator(
                  onRefresh: () => admin.fetchUsers(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _UserCard(user: user);
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

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;

  const _UserCard({required this.user});

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'provider':
        return AppTheme.primaryColor;
      case 'customer':
        return AppTheme.successColor;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBlocked = user['is_blocked'] == true || user['is_blocked'] == 1;
    final isVerified = user['is_verified'] == true || user['is_verified'] == 1;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isBlocked ? Colors.red : _getRoleColor(user['role'] ?? ''),
          child: Text(
            (user['name'] ?? 'U')[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(user['name'] ?? 'Unknown')),
            if (isBlocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('BLOCKED', style: TextStyle(fontSize: 10, color: Colors.red)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email'] ?? '', style: const TextStyle(fontSize: 12)),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user['role'] ?? '').withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (user['role'] ?? '').toUpperCase(),
                    style: TextStyle(fontSize: 10, color: _getRoleColor(user['role'] ?? '')),
                  ),
                ),
                const SizedBox(width: 8),
                if (isVerified)
                  Icon(Icons.verified, size: 14, color: AppTheme.successColor)
                else
                  Icon(Icons.pending, size: 14, color: Colors.orange),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            final admin = Provider.of<AdminService>(context, listen: false);
            if (value == 'block') {
              await admin.blockUser(user['id']);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User blocked')),
                );
              }
            } else if (value == 'unblock') {
              await admin.unblockUser(user['id']);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User unblocked')),
                );
              }
            }
          },
          itemBuilder: (context) => [
            if (!isBlocked)
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Block User'),
                  ],
                ),
              )
            else
              const PopupMenuItem(
                value: 'unblock',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Unblock User'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
