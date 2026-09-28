import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FcmService {
  final _messaging = FirebaseMessaging.instance;

  /// Requests permission and saves the device's FCM token to Firestore
  /// under the user's doc — this is what the GitHub Actions script will
  /// read to know where to send notifications.
  Future<void> initAndSaveToken(String uid) async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('🔔 Notification permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return; // user said no — respect it, don't nag
    }

    final token = await _messaging.getToken();
    debugPrint('🔑 FCM token: $token');

    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': token,
      });
    }

    // Keep the stored token fresh if it ever rotates (rare, but happens)
    _messaging.onTokenRefresh.listen((newToken) {
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': newToken,
      });
    });
  }
}
