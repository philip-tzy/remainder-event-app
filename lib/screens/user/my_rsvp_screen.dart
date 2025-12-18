import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/rsvp_model.dart';
import '../../models/event_model.dart';
import '../../services/rsvp_service.dart';
import '../../services/event_service.dart';
import '../../widgets/event_list_item.dart';
import 'event_detail_screen.dart';

class MyRsvpScreen extends StatelessWidget {
  const MyRsvpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My RSVPs'),
        ),
        body: const Center(
          child: Text('Please login to view your RSVPs'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My RSVPs'),
      ),
      body: StreamBuilder<List<RsvpModel>>(
        stream: RsvpService().getUserRsvps(userId),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          // Empty state
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No RSVP yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Browse events and RSVP to attend',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          final rsvps = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rsvps.length,
            itemBuilder: (context, index) {
              final rsvp = rsvps[index];
              
              // Get event details
              return FutureBuilder<EventModel?>(
                future: EventService().getEventById(rsvp.eventId),
                builder: (context, eventSnapshot) {
                  if (eventSnapshot.connectionState == ConnectionState.waiting) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    );
                  }

                  if (!eventSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final event = eventSnapshot.data!;

                  return EventListItem(
                    event: event,
                    showRsvpBadge: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventDetailScreen(
                            event: event,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}