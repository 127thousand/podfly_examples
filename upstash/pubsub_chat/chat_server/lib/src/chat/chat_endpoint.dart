import 'dart:io' show Platform;

import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Cross-client chat via Serverpod messages + Redis (`global: true`).
///
/// Proof of multi-machine PubSub:
/// 1. [listen] first emits a `kind: hello` event with the **WebSocket host** machine id.
/// 2. [send] tags each line with the **HTTP handler** machine id (`global: true` → Redis).
/// 3. UI highlights when hello machine ≠ send machine (message crossed instances via Redis).
class ChatEndpoint extends Endpoint {
  static const channel = 'podfly_chat';

  /// Prefer Fly machine id so HA demos show which instance handled work.
  static String instanceId(Session session) {
    final fly = Platform.environment['FLY_MACHINE_ID'];
    if (fly != null && fly.isNotEmpty) {
      return fly.length > 6 ? fly.substring(fly.length - 6) : fly;
    }
    return session.server.serverId;
  }

  /// Subscribe to the global chat channel (WebSocket stream).
  ///
  /// First event is local (this process only): which machine owns the WS.
  /// Later chat events may originate on other machines and arrive via Redis.
  Stream<ChatMessage> listen(Session session) async* {
    final id = instanceId(session);
    yield ChatMessage(
      author: 'system',
      text: 'This tab’s WebSocket is on machine $id',
      at: DateTime.now().toUtc(),
      serverId: id,
      kind: 'hello',
    );
    yield* session.messages.createStream<ChatMessage>(channel);
  }

  /// Which machine would handle an RPC right now (HTTP load-balanced separately
  /// from the WebSocket). Useful to compare with the listen hello id.
  Future<String> whoami(Session session) async {
    return instanceId(session);
  }

  /// Publish a line to all listeners (requires Redis when multi-instance).
  Future<ChatMessage> send(
    Session session,
    String author,
    String text,
  ) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('text must not be empty');
    }
    final msg = ChatMessage(
      author: author.trim().isEmpty ? 'anon' : author.trim(),
      text: trimmed,
      at: DateTime.now().toUtc(),
      serverId: instanceId(session),
      kind: 'chat',
    );
    // global: true → Redis PubSub (throws if Redis is not configured).
    await session.messages.postMessage(channel, msg, global: true);
    return msg;
  }
}
