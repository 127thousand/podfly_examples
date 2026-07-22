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
import 'dart:async' as _i2;
import 'package:chat_client/src/protocol/chat/chat_message.dart' as _i3;
import 'package:chat_client/src/protocol/greetings/greeting.dart' as _i4;
import 'package:http/http.dart' as _i5;
import 'protocol.dart' as _i6;

/// Cross-client chat via Serverpod messages + Redis (`global: true`).
///
/// Proof of multi-machine PubSub:
/// 1. [listen] first emits a `kind: hello` event with the **WebSocket host** machine id.
/// 2. [send] tags each line with the **HTTP handler** machine id (`global: true` → Redis).
/// 3. UI highlights when hello machine ≠ send machine (message crossed instances via Redis).
/// {@category Endpoint}
class EndpointChat extends _i1.EndpointRef {
  EndpointChat(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'chat';

  /// Subscribe to the global chat channel (WebSocket stream).
  ///
  /// First event is local (this process only): which machine owns the WS.
  /// Later chat events may originate on other machines and arrive via Redis.
  _i2.Stream<_i3.ChatMessage> listen() =>
      caller.callStreamingServerEndpoint<
        _i2.Stream<_i3.ChatMessage>,
        _i3.ChatMessage
      >(
        'chat',
        'listen',
        {},
        {},
      );

  /// Which machine would handle an RPC right now (HTTP load-balanced separately
  /// from the WebSocket). Useful to compare with the listen hello id.
  _i2.Future<String> whoami() => caller.callServerEndpoint<String>(
    'chat',
    'whoami',
    {},
  );

  /// Publish a line to all listeners (requires Redis when multi-instance).
  _i2.Future<_i3.ChatMessage> send(
    String author,
    String text,
  ) => caller.callServerEndpoint<_i3.ChatMessage>(
    'chat',
    'send',
    {
      'author': author,
      'text': text,
    },
  );
}

/// This is an example endpoint that returns a greeting message through
/// its [hello] method.
/// {@category Endpoint}
class EndpointGreeting extends _i1.EndpointRef {
  EndpointGreeting(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  /// Returns a personalized greeting message: "Hello {name}".
  _i2.Future<_i4.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i4.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

class Client extends _i1.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    @Deprecated(
      'Use authKeyProvider instead. This will be removed in future releases.',
    )
    super.authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i1.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_i1.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
    _i5.Client? httpClientOverride,
  }) : super(
         host,
         _i6.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
         httpClientOverride: httpClientOverride,
       ) {
    chat = EndpointChat(this);
    greeting = EndpointGreeting(this);
  }

  late final EndpointChat chat;

  late final EndpointGreeting greeting;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
    'chat': chat,
    'greeting': greeting,
  };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {};
}
