import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/notification_api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationApiService>().fetchNotifications();
    });
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'booking_confirmed':
        return Icons.check_circle;
      case 'your_turn':
        return Icons.notifications_active;
      case 'turn_approaching':
        return Icons.hourglass_top;
      case 'booking_completed':
        return Icons.done_all;
      case 'booking_cancelled':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'booking_confirmed':
        return const Color(0xFF4CAF50);
      case 'your_turn':
        return const Color(0xFFFF5722);
      case 'turn_approaching':
        return const Color(0xFFFFC107);
      case 'booking_completed':
        return const Color(0xFF2196F3);
      case 'booking_cancelled':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _formatTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1A1F36),
        elevation: 0,
        actions: [
          Consumer<NotificationApiService>(
            builder: (context, service, _) {
              if (service.unreadCount > 0) {
                return TextButton(
                  onPressed: () => service.markAllRead(),
                  child: Text(
                    'Mark All Read',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF7C4DFF),
                      fontSize: 13,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationApiService>(
        builder: (context, service, _) {
          if (service.isLoading && service.notifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C4DFF)),
            );
          }

          if (service.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll see booking confirmations &\nqueue alerts here',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => service.fetchNotifications(),
            color: const Color(0xFF7C4DFF),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: service.notifications.length,
              itemBuilder: (context, index) {
                final notif = service.notifications[index];
                final isRead = notif['is_read'] == true || notif['is_read'] == 1;
                final type = notif['type'] ?? 'general';

                return Dismissible(
                  key: Key('notif-${notif['id']}'),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => service.markAsRead(notif['id']),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: const Color(0xFF7C4DFF).withOpacity(0.3),
                    child: const Icon(Icons.done, color: Colors.white),
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isRead
                          ? const Color(0xFF1A1F36)
                          : const Color(0xFF1A1F36).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: isRead
                          ? null
                          : Border.all(
                              color: _getNotificationColor(type)
                                  .withOpacity(0.3),
                              width: 1),
                    ),
                    child: ListTile(
                      onTap: () {
                        if (!isRead) service.markAsRead(notif['id']);
                      },
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color:
                              _getNotificationColor(type).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getNotificationIcon(type),
                          color: _getNotificationColor(type),
                          size: 24,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              notif['title'] ?? '',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: isRead
                                    ? FontWeight.w400
                                    : FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF7C4DFF),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            notif['body'] ?? '',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatTime(notif['created_at'] ?? ''),
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
