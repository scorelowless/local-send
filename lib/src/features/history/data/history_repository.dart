import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../storage/storage.dart';

/// Simple model representing a conversation entry.
class Conversation {
  /// Creates a conversation model.
  const Conversation({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.timestamp,
    this.favorite = false,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: json['id'] as String,
    title: json['title'] as String,
    lastMessage: json['lastMessage'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    favorite: (json['favorite'] as String).toLowerCase() == 'true',
  );

  final String id;
  final String title;
  final String lastMessage;
  final DateTime timestamp;
  final bool favorite;

  Map<String, String> toJson() => {
    'id': id,
    'title': title,
    'lastMessage': lastMessage,
    'timestamp': timestamp.toIso8601String(),
    'favorite': favorite.toString(),
  };
}

/// Repository to persist/load conversation history.
abstract class HistoryRepository {
  Future<List<Conversation>> loadAll();

  Future<void> add(Conversation conversation);

  Future<void> clear();

  /// Update favorite flag for a conversation by id.
  Future<void> updateFavorite(String id, bool favorite);

  /// Update the title for a conversation by id.
  Future<void> updateTitle(String id, String title);
}

/// A small implementation using [Storage] to persist JSON list under key 'history'.
class HistoryRepositoryImpl implements HistoryRepository {
  /// Creates a new [HistoryRepositoryImpl].
  HistoryRepositoryImpl({required this.storage});
  static const _kHistoryKey = 'history';
  static const _kBackupKey = 'history_corrupt_backup';

  final Storage storage;

  @override
  Future<void> add(Conversation conversation) async {
    final List<Conversation> list = await loadAll();
    // Remove any existing with the same id (deduplicate)
    final updated = List<Conversation>.from(list.where((e) => e.id != conversation.id))
      // Insert newest at the front
      ..insert(0, conversation);
    final String encoded = jsonEncode(updated.map((e) => e.toJson()).toList());
    await storage.writeString(_kHistoryKey, encoded);
  }

  @override
  Future<void> clear() async {
    await storage.remove(_kHistoryKey);
  }

  @override
  Future<List<Conversation>> loadAll() async {
    final String? raw = await storage.readString(_kHistoryKey);
    if (raw == null || raw.isEmpty) {
      return <Conversation>[];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final List<Conversation> result = decoded
          .map((e) => Conversation.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return result;
    } catch (err) {
      if (kDebugMode) {
        print(err);
      }
      // Back up corrupt raw payload for diagnostics and avoid repeatedly failing
      try {
        await storage.writeString(_kBackupKey, raw);
      } catch (_) {
        // ignore backup failure
      }
      // Clear the corrupt key so future loads start fresh
      try {
        await storage.remove(_kHistoryKey);
      } catch (_) {
        // ignore
      }
      return <Conversation>[];
    }
  }

  @override
  Future<void> updateFavorite(String id, bool favorite) async {
    final List<Conversation> current = await loadAll();
    final List<Conversation> updated = current.map((c) {
      if (c.id == id) {
        return Conversation(
          id: c.id,
          title: c.title,
          lastMessage: c.lastMessage,
          timestamp: c.timestamp,
          favorite: favorite,
        );
      }
      return c;
    }).toList();
    await storage.writeString(_kHistoryKey, jsonEncode(updated.map((e) => e.toJson()).toList()));
  }

  @override
  Future<void> updateTitle(String id, String title) async {
    final List<Conversation> current = await loadAll();
    final List<Conversation> updated = current.map((c) {
      if (c.id == id) {
        return Conversation(
          id: c.id,
          title: title,
          lastMessage: c.lastMessage,
          timestamp: c.timestamp,
          favorite: c.favorite,
        );
      }
      return c;
    }).toList();
    await storage.writeString(_kHistoryKey, jsonEncode(updated.map((e) => e.toJson()).toList()));
  }
}
