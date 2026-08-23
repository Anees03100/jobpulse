import 'dart:async';
import 'package:flutter/foundation.dart';

/// Bridges a Stream (like Firebase's authStateChanges) into a
/// Listenable that GoRouter can use to re-run its redirect logic
/// WITHOUT rebuilding the GoRouter instance itself.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
