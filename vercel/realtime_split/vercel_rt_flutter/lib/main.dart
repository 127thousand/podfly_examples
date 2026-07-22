import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:vercel_rt_client/vercel_rt_client.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

late final Client client;

/// Resolve API base URL for this app.
///
/// Split deploy: Flutter is on Vercel; Serverpod (HTTP + WebSockets) is on Fly.
/// Prefer baked-in SERVER_URL / config; only fall back to same-origin for local
/// monolith-style dev (not Vercel production).
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
    // Same-origin only when running local/dev without a real API URL.
    // On Vercel, Uri.base is the CDN — streams must hit Fly instead.
    final onVercel = Uri.base.host.contains('vercel.app');
    if (isLocalOrPlaceholder && !onVercel) {
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
    // Same light Material 3 pattern as the other host demos (Hetzner, Azure, …).
    return MaterialApp(
      title: 'Serverpod realtime on Fly + Vercel',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
  final _nameController = TextEditingController(text: 'Fly');
  String? _hello;
  String? _helloError;
  final _ticks = <String>[];
  StreamSubscription<String>? _tickSub;
  bool _streaming = false;
  String? _streamError;

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
        title: const Text('Serverpod · Fly + Vercel'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Split deploy: Flutter UI is on Vercel; Serverpod API and '
            'WebSocket streams are on Fly (SERVER_URL). Start the clock '
            'stream to verify realtime over WSS to Fly.',
            style: Theme.of(context).textTheme.bodyMedium,
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
            _streaming
                ? 'Streaming ticks from server…'
                : 'Not streaming',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          ..._ticks.map(
            (t) => Card(
              child: ListTile(
                dense: true,
                leading: Icon(
                  Icons.bolt,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(t, style: const TextStyle(fontFamily: 'monospace')),
              ),
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
    // Light pastel fill + explicit dark text (same as Hetzner/Azure demos).
    // Do not force white text here — that is what made the cream banner unreadable.
    final bg = ok ? Colors.green.shade100 : Colors.orange.shade100;
    final fg = ok ? Colors.green.shade900 : Colors.orange.shade900;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(color: fg)),
    );
  }
}
