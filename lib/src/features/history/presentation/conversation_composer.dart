import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../di/di.dart' as di;
import '../../../l10n/app_localizations.dart';
import '../../../platform/network_manager.dart';
import '../../device_profile/data/device_profile_repository.dart';
import '../../send_receive/data/send_repository.dart';
import '../../send_receive/data/send_service.dart';
import 'conversation_detail_view_model.dart';
import 'message_input_sheet.dart';

class Composer extends StatelessWidget {
  const Composer({
    super.key,
    required this.deviceId,
    required this.vm,
    required this.isReachable,
    required this.showMessage,
  });

  final String deviceId;
  final ConversationDetailViewModel vm;
  final bool isReachable;
  final Future<void> Function(String) showMessage;

  Future<void> _sendFile(BuildContext context) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        withData: true,
        dialogTitle: AppLocalizations.of(context)?.filePickerTitle ?? 'Choose a file to send',
      );
      if (result == null) {
        return;
      }
      final Uint8List? bytes = result.files.single.bytes;
      if (bytes == null) {
        return;
      }
      final SendService service = di.getIt<SendService>();

      final String tempId = vm.addPendingSent(
        content: null,
        size: bytes.length,
        metadata: <String, String>{'filename': result.files.single.name},
      );

      try {
        String deviceIdForSend = deviceId;
        try {
          final DeviceProfileRepository repo = di.getIt<DeviceProfileRepository>();
          final List<DeviceProfile> profiles = await repo.loadAll();
          final Iterable<DeviceProfile> matching = profiles.where((p) => p.id == deviceId);
          if (matching.isNotEmpty) {
            final DeviceProfile profile = matching.first;
            if (profile.endpoint != null && profile.endpoint!.isNotEmpty) {
              deviceIdForSend = profile.endpoint!;
            }
          }
        } catch (_) {}

        final String? transferId = await service.sendMessage(bytes, {
          'senderId': di.getIt<NetworkManager>().localId,
          'receiverId': deviceIdForSend,
          'senderName': di.getIt<NetworkManager>().localName,
          'receiverName': '',
          'filename': result.files.single.name,
        });

        try {
          final SendRepository sendRepo = di.getIt<SendRepository>();
          final List<TransferRecord> records = await sendRepo.loadAll();
          TransferRecord? rec;
          for (final r in records) {
            if (r.id == transferId) {
              rec = r;
              break;
            }
          }
          if (rec != null) {
            vm.replacePendingWithPersisted(tempId, rec);
          } else {
            await vm.load();
          }
        } catch (_) {
          await vm.load();
        }
      } catch (err) {
        vm.markFailed(tempId);
        final String msg = AppLocalizations.of(context)?.failedToSendFile ?? 'Failed to send file';
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await showMessage(msg);
        });
      }
    } catch (err) {
      final String msg = AppLocalizations.of(context)?.failedToSendFile ?? 'Failed to send file';
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await showMessage(msg);
      });
    }
  }

  Future<void> _sendText(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: MessageInputSheet(deviceId: deviceId, vm: vm, showMessage: showMessage),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? loc = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            ElevatedButton.icon(
              onPressed: isReachable ? () => _sendFile(context) : null,
              icon: const Icon(Icons.attach_file),
              label: Text(loc?.sendFileButton ?? 'Send file'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isReachable ? () => _sendText(context) : null,
                icon: const Icon(Icons.message),
                label: Text(loc?.sendMessageButton ?? 'Send message'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
