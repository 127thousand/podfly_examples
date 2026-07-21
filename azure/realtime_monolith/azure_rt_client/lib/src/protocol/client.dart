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
import 'package:azure_rt_client/src/protocol/greetings/greeting.dart' as _i3;
import 'package:http/http.dart' as _i4;
import 'protocol.dart' as _i5;

/// This is an example endpoint that returns a greeting message through
/// its [hello] method.
/// {@category Endpoint}
class EndpointGreeting extends _i1.EndpointRef {
  EndpointGreeting(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  /// Returns a personalized greeting message: "Hello {name}".
  _i2.Future<_i3.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i3.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

/// Realtime demo: server → client WebSocket stream of clock ticks.
///
/// No Redis needed on a single Azure task (in-process stream).
/// {@category Endpoint}
class EndpointTick extends _i1.EndpointRef {
  EndpointTick(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'tick';

  /// Yields a tick every [intervalMs] milliseconds until the client cancels.
  _i2.Stream<String> clock({required int intervalMs}) =>
      caller.callStreamingServerEndpoint<_i2.Stream<String>, String>(
        'tick',
        'clock',
        {'intervalMs': intervalMs},
        {},
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
    _i4.Client? httpClientOverride,
  }) : super(
         host,
         _i5.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
         httpClientOverride: httpClientOverride,
       ) {
    greeting = EndpointGreeting(this);
    tick = EndpointTick(this);
  }

  late final EndpointGreeting greeting;

  late final EndpointTick tick;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
    'greeting': greeting,
    'tick': tick,
  };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {};
}
