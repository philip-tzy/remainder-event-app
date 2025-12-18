import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/event_model.dart';
import '../../models/rsvp_model.dart';
import '../../services/rsvp_service.dart';
import '../../services/notification_service.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailScreen({Key? key, required this.event}) : super(key: key);

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _rsvpService = RsvpService();
  final _notificationService = NotificationService();
  bool _isLoading = false;
  RsvpModel? _userRsvp;
  int _rsvpCount = 0;

  @override
  void initState() {
    super.initState();
    _loadRsvpData();
  }

  Future<void> _loadRsvpData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Check if user has RSVP'd
    final rsvp = await _rsvpService.getUserRsvpForEvent(userId, widget.event.id!);
    
    // Get RSVP count
    final count = await _rsvpService.getEventRsvpCount(widget.event.id!);

    if (mounted) {
      setState(() {
        _userRsvp = rsvp;
        _rsvpCount = count;
      });
    }
  }

  Future<void> _handleRsvp() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    if (_userRsvp == null) {
      // Create RSVP
      final rsvp = RsvpModel(
        eventId: widget.event.id!,
        userId: user.uid,
        userName: user.displayName ?? 'User',
        userEmail: user.email ?? '',
      );

      final result = await _rsvpService.createRsvp(rsvp);

      if (result['success']) {
        await _loadRsvpData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'Set Reminder',
                textColor: Colors.white,
                onPressed: () => _showReminderDialog(),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Cancel RSVP
      final result = await _rsvpService.cancelRsvp(_userRsvp!.id!);
      
      // Cancel notification if exists
      if (_userRsvp!.reminderEnabled) {
        await _notificationService.cancelEventReminder(widget.event.id!);
      }

      if (result['success']) {
        await _loadRsvpData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _showReminderDialog() async {
    if (_userRsvp == null) return;

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('When would you like to be reminded?'),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('15 minutes before'),
              leading: Radio<int>(
                value: 15,
                groupValue: _userRsvp?.reminderMinutesBefore,
                onChanged: (value) => Navigator.pop(context, value),
              ),
            ),
            ListTile(
              title: const Text('30 minutes before'),
              leading: Radio<int>(
                value: 30,
                groupValue: _userRsvp?.reminderMinutesBefore,
                onChanged: (value) => Navigator.pop(context, value),
              ),
            ),
            ListTile(
              title: const Text('1 hour before'),
              leading: Radio<int>(
                value: 60,
                groupValue: _userRsvp?.reminderMinutesBefore,
                onChanged: (value) => Navigator.pop(context, value),
              ),
            ),
            ListTile(
              title: const Text('1 day before'),
              leading: Radio<int>(
                value: 1440,
                groupValue: _userRsvp?.reminderMinutesBefore,
                onChanged: (value) => Navigator.pop(context, value),
              ),
            ),
          ],
        ),
        actions: [
          if (_userRsvp?.reminderEnabled == true)
            TextButton(
              onPressed: () async {
                await _notificationService.cancelEventReminder(widget.event.id!);
                await _rsvpService.updateReminder(_userRsvp!.id!, false, null);
                await _loadRsvpData();
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reminder cancelled'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              child: const Text('Remove Reminder'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result != null && _userRsvp != null) {
      // Update reminder settings
      await _rsvpService.updateReminder(_userRsvp!.id!, true, result);
      
      // Schedule notification
      await _notificationService.scheduleEventReminder(
        eventId: widget.event.id!,
        event: widget.event,
        minutesBefore: result,
      );

      await _loadRsvpData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder set for $result minutes before event'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy');
    final timeFormat = DateFormat('HH:mm');
    final isPast = widget.event.endAt.isBefore(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with category color
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _getCategoryColor(widget.event.category),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getCategoryColor(widget.event.category),
                    _getCategoryColor(widget.event.category).withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.event.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    widget.event.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // RSVP Count
                  Row(
                    children: [
                      const Icon(
                        Icons.people,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_rsvpCount ${_rsvpCount == 1 ? 'person' : 'people'} attending',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date and Time
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Date',
                    dateFormat.format(widget.event.startAt),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoRow(
                    Icons.access_time,
                    'Time',
                    '${timeFormat.format(widget.event.startAt)} - ${timeFormat.format(widget.event.endAt)}',
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoRow(
                    Icons.location_on,
                    'Location',
                    widget.event.location,
                  ),
                  const SizedBox(height: 24),
                  
                  // Description
                  const Text(
                    'About this event',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.event.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  
                  // Reminder info
                  if (_userRsvp?.reminderEnabled == true) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications_active,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Reminder set for ${_userRsvp!.reminderMinutesBefore} minutes before event',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _showReminderDialog,
                            child: const Text('Edit'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (_userRsvp != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _showReminderDialog,
                    icon: Icon(
                      _userRsvp?.reminderEnabled == true
                          ? Icons.notifications_active
                          : Icons.notifications_outlined,
                    ),
                    label: Text(
                      _userRsvp?.reminderEnabled == true
                          ? 'Edit Reminder'
                          : 'Set Reminder',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: _userRsvp != null ? 1 : 2,
                child: ElevatedButton.icon(
                  onPressed: (_isLoading || isPast) ? null : _handleRsvp,
                  icon: Icon(
                    _userRsvp != null
                        ? Icons.cancel_outlined
                        : Icons.check_circle_outline,
                  ),
                  label: Text(
                    isPast
                        ? 'Event Ended'
                        : (_userRsvp != null ? 'Cancel RSVP' : 'RSVP Now'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _userRsvp != null
                        ? Colors.orange
                        : Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey[600], size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'seminar':
        return Colors.blue;
      case 'competition':
        return Colors.orange;
      case 'ukm':
        return Colors.green;
      case 'workshop':
        return Colors.purple;
      case 'sports':
        return Colors.red;
      case 'cultural':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}