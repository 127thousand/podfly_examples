import 'package:serverpod/serverpod.dart';

import 'src/generated/protocol.dart';
import 'src/generated/endpoints.dart';

/// The starting point of the Serverpod server.
void run(List<String> args) async {
  final pod = Serverpod(args, Protocol(), Endpoints());

  // Flutter web is served by nginx in the App Runner monolith image.
  // API + WebSockets listen on the port configured in production.yaml (8081).

  await pod.start();
}
