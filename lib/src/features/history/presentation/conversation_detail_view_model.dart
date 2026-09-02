import 'package:flutter/foundation.dart';

import '../../../di/di.dart';
import '../../../platform/file_opener.dart';
import '../../../platform/network_manager.dart';
import '../../send_receive/data/receive_repository.dart';
import '../../send_receive/data/send_repository.dart';

/// Direction of a message in a conversation.
enum MessageDirection { sent, received }

/// Delivery status of a message entry.
enum MessageStatus { pending, sent, failed }

/// Single merged message entry combining sent or received transfer with its direction
/// and an optional delivery status used for optimistic UI.
class MessageEntry {
  MessageEntry({required this.record, required this.direction, this.status = MessageStatus.sent});

  TransferRecord record;
  MessageDirection direction;
  MessageStatus status;
}

/// ViewModel exposing a merged, chronological list of messages (sent & received)
/// for a given conversation/device id. The `messages` list is sorted oldest->newest.
class ConversationDetailViewModel with ChangeNotifier {
  ConversationDetailViewModel({
    required this.deviceId,
    required this.sendRepository,
    required this.receiveRepository,
    required this.fileOpener,
  }) {
    _repoListener = load;
    receiveRepository.addListener(_repoListener!);
  }

  final String deviceId;
  final SendRepository sendRepository;
  final ReceiveRepository receiveRepository;
  final FileOpener fileOpener;

  List<MessageEntry> messages = [];
  bool isLoading = false;

  VoidCallback? _repoListener;

  /// Attempts to open a local file referenced by [path]. Returns true on success.
  Future<bool> openFile(String path) async {
    try {
      return await fileOpener.open(path);
    } catch (_) {
      return false;
    }
  }

  /// Loads both sent and received transfers and merges them in chronological order.
  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    try {
      final List<TransferRecord> allSent = await sendRepository.loadAll();
      final List<TransferRecord> allReceived = await receiveRepository.loadAll();

      // Build merged list from persisted records (sent + received)
      final merged = <MessageEntry>[];

      String normalize(String? id) => id ?? '';
      // Collect persisted sent records for this device to use for matching pending entries
      final persistedSentForDevice = <TransferRecord>[];
      for (final t in allSent) {
        final String fromField = normalize(t.receiverId);
        final String metaDev = normalize(t.senderId);
        if (fromField == deviceId || metaDev == deviceId) {
          merged.add(MessageEntry(record: t, direction: MessageDirection.sent));
          persistedSentForDevice.add(t);
        }
      }
      for (final t in allReceived) {
        final String fromField = normalize(t.senderId);
        final String metaDev = normalize(t.receiverId);
        if (fromField == deviceId || metaDev == deviceId) {
          merged.add(MessageEntry(record: t, direction: MessageDirection.received));
        }
      }
      merged.sort((a, b) => a.record.timestamp.compareTo(b.record.timestamp));
      messages = merged;
    } catch (_) {
      messages = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Insert an optimistic pending sent message. Returns the temporary id used
  /// to identify the pending entry so it can be marked failed or replaced later.
  String addPendingSent({
    required String? content,
    required int size,
    Map<String, String>? metadata,
  }) {
    final tempId =
        'local-${DateTime.now().toUtc().microsecondsSinceEpoch}-${DateTime.now().millisecondsSinceEpoch}';
    final rec = TransferRecord(
      id: tempId,
      timestamp: DateTime.now().toUtc(),
      size: size,
      metadata: metadata ?? {},
      senderId: getIt<NetworkManager>().localId,
      receiverId: deviceId,
      content: content,
    );
    final entry = MessageEntry(
      record: rec,
      direction: MessageDirection.sent,
      status: MessageStatus.pending,
    );
    // Insert at end (newest). messages are oldest->newest; so append.
    messages.add(entry);
    notifyListeners();
    return tempId;
  }

  /// Mark a previously added pending message as failed. If no matching pending
  /// message exists this is a no-op.
  void markFailed(String tempId) {
    for (final MessageEntry e in messages) {
      if (e.record.id == tempId && e.status == MessageStatus.pending) {
        e.status = MessageStatus.failed;
        notifyListeners();
        return;
      }
    }
  }

  /// Replace a previously added pending message (identified by [tempId])
  /// with a persisted [record]. If the pending entry is not found, the
  /// persisted record is appended. After replacement the messages are
  /// re-sorted and listeners notified.
  void replacePendingWithPersisted(String tempId, TransferRecord record) {
    for (var i = 0; i < messages.length; i++) {
      final MessageEntry e = messages[i];
      if (e.record.id == tempId &&
          e.status == MessageStatus.pending &&
          e.direction == MessageDirection.sent) {
        // Replace the entry's record and mark as sent.
        messages[i] = MessageEntry(record: record, direction: MessageDirection.sent);
        messages.sort((a, b) => a.record.timestamp.compareTo(b.record.timestamp));
        notifyListeners();
        return;
      }
    }
    // Not found: append persisted record
    messages
      ..add(MessageEntry(record: record, direction: MessageDirection.sent))
      ..sort((a, b) => a.record.timestamp.compareTo(b.record.timestamp));
    notifyListeners();
  }

  /// Finalize a pending optimistic entry by assigning it a real [transferId]
  /// and marking it as sent. This helps avoid duplicates when the persisted
  /// record isn't immediately visible in the repository.
  void finalizePendingWithId(String tempId, String transferId) {
    for (var i = 0; i < messages.length; i++) {
      final MessageEntry e = messages[i];
      if (e.record.id == tempId &&
          e.status == MessageStatus.pending &&
          e.direction == MessageDirection.sent) {
        // Mutate the record id and status
        final updatedRecord = TransferRecord(
          id: transferId,
          timestamp: DateTime.now().toUtc(),
          size: e.record.size,
          metadata: e.record.metadata,
          senderId: e.record.senderId,
          receiverId: e.record.receiverId,
          content: e.record.content,
        );
        messages[i] = MessageEntry(record: updatedRecord, direction: MessageDirection.sent);
        messages.sort((a, b) => a.record.timestamp.compareTo(b.record.timestamp));
        notifyListeners();
        return;
      }
    }
  }

  /// Clean up any listeners attached to repositories.
  @override
  void dispose() {
    if (_repoListener != null) {
      try {
        receiveRepository.removeListener(_repoListener!);
      } catch (_) {}
    }
    super.dispose();
  }
}
