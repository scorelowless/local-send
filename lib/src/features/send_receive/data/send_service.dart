import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../platform/network_manager.dart';
import '../data/send_repository.dart';

/// Abstract service responsible for sending files/messages to a remote device.
abstract class SendService {
  /// Sends raw bytes with an optional metadata map.
  /// Returns a transfer id on success and null on failure.
  Future<String?> sendMessage(List<int> bytes, Map<String, String> metadata);
}

class SendServiceImpl implements SendService {
  SendServiceImpl({required SendRepository repository, required NetworkManager networkManager})
    : _repository = repository,
      _networkManager = networkManager;

  final SendRepository _repository;
  final NetworkManager _networkManager;

  @override
  Future<String?> sendMessage(List<int> bytes, Map<String, String> metadata) async {
    if (metadata['receiverId'] == null) {
      return null;
    }
    final String receiverId = metadata['receiverId']!;

    var transferId = '';
    try {
      transferId = await _networkManager.sendBytes(Uint8List.fromList(bytes), metadata);
    } catch (_) {
      if (kDebugMode) {
        print('[SendServiceImpl] Error sending bytes to deviceId=$receiverId');
      }
      return null;
    }

    if (metadata['deviceAdded'] == 'true') {
      // If this was a device addition message, no need to persist a record
      return transferId;
    }

    // Persist the transfer record
    try {
      String? content;
      final persistMetadata = Map<String, String>.from(metadata);

      if (metadata['isText'] == 'true') {
        content = utf8.decode(bytes);
      } else {
        content = null;
        final String? filename = persistMetadata['filename'];
        if (filename == null) {
          return null;
        }
        try {
          // Save sent files to temporary directory (not permanent).
          final Directory dir = await getTemporaryDirectory();
          final String safeName = filename.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
          final filePath =
              '${dir.path}${Platform.pathSeparator}${DateTime.now().millisecondsSinceEpoch}_$safeName';
          final file = File(filePath);
          await file.writeAsBytes(bytes, flush: true);
          persistMetadata['localPath'] = file.path;
        } catch (_) {
          if (kDebugMode) {
            print('[SendServiceImpl] Failed to persist sent file to temporary storage');
          }
        }
      }

      final rec = TransferRecord(
        id: transferId,
        timestamp: DateTime.now().toUtc(),
        size: bytes.length,
        metadata: persistMetadata,
        senderId: metadata['senderId']!,
        receiverId: receiverId,
        content: content,
      );
      await _repository.add(rec);
    } catch (_) {
      if (kDebugMode) {
        print('[SendServiceImpl] Failed to persist sent transfer record');
      }
    }

    return transferId;
  }
}
