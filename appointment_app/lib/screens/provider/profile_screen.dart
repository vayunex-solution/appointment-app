import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/provider_service.dart';
import '../../config/theme.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await Provider.of<ProviderService>(context, listen: false).fetchProfile();
      _populateFields();
    });
  }

  void _populateFields() {
    final profile = Provider.of<ProviderService>(context, listen: false).profile;
    if (profile != null) {
      _shopNameController.text = profile['shop_name'] ?? '';
      _categoryController.text = profile['category'] ?? '';
      _locationController.text = profile['location'] ?? '';
      _descriptionController.text = profile['description'] ?? '';
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<ProviderService>(context, listen: false);
    
    final success = await provider.updateProfile({
      'shop_name': _shopNameController.text.trim(),
      'category': _categoryController.text.trim(),
      'location': _locationController.text.trim(),
      'description': _descriptionController.text.trim(),
    });

    if (success && mounted) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to update profile'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: Consumer<ProviderService>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = provider.profile;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.primaryColor,
                          child: Text(
                            (profile?['name'] ?? 'P')[0].toUpperCase(),
                            style: const TextStyle(fontSize: 40, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          profile?['name'] ?? 'Provider',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          profile?['email'] ?? '',
                          style: TextStyle(color: Colors.white60),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: profile?['is_approved'] == true
                                ? AppTheme.successColor.withOpacity(0.2)
                                : Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            profile?['is_approved'] == true ? '✓ Approved' : '⏳ Pending Approval',
                            style: TextStyle(
                              color: profile?['is_approved'] == true
                                  ? AppTheme.successColor
                                  : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Shop Name
                  TextFormField(
                    controller: _shopNameController,
                    enabled: _isEditing,
                    decoration: const InputDecoration(
                      labelText: 'Shop/Business Name',
                      prefixIcon: Icon(Icons.store),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter shop name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category
                  TextFormField(
                    controller: _categoryController,
                    enabled: _isEditing,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter category';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Location
                  TextFormField(
                    controller: _locationController,
                    enabled: _isEditing,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter location';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    enabled: _isEditing,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save/Cancel Buttons
                  if (_isEditing)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() => _isEditing = false);
                              _populateFields();
                            },
                            child: const Text('CANCEL'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: provider.isLoading ? null : _saveProfile,
                            child: provider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('SAVE'),
                          ),
                        ),
                      ],
                    ),

                  // Wallet Balance
                  if (!_isEditing) ...[
                    const SizedBox(height: 24),
                    Card(
                      child: ListTile(
                        leading: Icon(Icons.account_balance_wallet, color: AppTheme.successColor),
                        title: const Text('Wallet Balance'),
                        trailing: Text(
                          '₹${profile?['wallet_balance'] ?? 0}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.successColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
