import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'notification_service.dart';
import 'package:flutter/foundation.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> signInWithGoogle() async {
    try {
      // 1. Force clear previous login to ensure the account selector always opens
      await _googleSignIn.signOut();
      
      // 2. Open Google account selector
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      // If user cancels the login
      if (googleUser == null) {
        return 'Google sign-in was cancelled';
      }

      // 2. Obtain auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Authenticate with Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // 5. Check if user already exists in Firestore
        final doc = await _firestore.collection('users').doc(user.uid).get();

        if (!doc.exists) {
          // New user -> Create Firestore document
          final newUser = UserModel(
            id: user.uid,
            fullName: googleUser.displayName ?? user.displayName ?? '',
            email: googleUser.email,
            profileImageUrl: googleUser.photoUrl ?? user.photoURL,
            authProvider: 'google',
            profileCompleted: false,
            createdAt: DateTime.now(),
          );

          await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        }
        
        return null; // Success
      }
      
      return 'Failed to authenticate with Google';
    } on FirebaseAuthException catch (e) {
      return NotificationService.getAuthErrorMessage(e.code);
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return 'An unexpected error occurred during Google sign-in.';
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
