import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../storage/storage.dart';
import 'send_repository.dart';

/// Persistence contract for received transfers.
///
/// Uses [TransferRecord] for record shape to keep serialization consistent
/// across send/receive persistence layers.
/// Implements [Listenable] so UI/ViewModels can listen for updates.
abstract class ReceiveRepository implements Listenable {
  /// Load all received transfer records in most-recent-first order.
  Future<List<TransferRecord>> loadAll();

  /// Persist a received transfer record (newest first). Implementations may
  /// deduplicate by id.
  Future<void> add(TransferRecord record);

  /// Remove all persisted received records.
  Future<void> clear();
}

/// JSON-backed implementation of [ReceiveRepository] using [Storage].
/// Extends [ChangeNotifier] so UI/ViewModels can listen for updates.
class ReceiveRepositoryImpl extends ChangeNotifier implements ReceiveRepository {
  ReceiveRepositoryImpl({required this.storage, int? maxEntries})
    : maxEntries = maxEntries ?? _defaultMaxEntries;
  static const String _kKey = 'receive_transfers';
  static const String _kBackupKey = 'receive_transfers_corrupt_backup';
  static const int _defaultMaxEntries = 2000;

  final Storage storage;
  final int maxEntries;

  @override
  Future<void> add(TransferRecord record) async {
    final List<TransferRecord> list = await loadAll();
    final updated = List<TransferRecord>.from(list.where((e) => e.id != record.id))
      ..insert(0, record);
    if (updated.length > maxEntries) {
      updated.removeRange(maxEntries, updated.length);
    }
    final String encoded = jsonEncode(updated.map((e) => e.toJson()).toList());
    await storage.writeString(_kKey, encoded);
    try {
      notifyListeners();
    } catch (_) {
      if (kDebugMode) {
        print('ReceiveRepositoryImpl: notifyListeners failed');
      }
    }
  }

  @override
  Future<void> clear() async {
    await storage.remove(_kKey);
    try {
      notifyListeners();
    } catch (_) {
      if (kDebugMode) {
        print('ReceiveRepositoryImpl: notifyListeners failed');
      }
    }
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
    } catch (_) {
      try {
        await storage.writeString(_kBackupKey, raw);
      } catch (_) {
        if (kDebugMode) {
          print('ReceiveRepositoryImpl: failed to write corrupt backup');
        }
      }
      try {
        await storage.remove(_kKey);
      } catch (_) {
        if (kDebugMode) {
          print('ReceiveRepositoryImpl: failed to remove corrupt key');
        }
      }
      return <TransferRecord>[];
    }
  }
}
