import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../storage/storage.dart';

/// Persistence contract for sent transfers.
abstract class SendRepository {
  /// Load all persisted transfer records in most-recent-first order.
  Future<List<TransferRecord>> loadAll();

  /// Persist a transfer record (newest first). Implementations may deduplicate by id.
  Future<void> add(TransferRecord record);

  /// Remove all persisted records.
  Future<void> clear();
}

/// Record describing a sent transfer.
class TransferRecord {
  const TransferRecord({
    required this.id,
    required this.timestamp,
    required this.size,
    required this.metadata,
    required this.senderId,
    required this.receiverId,
    required this.content,
  });

  factory TransferRecord.fromJson(Map<String, dynamic> json) => TransferRecord(
    id: json['id'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    size: json['size'] as int,
    metadata:
        (json['metadata'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v.toString())) ?? {},
    receiverId: json['receiverId'] as String,
    senderId: json['senderId'] as String,
    content: json['content'] as String?,
  );

  final String id;
  final DateTime timestamp;
  final int size;
  final Map<String, String> metadata;
  final String receiverId;
  final String senderId;
  final String? content;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'size': size,
    'metadata': metadata,
    'senderId': senderId,
    'receiverId': receiverId,
    'content': content,
  };
}

/// JSON-backed implementation of [SendRepository] using the provided [Storage].
class SendRepositoryImpl implements SendRepository {
  SendRepositoryImpl({required this.storage});
  static const String _kKey = 'send_transfers';
  static const String _kBackupKey = 'send_transfers_corrupt_backup';

  final Storage storage;

  @override
  Future<void> add(TransferRecord record) async {
    final List<TransferRecord> list = await loadAll();
    list.insert(0, record);
    final String encoded = jsonEncode(list.map((e) => e.toJson()).toList());
    await storage.writeString(_kKey, encoded);
  }

  @override
  Future<void> clear() async {
    await storage.remove(_kKey);
  }

  @override
  Future<List<TransferRecord>> loadAll() async {
    final String? raw = await storage.readString(_kKey);
    if (raw == null || raw.isEmpty) {
      return <TransferRecord>[];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => TransferRecord.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (err) {
      if (kDebugMode) {
        print(err);
      }
      try {
        await storage.writeString(_kBackupKey, raw);
      } catch (_) {}
      try {
        await storage.remove(_kKey);
      } catch (_) {}
      return <TransferRecord>[];
    }
  }
}
