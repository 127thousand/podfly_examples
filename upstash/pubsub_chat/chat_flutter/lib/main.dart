import 'dart:async';

import 'package:chat_client/chat_client.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
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
    // Monolith / local: same origin OK. Split CDN: never use CDN origin for WS.
    final onCdn = Uri.base.host.contains('vercel.app') ||
        Uri.base.host.contains('netlify.app') ||
        Uri.base.host.contains('github.io') ||
        Uri.base.host.contains('pages.dev');
    if (isLocalOrPlaceholder && !onCdn) {
      return '${Uri.base.origin}/';
    }
  }
  return fromEnvOrAsset.endsWith('/') ? fromEnvOrAsset : '$fromEnvOrAsset/';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final serverUrl = await resolveServerUrl();
  client = Client(serverUrl)..connectivityMonitor = FlutterConnectivityMonitor();
  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upstash PubSub chat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const ChatPage(),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _author = TextEditingController(text: 'Browser A');
  final _text = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <ChatMessage>[];
  StreamSubscription<ChatMessage>? _sub;
  String? _error;
  bool _listening = false;
  String? _apiUrl;

  /// Machine serving this tab’s WebSocket (from kind=hello).
  String? _wsMachine;

  /// Last HTTP whoami / send machine (load-balanced independently of WS).
  String? _lastHttpMachine;

  int _crossMachineCount = 0;

  @override
  void initState() {
    super.initState();
    _apiUrl = client.host;
    _startListen();
  }

  Future<void> _startListen() async {
    await _sub?.cancel();
    setState(() {
      _listening = true;
      _error = null;
      _wsMachine = null;
      _messages.clear();
      _crossMachineCount = 0;
    });
    try {
      _sub = client.chat.listen().listen(
        (msg) {
          if (!mounted) return;
          final isHello = msg.kind == 'hello';
          setState(() {
            if (isHello && msg.serverId != null) {
              _wsMachine = msg.serverId;
            }
            if (!isHello &&
                msg.serverId != null &&
                _wsMachine != null &&
                msg.serverId != _wsMachine) {
              _crossMachineCount++;
            }
            _messages.add(msg);
            if (_messages.length > 200) _messages.removeAt(0);
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scroll.hasClients) {
              _scroll.jumpTo(_scroll.position.maxScrollExtent);
            }
          });
        },
        onError: (Object e) {
          if (!mounted) return;
          setState(() {
            _error = '$e';
            _listening = false;
          });
        },
        onDone: () {
          if (!mounted) return;
          setState(() => _listening = false);
        },
      );
    } catch (e) {
      setState(() {
        _error = '$e';
        _listening = false;
      });
    }
  }

  Future<void> _probeHttpMachine() async {
    try {
      final id = await client.chat.whoami();
      if (!mounted) return;
      setState(() {
        _lastHttpMachine = id;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    try {
      final sent = await client.chat.send(_author.text, text);
      _text.clear();
      if (!mounted) return;
      setState(() {
        _lastHttpMachine = sent.serverId;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  bool _isCrossMachine(ChatMessage m) {
    if (m.kind == 'hello') return false;
    if (m.serverId == null || _wsMachine == null) return false;
    return m.serverId != _wsMachine;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _author.dispose();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final proofReady = _crossMachineCount > 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upstash Redis · multi-machine PubSub'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            tooltip: 'Reconnect WebSocket (re-roll machine)',
            onPressed: _startListen,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            color: proofReady ? Colors.green.shade50 : Colors.teal.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    proofReady
                        ? '✓ Cross-machine delivery proven (Redis PubSub)'
                        : 'How to prove both Fly machines',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: proofReady ? Colors.green.shade900 : null,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    proofReady
                        ? 'At least one chat line was published on a different '
                            'machine than this tab’s WebSocket. That fan-out only '
                            'works with Redis `global: true`.'
                        : 'Each tab has a sticky WebSocket on one machine. Sends '
                            'are load-balanced over HTTP (any machine). When '
                            'send machine ≠ WS machine, the line is highlighted '
                            'as CROSS-MACHINE — that is Redis, not local memory.\n\n'
                            'Tips: open 2 browsers; Reconnect (↻) until WS machines '
                            'differ; spam Send until a green CROSS-MACHINE appears.',
                    style: const TextStyle(height: 1.35),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MachineChip(
                        label: 'This tab WS',
                        value: _wsMachine,
                        color: Colors.indigo,
                      ),
                      _MachineChip(
                        label: 'Last HTTP send/whoami',
                        value: _lastHttpMachine,
                        color: Colors.deepOrange,
                      ),
                      _MachineChip(
                        label: 'Cross-machine hits',
                        value: '$_crossMachineCount',
                        color: proofReady ? Colors.green : Colors.blueGrey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _startListen,
                        icon: const Icon(Icons.cable, size: 18),
                        label: const Text('Reconnect WS'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _probeHttpMachine,
                        icon: const Icon(Icons.dns, size: 18),
                        label: const Text('Probe HTTP machine'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'API: ${_apiUrl ?? "…"}\n'
                    'Stream: ${_listening ? "connected" : "not listening"}'
                    '${_wsMachine != null ? " → machine $_wsMachine" : ""}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                  ),
                ],
              ),
            ),
          ),
          if (_error != null)
            Container(
              width: double.infinity,
              color: Colors.red.shade100,
              padding: const EdgeInsets.all(10),
              child: Text(_error!, style: TextStyle(color: Colors.red.shade900)),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isHello = m.kind == 'hello';
                final cross = _isCrossMachine(m);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isHello
                      ? Colors.indigo.shade50
                      : cross
                          ? Colors.green.shade50
                          : null,
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      isHello
                          ? Icons.link
                          : cross
                              ? Icons.hub
                              : Icons.chat_bubble_outline,
                      color: isHello
                          ? Colors.indigo
                          : cross
                              ? Colors.green.shade800
                              : Colors.teal,
                    ),
                    title: Text(
                      m.author,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.text),
                        if (cross)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'CROSS-MACHINE · published on ${m.serverId}, '
                              'delivered to this WS on $_wsMachine via Redis',
                              style: TextStyle(
                                color: Colors.green.shade900,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          )
                        else if (!isHello &&
                            m.serverId != null &&
                            m.serverId == _wsMachine)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Same machine as this WS (${m.serverId}) — could be local; '
                              'keep sending or reconnect other tab for a mismatch',
                              style: TextStyle(
                                color: Colors.blueGrey.shade700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                    trailing: Text(
                      [
                        m.at.toLocal().toIso8601String().substring(11, 19),
                        if (m.serverId != null)
                          isHello
                              ? 'ws:${m.serverId}'
                              : 'send:${m.serverId}',
                      ].join('\n'),
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _author,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _text,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _send,
                    child: const Text('Send'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MachineChip extends StatelessWidget {
  const _MachineChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String? value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.9)),
          ),
          Text(
            value ?? '…',
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
