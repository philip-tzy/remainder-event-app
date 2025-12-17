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
      return {
        'success': false,
        'message': 'Failed to create event: $e',
      };
    }
  }

  // Update existing event
  Future<Map<String, dynamic>> updateEvent(
    String eventId, 
    EventModel event
  ) async {
    try {
      await _eventsCollection.doc(eventId).update(event.toMap());
      
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
      await _eventsCollection.doc(eventId).delete();
      
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

  // Get all events (Stream for real-time updates)
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

  // Get events by category
  Stream<List<EventModel>> getEventsByCategory(String category) {
    return _eventsCollection
        .where('category', isEqualTo: category)
        .orderBy('start_at', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get upcoming events (events that haven't ended yet)
  Stream<List<EventModel>> getUpcomingEvents() {
    return _eventsCollection
        .where('end_at', isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('end_at', descending: false)
        .orderBy('start_at', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();
    });
  }
}