import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class FarreyStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  /// Uploads a file (PDF or Image) to Firebase Storage under farrey_notes/
  Future<String> uploadNoteFile(File file, String fileExtension, {Function(double)? onProgress}) async {
    try {
      final String fileName = '${_uuid.v4()}.$fileExtension';
      final Reference ref = _storage.ref().child('farrey_notes').child(fileName);
      
      final UploadTask uploadTask = ref.putFile(file);
      
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          if (snapshot.totalBytes > 0) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress(progress);
          }
        });
      }
      
      final TaskSnapshot snapshot = await uploadTask;
      
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading Farrey note file: $e');
      throw Exception('Storage Error: $e');
    }
  }

  /// Deletes a file from Firebase Storage
  Future<void> deleteNoteFile(String fileUrl) async {
    try {
      final Reference ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting Farrey note file: $e');
    }
  }
}
