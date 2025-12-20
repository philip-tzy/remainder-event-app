import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'events';

  // Create event
  Future<Map<String, dynamic>> createEvent(EventModel event) async {
    try {
      await _firestore.collection(_collectionName).add(event.toMap());
      return {
        'success': true,
        'message': 'Event created successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to create event: $e',
      };
    }
  }

  // Update event
  Future<Map<String, dynamic>> updateEvent(
      String eventId, EventModel event) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(eventId)
          .update(event.toMap());
      return {
        'success': true,
        'message': 'Event updated successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update event: $e',
      };
    }
  }

  // Delete event
  Future<Map<String, dynamic>> deleteEvent(String eventId) async {
    try {
      await _firestore.collection(_collectionName).doc(eventId).delete();
      return {
        'success': true,
        'message': 'Event deleted successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete event: $e',
      };
    }
  }

  // Get upcoming events - SIMPLIFIED (no composite index needed)
  Stream<List<EventModel>> getUpcomingEvents() {
    return _firestore
        .collection(_collectionName)
        .orderBy('start_at')
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      // Filter in memory to avoid composite index
      final events = snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .where((event) => event.endAt.isAfter(now))
          .toList();
      
      // Sort by start date
      events.sort((a, b) => a.startAt.compareTo(b.startAt));
      return events;
    });
  }

  // Get events by category - SIMPLIFIED
  Stream<List<EventModel>> getEventsByCategory(String category) {
    return _firestore
        .collection(_collectionName)
        .where('category', isEqualTo: category)
        .orderBy('start_at')
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      // Filter in memory to avoid composite index
      final events = snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .where((event) => event.endAt.isAfter(now))
          .toList();
      
      return events;
    });
  }

  // Get ALL events (including past events) - for admin
  Stream<List<EventModel>> getAllEvents() {
    return _firestore
        .collection(_collectionName)
        .orderBy('start_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get single event by ID
  Future<EventModel?> getEvent(String eventId) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(eventId).get();
      if (doc.exists) {
        return EventModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting event: $e');
      return null;
    }
  }

  // Alias for compatibility
  Future<EventModel?> getEventById(String eventId) async {
    return getEvent(eventId);
  }

  // Get today's events
  Future<List<EventModel>> getTodayEvents() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection(_collectionName)
          .orderBy('start_at')
          .get();

      // Filter in memory
      final events = snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .where((event) {
            return event.startAt.isAfter(startOfDay) &&
                   event.startAt.isBefore(endOfDay);
          })
          .toList();

      return events;
    } catch (e) {
      print('Error getting today events: $e');
      return [];
    }
  }
}
