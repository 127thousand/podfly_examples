import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Persist notes in Postgres and read them back (bidirectional DB smoke).
class NoteEndpoint extends Endpoint {
  /// Insert a note and return the stored row (id assigned by DB).
  Future<Note> add(Session session, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('text must not be empty');
    }
    final row = Note(
      text: trimmed,
      createdAt: DateTime.now().toUtc(),
    );
    return Note.db.insertRow(session, row);
  }

  /// List notes newest-first (proves read path from Postgres).
  Future<List<Note>> list(Session session) async {
    return Note.db.find(
      session,
      orderBy: (t) => t.id,
      orderDescending: true,
      limit: 50,
    );
  }

  /// Count rows (cheap round-trip check).
  Future<int> count(Session session) async {
    return Note.db.count(session);
  }
}
