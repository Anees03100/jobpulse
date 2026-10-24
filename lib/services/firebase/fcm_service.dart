import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FcmService {
  final _messaging = FirebaseMessaging.instance;
  StreamSubscription<String>? _refreshSub;

  /// Asks for permission and saves this device's token on the user's doc.
  Future<void> initAndSaveToken(String uid) async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('🔔 Notification permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await _messaging.getToken();
    if (token != null) await _saveToken(uid, token);

    // Only one refresh listener at a time, always tied to the current user.
    await _refreshSub?.cancel();
    _refreshSub = _messaging.onTokenRefresh.listen(
      (newToken) => _saveToken(uid, newToken),
    );
  }

  Future<void> _saveToken(String uid, String token) {
    return FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }

  /// Call BEFORE signing out. Stops alerts for this account reaching this
  /// device and makes the device generate a fresh token for the next login.
  /// Never blocks logout: if the network is down it gives up after 3 seconds.
  Future<void> clearToken(String uid) async {
    await _refreshSub?.cancel();
    _refreshSub = null;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'fcmToken': FieldValue.delete()})
          .timeout(const Duration(seconds: 3));
      await _messaging.deleteToken().timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('FCM token cleanup skipped: $e');
    }
  }
}
