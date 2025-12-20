import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Authenticate user
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Get user role from Firestore
      String role = await getUserRole(userCredential.user!.uid);

      return {
        'success': true,
        'role': role,
        'message': 'Login successful',
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred. Please try again.',
      };
    }
  }

  // Register new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? major,
    String? batch,
    String? concentration,
    String? classCode,
  }) async {
    try {
      // Validate student data
      if (role == 'user' && (major == null || batch == null || classCode == null)) {
        return {
          'success': false,
          'message': 'Students must select major, batch, and class',
        };
      }

      // Create user account
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Create user model
      final userModel = UserModel(
        uid: userCredential.user!.uid,
        email: email.trim(),
        name: name.trim(),
        role: role,
        major: role == 'user' ? major : null,
        batch: role == 'user' ? batch : null,
        concentration: role == 'user' ? concentration : null,
        classCode: role == 'user' ? classCode : null,
        photoURL: null,
      );

      // Save user data to Firestore
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userModel.toMap());

      return {
        'success': true,
        'role': role,
        'message': 'Registration successful',
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred. Please try again.',
      };
    }
  }

  // Get user role from Firestore
  Future<String> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.get('role') ?? 'user';
      }
      return 'user';
    } catch (e) {
      return 'user';
    }
  }

  // Get full user data
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateUserProfile({
    required String uid,
    String? name,
    String? major,
    String? batch,
    String? concentration,
    String? classCode,
    String? photoURL,
  }) async {
    try {
      Map<String, dynamic> updates = {};

      if (name != null) updates['name'] = name;
      if (major != null) updates['major'] = major;
      if (batch != null) updates['batch'] = batch;
      if (concentration != null) updates['concentration'] = concentration;
      if (classCode != null) updates['class'] = classCode;
      if (photoURL != null) updates['photo_url'] = photoURL;

      await _firestore.collection('users').doc(uid).update(updates);

      return {
        'success': true,
        'message': 'Profile updated successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update profile: $e',
      };
    }
  }

  // Update profile picture
  Future<Map<String, dynamic>> updateProfilePicture({
    required String uid,
    required String photoURL,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'photo_url': photoURL,
      });

      return {
        'success': true,
        'message': 'Profile picture updated successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update profile picture: $e',
      };
    }
  }

  // Remove profile picture
  Future<Map<String, dynamic>> removeProfilePicture({
    required String uid,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'photo_url': FieldValue.delete(),
      });

      return {
        'success': true,
        'message': 'Profile picture removed successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to remove profile picture: $e',
      };
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Helper method to get user-friendly error messages
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'invalid-email':
        return 'Invalid email address.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
