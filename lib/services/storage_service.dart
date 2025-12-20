import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  // Pick image from camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Error taking photo: $e');
      return null;
    }
  }

  // Upload profile picture to Firebase Storage
  Future<Map<String, dynamic>> uploadProfilePicture({
    required String userId,
    required File imageFile,
  }) async {
    try {
      // Create reference
      final ref = _storage.ref().child('profile_pictures/$userId.jpg');

      // Upload file
      final uploadTask = ref.putFile(imageFile);

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return {
        'success': true,
        'url': downloadUrl,
        'message': 'Profile picture uploaded successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to upload profile picture: $e',
      };
    }
  }

  // Delete profile picture
  Future<Map<String, dynamic>> deleteProfilePicture({
    required String userId,
  }) async {
    try {
      final ref = _storage.ref().child('profile_pictures/$userId.jpg');
      await ref.delete();

      return {
        'success': true,
        'message': 'Profile picture deleted successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete profile picture: $e',
      };
    }
  }
}
