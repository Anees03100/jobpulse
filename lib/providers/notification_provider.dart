import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobpulse/services/firebase/notification_handler.dart';

final notificationHandlerProvider = Provider<NotificationHandler>((ref) {
  final handler = NotificationHandler();
  ref.onDispose(handler.dispose);
  return handler;
});
