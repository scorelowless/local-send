import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../device_profile/data/device_profile_repository.dart';
import '../../history/data/history_repository.dart';
import 'receive_repository.dart';
import 'send_repository.dart';

/// Interface for receive listener. Implementations should subscribe to an
/// incoming bytes stream and persist received transfers automatically.
abstract class ReceiveListener {}

/// Simple listener that subscribes to a PlatformBridge/receive stream and
/// persists incoming byte payloads into [ReceiveRepository].
class ReceiveListenerImpl implements ReceiveListener {
  ReceiveListenerImpl({
    required Stream<Uint8List> stream,
    required this.repository,
    this.historyRepository,
    this.deviceProfileRepository,
  }) {
    _sub = stream.listen(_onData, onError: (_) {}, cancelOnError: false);
  }

  final ReceiveRepository repository;
  final HistoryRepository? historyRepository;
  final DeviceProfileRepository? deviceProfileRepository;
  late final StreamSubscription<Uint8List> _sub;

  Future<void> _onData(Uint8List data) async {
    try {
      final _Frame? frame = _parseFrame(data);
      if (frame == null) {
        if (kDebugMode) {
          print('ReceiveListener: received invalid frame');
        }
        return;
      }
      final persistMetadata = Map<String, String>.from(frame.metadata);

      if (persistMetadata['isText'] == 'true') {
        await _handleText(frame.senderId, persistMetadata, frame.payload);
      } else if (persistMetadata['filename'] != null) {
        await _handleFile(frame.senderId, persistMetadata, frame.payload);
      }
    } catch (_) {
      if (kDebugMode) {
        print('ReceiveListener: error processing incoming data');
      }
    }
  }

  // Parse frame returns deviceId, metadata map (values as String) and payload bytes.
  _Frame? _parseFrame(Uint8List data) {
    if (data.length >= 4) {
      try {
        final int headerLen = ByteData.sublistView(data, 0, 4).getUint32(0);
        if (headerLen >= 0 && data.length >= 4 + headerLen) {
          final Uint8List headerBytes = data.sublist(4, 4 + headerLen);
          final String headerJson = utf8.decode(headerBytes, allowMalformed: true);
          final Map<String, String> metadata =
              (jsonDecode(headerJson) as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(k, v.toString()),
              ) ??
              {};
          if (metadata['senderId'] == null || metadata['receiverId'] == null) {
            return null;
          }
          final String senderId = metadata['senderId']!;
          final Uint8List payload = data.sublist(4 + headerLen);
          return _Frame(senderId: senderId, metadata: metadata, payload: payload);
        }
      } catch (err) {
        if (kDebugMode) {
          print(err);
          print('ReceiveListener: error parsing frame header');
        }
      }
    }
    return null;
  }

  Future<void> _handleText(String senderId, Map<String, String> metadata, Uint8List payload) async {
    String content;
    try {
      content = utf8.decode(payload, allowMalformed: true);
    } catch (_) {
      content = String.fromCharCodes(payload);
    }
    final id = 'recv-${DateTime.now().toUtc().microsecondsSinceEpoch}';
    final record = TransferRecord(
      id: id,
      timestamp: DateTime.now().toUtc(),
      size: payload.length,
      metadata: Map<String, String>.from(metadata),
      senderId: metadata['senderId']!,
      receiverId: metadata['receiverId']!,
      content: content,
    );
    await repository.add(record);
    await _updateHistoryPreview(record);
    await _maybeHandleDeviceAdded(metadata, senderId);
  }

  Future<Directory> _choosePersistentDir() async {
    try {
      final Directory? downloads = await getDownloadsDirectory();
      if (downloads != null) {
        return downloads;
      }
    } catch (_) {}
    try {
      final Directory? external = await getExternalStorageDirectory();
      if (external != null) {
        return external;
      }
    } catch (_) {}
    return getApplicationDocumentsDirectory();
  }

  Future<void> _handleFile(String senderId, Map<String, String> metadata, Uint8List payload) async {
    final persistMetadata = Map<String, String>.from(metadata);
    final String? filename = persistMetadata['filename'];
    if (filename != null) {
      try {
        final Directory baseDir = await _choosePersistentDir();

        // On Android, when choosing external storage, ensure we have permission
        if (Platform.isAndroid) {
          try {
            // Request storage permission if needed
            final PermissionStatus status = await Permission.storage.request();
            if (!status.isGranted) {
              throw Exception('Storage permission not granted');
            }
          } catch (_) {}
        }

        final targetDir = Directory(
          '${baseDir.path}${Platform.pathSeparator}LocalSend${Platform.pathSeparator}received',
        );
        await targetDir.create(recursive: true);
        final String safeName = filename.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
        final filePath =
            '${targetDir.path}${Platform.pathSeparator}${DateTime.now().millisecondsSinceEpoch}_$safeName';
        final file = File(filePath);
        await file.writeAsBytes(payload, flush: true);
        persistMetadata['localPath'] = file.path;
      } catch (_) {
        if (kDebugMode) {
          print(
            '[ReceiveListener] Failed to persist received file to persistent storage, falling back to temp',
          );
        }
        try {
          final Directory dir = await getTemporaryDirectory();
          final file = File(
            '${dir.path}${Platform.pathSeparator}${DateTime.now().millisecondsSinceEpoch}_$filename',
          );
          await file.writeAsBytes(payload, flush: true);
          persistMetadata['localPath'] = file.path;
        } catch (_) {
          if (kDebugMode) {
            print('[ReceiveListener] Failed to persist received file to temp storage');
          }
        }
      }
    }
    final id = 'recv-${DateTime.now().toUtc().microsecondsSinceEpoch}';
    final record = TransferRecord(
      id: id,
      timestamp: DateTime.now().toUtc(),
      size: payload.length,
      metadata: persistMetadata,
      senderId: metadata['senderId']!,
      receiverId: metadata['receiverId']!,
      content: null,
    );
    await repository.add(record);
    await _updateHistoryPreview(record);
    await _maybeHandleDeviceAdded(persistMetadata, senderId);
  }

  Future<void> _updateHistoryPreview(TransferRecord record) async {
    try {
      String preview;
      if (record.content != null && record.content!.isNotEmpty) {
        preview = record.content!.length > 200
            ? '${record.content!.substring(0, 200)}…'
            : record.content!;
      } else if (record.metadata['filename'] != null) {
        preview = record.metadata['filename']!;
      } else {
        preview = '${record.size} bytes';
      }
      final String convId = record.senderId;
      final String title = record.metadata['senderName'] ?? convId;
      final conv = Conversation(
        id: convId,
        title: title,
        lastMessage: preview,
        timestamp: record.timestamp,
      );
      await historyRepository?.add(conv);
    } catch (_) {
      if (kDebugMode) {
        print('ReceiveListener: error updating history preview');
      }
    }
  }

  Future<void> _maybeHandleDeviceAdded(Map<String, String> metadata, String senderId) async {
    try {
      if (metadata['deviceAdded'] == 'true') {
        final String displayName = metadata['displayName'] ?? 'unknown';
        try {
          var endpointToSave = senderId;
          try {
            final int at = senderId.indexOf('@');
            if (at >= 0) {
              final String after = senderId.substring(at + 1);
              final int colon = after.lastIndexOf(':');
              final String hostPart = colon >= 0 ? after.substring(0, colon) : after;
              final String portPart = colon >= 0 ? after.substring(colon + 1) : '';
              if (InternetAddress.tryParse(hostPart) == null) {
                try {
                  final List<InternetAddress> resolved = await InternetAddress.lookup(hostPart);
                  if (resolved.isNotEmpty) {
                    final InternetAddress v4 = resolved.firstWhere(
                      (a) => a.type == InternetAddressType.IPv4,
                      orElse: () => resolved.first,
                    );
                    endpointToSave =
                        '$senderId@${v4.address}${portPart.isNotEmpty ? ':$portPart' : ''}';
                  }
                } catch (_) {
                  if (kDebugMode) {
                    print('ReceiveListener: failed to resolve hostname $hostPart');
                  }
                }
              }
            }
          } catch (_) {
            if (kDebugMode) {
              print('ReceiveListener: error processing endpoint for device profile');
            }
          }
          final profile = DeviceProfile(
            id: senderId,
            displayName: displayName,
            type: 'other',
            sentColorHex: '#2196F3',
            receivedColorHex: '#EEEEEE',
            endpoint: endpointToSave,
          );
          await deviceProfileRepository?.save(profile);
        } catch (_) {
          if (kDebugMode) {
            print('ReceiveListener: error saving device profile');
          }
        }
        try {
          final conversation = Conversation(
            id: senderId,
            title: displayName,
            lastMessage: '',
            timestamp: DateTime.now().toUtc(),
          );
          await historyRepository?.add(conversation);
        } catch (_) {
          if (kDebugMode) {
            print('ReceiveListener: error adding conversation for new device');
          }
        }
      }
    } catch (_) {
      if (kDebugMode) {
        print('ReceiveListener: error handling device added');
      }
    }
  }

  /// Cancel the internal stream subscription and release resources.
  Future<void> dispose() async {
    try {
      await _sub.cancel();
    } catch (_) {
      if (kDebugMode) {
        print('ReceiveListener: error disposing subscription');
      }
    }
  }
}

// Small private struct for parsed frame
class _Frame {
  _Frame({required this.senderId, required this.metadata, required this.payload});
  final String senderId;
  final Map<String, String> metadata;
  final Uint8List payload;
}
