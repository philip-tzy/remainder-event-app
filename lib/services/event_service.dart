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

  // Get upcoming events
  Stream<List<EventModel>> getUpcomingEvents() {
    return _firestore
        .collection(_collectionName)
        .where('start_at', isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('start_at')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get events by category
  Stream<List<EventModel>> getEventsByCategory(String category) {
    return _firestore
        .collection(_collectionName)
        .where('category', isEqualTo: category)
        .where('start_at', isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('start_at')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get all events for admin
  Stream<List<EventModel>> getAllEventsForAdmin() {
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

  // Get ALL events (for admin statistics)
  Stream<List<EventModel>> getAllEvents() {
    return _firestore
        .collection(_collectionName)
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
      final doc =
          await _firestore.collection(_collectionName).doc(eventId).get();
      if (doc.exists) {
        return EventModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting event: $e');
      return null;
    }
  }

  // DITAMBAHKAN: Get event by ID (alias untuk getEvent - untuk kompatibilitas)
  Future<EventModel?> getEventById(String eventId) async {
    return getEvent(eventId);
  }
}
