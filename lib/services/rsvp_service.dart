import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rsvp_model.dart';

class RsvpService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'rsvps';

  CollectionReference get _rsvpCollection => 
      _firestore.collection(_collectionName);

  // Create RSVP
  Future<Map<String, dynamic>> createRsvp(RsvpModel rsvp) async {
    try {
      // Check if user already RSVP'd
      final existing = await _rsvpCollection
          .where('event_id', isEqualTo: rsvp.eventId)
          .where('user_id', isEqualTo: rsvp.userId)
          .get();

      if (existing.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'You have already RSVP\'d to this event',
        };
      }

      DocumentReference docRef = await _rsvpCollection.add(rsvp.toMap());
      
      return {
        'success': true,
        'message': 'RSVP successful!',
        'rsvpId': docRef.id,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to RSVP: $e',
      };
    }
  }

  // Cancel RSVP
  Future<Map<String, dynamic>> cancelRsvp(String rsvpId) async {
    try {
      await _rsvpCollection.doc(rsvpId).delete();
      
      return {
        'success': true,
        'message': 'RSVP cancelled',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to cancel RSVP: $e',
      };
    }
  }

  // Update reminder settings
  Future<Map<String, dynamic>> updateReminder(
    String rsvpId, 
    bool enabled, 
    int? minutesBefore
  ) async {
    try {
      await _rsvpCollection.doc(rsvpId).update({
        'reminder_enabled': enabled,
        'reminder_minutes_before': minutesBefore,
      });
      
      return {
        'success': true,
        'message': 'Reminder settings updated',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update reminder: $e',
      };
    }
  }

  // Check if user has RSVP'd to an event
  Future<RsvpModel?> getUserRsvpForEvent(String userId, String eventId) async {
    try {
      final snapshot = await _rsvpCollection
          .where('event_id', isEqualTo: eventId)
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return RsvpModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error checking RSVP: $e');
      return null;
    }
  }

  // Get all RSVPs for a user
  Stream<List<RsvpModel>> getUserRsvps(String userId) {
    return _rsvpCollection
        .where('user_id', isEqualTo: userId)
        .orderBy('rsvp_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RsvpModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get RSVP count for an event
  Future<int> getEventRsvpCount(String eventId) async {
    try {
      final snapshot = await _rsvpCollection
          .where('event_id', isEqualTo: eventId)
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting RSVP count: $e');
      return 0;
    }
  }

  // Get all RSVPs for an event (for admin)
  Stream<List<RsvpModel>> getEventRsvps(String eventId) {
    return _rsvpCollection
        .where('event_id', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) {
      // Convert to list
      final rsvps = snapshot.docs
          .map((doc) => RsvpModel.fromFirestore(doc))
          .toList();
      
      // Sort by rsvp_at ascending, handle null values
      rsvps.sort((a, b) {
        // Jika keduanya null, dianggap sama
        if (a.rsvpAt == null && b.rsvpAt == null) return 0;
        
        // Jika a null, taruh di belakang
        if (a.rsvpAt == null) return 1;
        
        // Jika b null, taruh di belakang
        if (b.rsvpAt == null) return -1;
        
        // Keduanya tidak null, sort ascending (terlama dulu)
        return a.rsvpAt!.compareTo(b.rsvpAt!);
      });
      
      return rsvps;
    });
  }
}