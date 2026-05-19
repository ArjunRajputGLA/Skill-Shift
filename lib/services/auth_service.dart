import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = true;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  AuthService() {
    _auth.authStateChanges().listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        await _fetchUserProfile(firebaseUser.uid);
      } else {
        _currentUser = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> _fetchUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        _currentUser = UserModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        UserModel newUser = UserModel(
          id: cred.user!.uid,
          fullName: name,
          email: email,
          profileCompleted: false, // Explicitly false! They need to complete setup.
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(cred.user!.uid)
            .set(newUser.toMap())
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () => throw Exception('Firestore timeout.'),
            );
            
        _currentUser = newUser;
        notifyListeners();
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Signup failed';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Will trigger the auth listener!
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Sign in failed';
    } catch (e) {
      return e.toString();
    }
  }

  // New method to handle saving the rest of the profile Setup!
  Future<String?> updateProfile(UserModel updatedUser) async {
    try {
      if (_currentUser == null) return "User is not logged in";

      // Changed from .update() to .set(SetOptions(merge: true))
      // This guarantees the database record is created even if signup failed to make the initial document earlier!
      await _firestore
          .collection('users')
          .doc(updatedUser.id)
          .set(updatedUser.toMap(), SetOptions(merge: true));
          
      _currentUser = updatedUser;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
