import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../models/job_model.dart';

/// Opens the job details screen when the user taps a push notification.
class NotificationHandler {
  GoRouter? _router;
  StreamSubscription<RemoteMessage>? _openedSub;

  Future<void> init(GoRouter router) async {
    _router = router;

    // App was fully closed and got launched by tapping a notification.
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) await _handle(initial);

    // App was in the background and the user tapped a notification.
    _openedSub ??= FirebaseMessaging.onMessageOpenedApp.listen(_handle);
  }

  void dispose() {
    _openedSub?.cancel();
    _openedSub = null;
  }

  Future<void> _handle(RemoteMessage message) async {
    final jobId = message.data['jobId'] as String?;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (jobId == null || uid == null || _router == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('sentJobs')
          .doc(jobId)
          .get();

      final data = snap.data();
      // Alerts sent before this feature only stored a title, so skip those.
      if (data == null || data['company'] == null) {
        debugPrint('Alert $jobId has no stored job details, staying on Home');
        return;
      }

      final job = JobModel.fromMap({...data, 'id': jobId});
      final score = (data['score'] as num?)?.toInt() ?? 0;

      _router!.push(
        '/opportunity-details',
        extra: {'job': job, 'score': score},
      );
    } catch (e) {
      debugPrint('Could not open alert: $e');
    }
  }
}
