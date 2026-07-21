import 'dart:async';

import 'package:serverpod/serverpod.dart';

/// Realtime demo: server → client WebSocket stream of clock ticks.
///
/// No Redis needed on a single Cloud Run instance (in-process stream).
class TickEndpoint extends Endpoint {
  /// Yields a tick every [intervalMs] milliseconds until the client cancels.
  Stream<String> clock(Session session, {int intervalMs = 1000}) async* {
    final interval = Duration(
      milliseconds: intervalMs.clamp(200, 10_000),
    );
    var n = 0;
    while (true) {
      n += 1;
      yield 'tick #$n @ ${DateTime.now().toUtc().toIso8601String()}';
      await Future<void>.delayed(interval);
    }
  }
}
