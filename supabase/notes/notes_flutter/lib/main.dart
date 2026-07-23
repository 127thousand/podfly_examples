import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:notes_client/notes_client.dart';
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
  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supabase notes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const NotesPage(),
    );
  }
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  final _notes = <Note>[];
  String? _error;
  bool _loading = true;
  bool _saving = false;
  int? _count;
  late final String _apiUrl;

  @override
  void initState() {
    super.initState();
    _apiUrl = client.host;
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await client.note.list();
      final count = await client.note.count();
      if (!mounted) return;
      setState(() {
        _notes
          ..clear()
          ..addAll(list);
        _count = count;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _add() async {
    final text = _text.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final note = await client.note.add(text);
      _text.clear();
      if (!mounted) return;
      setState(() {
        _notes.insert(0, note);
        _count = (_count ?? 0) + 1;
        _saving = false;
      });
      if (_scroll.hasClients) {
        _scroll.jumpTo(0);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _saving = false;
      });
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Postgres · notes'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            tooltip: 'Refresh from database',
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            color: Colors.deepPurple.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Write → Supabase · Read ← Supabase',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Add a note (INSERT on Supabase Postgres). '
                    'Refresh or reload to list (SELECT). '
                    'Both directions go through the Fly API.',
                    style: TextStyle(height: 1.35),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'API: $_apiUrl\n'
                    'Rows in DB: ${_count ?? "…"}${_loading ? " · loading…" : ""}',
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
            child: _loading && _notes.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _notes.isEmpty
                    ? Center(
                        child: Text(
                          'No notes yet — add one below',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(12),
                        itemCount: _notes.length,
                        itemBuilder: (context, i) {
                          final n = _notes[i];
                          final at = n.createdAt.toLocal();
                          final stamp =
                              '${at.year}-${at.month.toString().padLeft(2, '0')}-'
                              '${at.day.toString().padLeft(2, '0')} '
                              '${at.hour.toString().padLeft(2, '0')}:'
                              '${at.minute.toString().padLeft(2, '0')}:'
                              '${at.second.toString().padLeft(2, '0')}';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text('${n.id}'),
                              ),
                              title: Text(n.text),
                              subtitle: Text(
                                stamp,
                                style: const TextStyle(fontFamily: 'monospace'),
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
                  Expanded(
                    child: TextField(
                      controller: _text,
                      decoration: const InputDecoration(
                        labelText: 'New note',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _add(),
                      enabled: !_saving,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _saving ? null : _add,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: const Text('Add'),
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
