import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:buildtrack_mobile/services/api_service.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final notifs = await ApiService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String id) async {
    await ApiService.markNotificationAsRead(id);
    _fetchNotifications();
  }

  Future<void> _markAllRead() async {
    await ApiService.markAllNotificationsAsRead();
    _fetchNotifications();
  }

  Future<void> _clearAll() async {
    await ApiService.clearAllNotifications();
    _fetchNotifications();
  }

  String _formatTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, h:mm a').format(date);
    } catch (e) {
      return '';
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'approval': return Icons.check_circle;
      case 'payment': return Icons.attach_money;
      case 'inventory': return Icons.inventory;
      case 'project': return Icons.business;
      case 'worker': return Icons.person;
      default: return Icons.notifications;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'approval': return Colors.blue;
      case 'payment': return Colors.green;
      case 'inventory': return Colors.orange;
      case 'project': return Colors.purple;
      case 'worker': return Colors.blueAccent;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => n['read'] == false).length;

    return Scaffold(
      backgroundColor: AppColors.gradientStart,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppTopBar(
              title: 'Notifications',
              isSubScreen: true,
              leftIcon: Icons.arrow_back,
              onLeftTap: () => Navigator.maybePop(context),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    unreadCount > 0 ? '$unreadCount Unread' : 'All caught up!',
                    style: AppTheme.heading3,
                  ),
                  Row(
                    children: [
                      if (unreadCount > 0)
                        IconButton(
                          icon: const Icon(Icons.done_all, color: AppColors.primary),
                          onPressed: _markAllRead,
                          tooltip: 'Mark all as read',
                        ),
                      if (_notifications.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.delete_sweep, color: Colors.red),
                          onPressed: _clearAll,
                          tooltip: 'Clear all',
                        ),
                    ],
                  )
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _notifications.isEmpty
                      ? const Center(child: Text('No notifications'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final n = _notifications[index];
                            final isRead = n['read'] == true;
                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isRead ? Colors.grey.shade200 : AppColors.primary,
                                  width: isRead ? 1 : 2,
                                ),
                              ),
                              child: ListTile(
                                onTap: () => _markAsRead(n['_id']),
                                leading: CircleAvatar(
                                  backgroundColor: _getColor(n['type'] ?? '').withOpacity(0.1),
                                  child: Icon(_getIcon(n['type'] ?? ''), color: _getColor(n['type'] ?? '')),
                                ),
                                title: Text(
                                  n['title'] ?? '',
                                  style: AppTheme.heading3.copyWith(
                                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      n['message'] ?? '',
                                      style: TextStyle(fontSize: 14, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _formatTime(n['createdAt'] ?? ''),
                                      style: AppTheme.label.copyWith(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
