/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;

/// A chat line broadcast via session.messages (Redis PubSub when global: true).
abstract class ChatMessage implements _i1.SerializableModel {
  ChatMessage._({
    required this.author,
    required this.text,
    required this.at,
    this.serverId,
    this.kind,
  });

  factory ChatMessage({
    required String author,
    required String text,
    required DateTime at,
    String? serverId,
    String? kind,
  }) = _ChatMessageImpl;

  factory ChatMessage.fromJson(Map<String, dynamic> jsonSerialization) {
    return ChatMessage(
      author: jsonSerialization['author'] as String,
      text: jsonSerialization['text'] as String,
      at: _i1.DateTimeJsonExtension.fromJson(jsonSerialization['at']),
      serverId: jsonSerialization['serverId'] as String?,
      kind: jsonSerialization['kind'] as String?,
    );
  }

  /// Display name of the sender.
  String author;

  /// Message body.
  String text;

  /// When the server accepted the message (UTC).
  DateTime at;

  /// Machine that produced this event (Fly machine id suffix).
  String? serverId;

  /// "hello" = WebSocket host machine; "chat" (or null) = published chat line.
  String? kind;

  /// Returns a shallow copy of this [ChatMessage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ChatMessage copyWith({
    String? author,
    String? text,
    DateTime? at,
    String? serverId,
    String? kind,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ChatMessage',
      'author': author,
      'text': text,
      'at': at.toJson(),
      if (serverId != null) 'serverId': serverId,
      if (kind != null) 'kind': kind,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ChatMessageImpl extends ChatMessage {
  _ChatMessageImpl({
    required String author,
    required String text,
    required DateTime at,
    String? serverId,
    String? kind,
  }) : super._(
         author: author,
         text: text,
         at: at,
         serverId: serverId,
         kind: kind,
       );

  /// Returns a shallow copy of this [ChatMessage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ChatMessage copyWith({
    String? author,
    String? text,
    DateTime? at,
    Object? serverId = _Undefined,
    Object? kind = _Undefined,
  }) {
    return ChatMessage(
      author: author ?? this.author,
      text: text ?? this.text,
      at: at ?? this.at,
      serverId: serverId is String? ? serverId : this.serverId,
      kind: kind is String? ? kind : this.kind,
    );
  }
}
