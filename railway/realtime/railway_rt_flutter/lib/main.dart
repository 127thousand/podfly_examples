import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:railway_rt_client/railway_rt_client.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

late final Client client;

Future<String> resolveServerUrl() async {
  final fromEnvOrAsset = await getServerUrl();
  if (kIsWeb) {
    final uri = Uri.tryParse(fromEnvOrAsset);
    final host = uri?.host ?? '';
    final isLocalOrPlaceholder = host.isEmpty ||
        host == 'localhost' ||
        host == '127.0.0.1' ||
        host.contains('placeholder') ||
        fromEnvOrAsset.contains('placeholder');
    // Railway native web: API is a different service — never use web origin.
    final onRailwayWeb = Uri.base.host.contains('up.railway.app') ||
        Uri.base.host.contains('railway.app');
    if (isLocalOrPlaceholder && !onRailwayWeb) {
      return '${Uri.base.origin}/';
    }
  }
  return fromEnvOrAsset.endsWith('/') ? fromEnvOrAsset : '$fromEnvOrAsset/';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final serverUrl = await resolveServerUrl();
  client = Client(serverUrl)..connectivityMonitor = FlutterConnectivityMonitor();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Serverpod realtime on Railway',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _nameController = TextEditingController(text: 'Railway');
  String? _hello;
  String? _helloError;
  final _ticks = <String>[];
  StreamSubscription<String>? _tickSub;
  bool _streaming = false;
  String? _streamError;
  late final String _apiUrl;

  @override
  void initState() {
    super.initState();
    _apiUrl = client.host;
  }

  Future<void> _callHello() async {
    try {
      final result = await client.greeting.hello(_nameController.text);
      setState(() {
        _helloError = null;
        _hello = result.message;
      });
    } catch (e) {
      setState(() {
        _hello = null;
        _helloError = '$e';
      });
    }
  }

  Future<void> _toggleStream() async {
    if (_streaming) {
      await _tickSub?.cancel();
      _tickSub = null;
      setState(() {
        _streaming = false;
        _streamError = null;
      });
      return;
    }

    setState(() {
      _streaming = true;
      _streamError = null;
      _ticks.clear();
    });

    try {
      final stream = client.tick.clock(intervalMs: 1000);
      _tickSub = stream.listen(
        (tick) {
          if (!mounted) return;
          setState(() {
            _ticks.insert(0, tick);
            if (_ticks.length > 20) _ticks.removeLast();
          });
        },
        onError: (Object e) {
          if (!mounted) return;
          setState(() {
            _streamError = '$e';
            _streaming = false;
          });
        },
        onDone: () {
          if (!mounted) return;
          setState(() => _streaming = false);
        },
      );
    } catch (e) {
      setState(() {
        _streamError = '$e';
        _streaming = false;
      });
    }
  }

  @override
  void dispose() {
    _tickSub?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Serverpod · Railway realtime'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Native Railway deploy: API service + static web service (nginx). '
            'RPC and WebSocket streams go to the API host (SERVER_URL), not the web origin.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'API: $_apiUrl',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
          ),
          const SizedBox(height: 24),
          Text('RPC (HTTP)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Name',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _callHello,
            child: const Text('greeting.hello'),
          ),
          const SizedBox(height: 8),
          _Banner(
            ok: _helloError == null && _hello != null,
            text: _helloError ?? _hello ?? 'No RPC response yet',
          ),
          const SizedBox(height: 32),
          Text(
            'Realtime (WebSocket stream)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: _toggleStream,
            child: Text(_streaming ? 'Stop clock stream' : 'Start clock stream'),
          ),
          if (_streamError != null) ...[
            const SizedBox(height: 8),
            _Banner(ok: false, text: _streamError!),
          ],
          const SizedBox(height: 12),
          Text(
            _streaming ? 'Streaming ticks from server…' : 'Not streaming',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          ..._ticks.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(t, style: const TextStyle(fontFamily: 'monospace')),
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.ok, required this.text});

  final bool ok;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: ok ? Colors.green.shade100 : Colors.red.shade100,
      child: Text(text),
    );
  }
}
