import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Central place to convert exceptions into user-facing messages.
/// Add new cases here as new features (job APIs, FCM, etc.) introduce
/// new error types — screens should never need their own error mapping.
class ErrorMapper {
  ErrorMapper._();

  static String map(Object error) {
    if (error is FirebaseAuthException) return _mapAuthError(error);
    if (error is FirebaseException) return _mapFirestoreError(error);
    return 'Something went wrong. Please try again.';
  }

  static String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  static String _mapFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return "You don't have permission to do that.";
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again.';
      default:
        return 'Could not complete the request. Please try again.';
    }
  }
}
