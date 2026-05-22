import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class PhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) codeSent,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(String) codeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
        forceResendingToken: forceResendingToken,
      );
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      verificationFailed(FirebaseAuthException(code: 'send_otp_failed', message: e.toString()));
    }
  }

  Future<bool> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // In this specific use case, we don't want to sign in with this credential,
      // because the user is already signed in via Email/Password.
      // We just want to link this phone credential to the current user.
      User? user = _auth.currentUser;
      if (user != null) {
        // Link the phone number to the current user account
        // Wrap in try/catch to handle if the phone number is already linked
        try {
          await user.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'provider-already-linked') {
            // It's already linked, which is fine
          } else if (e.code == 'credential-already-in-use') {
             // Another account uses this phone number
             throw Exception('This phone number is already linked to another account.');
          } else {
             rethrow;
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('OTP Verification Error: $e');
      return false;
    }
  }
}
