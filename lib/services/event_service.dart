import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'events';

  // Get reference to events collection
  CollectionReference get _eventsCollection =>
      _firestore.collection(_collectionName);

  // Create new event
  Future<Map<String, dynamic>> createEvent(EventModel event) async {
    try {
      DocumentReference docRef = await _eventsCollection.add(event.toMap());

      return {
        'success': true,
        'message': 'Event created successfully',
        'eventId': docRef.id,
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to create event: $e'};
    }
  }

  // Update existing event
  Future<Map<String, dynamic>> updateEvent(
    String eventId,
    EventModel event,
  ) async {
    try {
      await _eventsCollection.doc(eventId).update(event.toMap());

      return {'success': true, 'message': 'Event updated successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update event: $e'};
    }
  }

  // Delete event
  Future<Map<String, dynamic>> deleteEvent(String eventId) async {
    try {
      await _eventsCollection.doc(eventId).delete();

      return {'success': true, 'message': 'Event deleted successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete event: $e'};
    }
  }

  // ✅ FIXED: Get all events (Stream for real-time updates)
  // Simplified query - only orderBy start_at
  Stream<List<EventModel>> getAllEvents() {
    return _eventsCollection
        .orderBy('start_at', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .toList();
        });
  }

  // Get single event by ID
  Future<EventModel?> getEventById(String eventId) async {
    try {
      DocumentSnapshot doc = await _eventsCollection.doc(eventId).get();

      if (doc.exists) {
        return EventModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting event: $e');
      return null;
    }
  }

  // ✅ FIXED: Get events by category
  // Filter in-memory to avoid composite index requirement
  Stream<List<EventModel>> getEventsByCategory(String category) {
    return _eventsCollection
        .orderBy('start_at', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .where((event) => event.category == category)
              .toList();
        });
  }

  // ✅ FIXED: Get upcoming events
  // Simplified - get all events and filter in-memory
  Stream<List<EventModel>> getUpcomingEvents() {
    return _eventsCollection
        .orderBy('start_at', descending: false)
        .snapshots()
        .map((snapshot) {
          final now = DateTime.now();

          // Filter events where end_at hasn't passed
          return snapshot.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .where((event) => event.endAt.isAfter(now))
              .toList();
        });
  }

  // ✅ NEW: Get past events (events that have ended)
  Stream<List<EventModel>> getPastEvents() {
    return _eventsCollection
        .orderBy('start_at', descending: true)
        .snapshots()
        .map((snapshot) {
          final now = DateTime.now();

          // Filter events where end_at has passed
          return snapshot.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .where((event) => event.endAt.isBefore(now))
              .toList();
        });
  }

  // ✅ NEW: Search events by keyword (in-memory search)
  Stream<List<EventModel>> searchEvents(String keyword) {
    return _eventsCollection
        .orderBy('start_at', descending: false)
        .snapshots()
        .map((snapshot) {
          final lowercaseKeyword = keyword.toLowerCase();

          return snapshot.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .where((event) {
                return event.title.toLowerCase().contains(lowercaseKeyword) ||
                    event.description.toLowerCase().contains(
                      lowercaseKeyword,
                    ) ||
                    event.location.toLowerCase().contains(lowercaseKeyword) ||
                    event.category.toLowerCase().contains(lowercaseKeyword);
              })
              .toList();
        });
  }

  // ✅ NEW: Get events with pagination (for better performance)
  Future<List<EventModel>> getEventsPaginated({
    int limit = 20,
    DocumentSnapshot? startAfterDoc,
  }) async {
    try {
      Query query = _eventsCollection
          .orderBy('start_at', descending: false)
          .limit(limit);

      if (startAfterDoc != null) {
        query = query.startAfterDocument(startAfterDoc);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting paginated events: $e');
      return [];
    }
  }
}
