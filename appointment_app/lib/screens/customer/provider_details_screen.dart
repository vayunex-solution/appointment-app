import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/customer_service.dart';
import '../../config/theme.dart';

class ProviderDetailsScreen extends StatefulWidget {
  const ProviderDetailsScreen({super.key});

  @override
  State<ProviderDetailsScreen> createState() => _ProviderDetailsScreenState();
}

class _ProviderDetailsScreenState extends State<ProviderDetailsScreen> {
  int? _providerId;
  Map<String, dynamic>? _selectedService;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedSlot;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int && _providerId != args) {
      _providerId = args;
      final service = Provider.of<CustomerService>(context, listen: false);
      service.fetchProviderDetails(args);
      service.fetchProviderServices(args);
    }
  }

  void _fetchSlots() {
    if (_providerId != null) {
      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      Provider.of<CustomerService>(context, listen: false)
          .fetchAvailableSlots(_providerId!, dateStr);
      setState(() => _selectedSlot = null);
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedService == null || _selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service and time slot')),
      );
      return;
    }

    final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    
    final result = await Provider.of<CustomerService>(context, listen: false).createBooking(
      providerId: _providerId!,
      serviceId: _selectedService!['id'],
      bookingDate: dateStr,
      slotTime: _selectedSlot!,
    );

    if (result != null && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Booking Confirmed!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 64, color: AppTheme.successColor),
              const SizedBox(height: 16),
              Text(
                'Token: ${result['token_number']}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text('Date: ${result['date']}'),
              Text('Time: ${result['time']}'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Details'),
      ),
      body: Consumer<CustomerService>(
        builder: (context, service, _) {
          if (service.isLoading && service.selectedProvider == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final provider = service.selectedProvider;
          if (provider == null) {
            return const Center(child: Text('Provider not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Provider Header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppTheme.primaryColor,
                          child: Text(
                            (provider['shop_name'] ?? 'P')[0].toUpperCase(),
                            style: const TextStyle(fontSize: 32, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider['shop_name'] ?? 'Unknown',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              Text(
                                provider['category'] ?? '',
                                style: TextStyle(color: AppTheme.primaryColor),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 14, color: Colors.white54),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      provider['location'] ?? '',
                                      style: const TextStyle(color: Colors.white54),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Services Section
                Text('Select Service', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ...service.providerServices.map((svc) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: _selectedService?['id'] == svc['id'] 
                      ? AppTheme.primaryColor.withOpacity(0.3)
                      : null,
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedService = svc);
                      _fetchSlots();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  svc['service_name'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (svc['duration_minutes'] != null)
                                  Text(
                                    '${svc['duration_minutes']} mins',
                                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${svc['rate']}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
                const SizedBox(height: 24),

                // Date Selection
                if (_selectedService != null) ...[
                  Text('Select Date', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                        _fetchSlots();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.primaryColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: const TextStyle(fontSize: 18),
                          ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Time Slots
                  Text('Select Time', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  if (service.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (service.availableSlots.isEmpty)
                    const Text('No slots available for this date')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: service.availableSlots.map((slot) {
                        final isAvailable = slot['available'] == true;
                        final isSelected = _selectedSlot == slot['time'];
                        return ChoiceChip(
                          label: Text(slot['time'] ?? ''),
                          selected: isSelected,
                          onSelected: isAvailable ? (_) {
                            setState(() => _selectedSlot = slot['time']);
                          } : null,
                          backgroundColor: isAvailable ? null : Colors.grey[800],
                          labelStyle: TextStyle(
                            color: isAvailable ? null : Colors.grey,
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _selectedService != null && _selectedSlot != null
          ? Container(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _bookAppointment,
                child: Consumer<CustomerService>(
                  builder: (context, service, _) {
                    if (service.isLoading) {
                      return const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                    return Text(
                      'BOOK APPOINTMENT - ₹${_selectedService!['rate']}',
                    );
                  },
                ),
              ),
            )
          : null,
    );
  }
}
