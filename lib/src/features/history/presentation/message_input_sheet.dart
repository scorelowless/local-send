import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../di/di.dart' as di;
import '../../../l10n/app_localizations.dart';
import '../../../platform/network_manager.dart';
import '../../device_profile/data/device_profile_repository.dart';
import '../../send_receive/data/send_repository.dart';
import '../../send_receive/data/send_service.dart';
import 'conversation_detail_view_model.dart';

class MessageInputSheet extends StatefulWidget {
  const MessageInputSheet({
    super.key,
    required this.deviceId,
    required this.vm,
    required this.showMessage,
  });

  final String deviceId;
  final ConversationDetailViewModel vm;
  final Future<void> Function(String) showMessage;

  @override
  State<MessageInputSheet> createState() => _MessageInputSheetState();
}

class _MessageInputSheetState extends State<MessageInputSheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final String text = _controller.text;
    if (text.trim().isEmpty) {
      return;
    }
    final SendService service = di.getIt<SendService>();

    final ConversationDetailViewModel vmRef = widget.vm;

    final String tempId = vmRef.addPendingSent(
      content: text,
      size: text.codeUnits.length,
      metadata: <String, String>{'isText': 'true'},
    );

    if (mounted) {
      Navigator.of(context).pop();
    }

    try {
      String deviceIdForSend = widget.deviceId;
      try {
        final DeviceProfileRepository repo = di.getIt<DeviceProfileRepository>();
        final List<DeviceProfile> profiles = await repo.loadAll();
        final Iterable<DeviceProfile> matching = profiles.where((p) => p.id == widget.deviceId);
        if (matching.isNotEmpty) {
          final DeviceProfile profile = matching.first;
          if (profile.endpoint != null && profile.endpoint!.isNotEmpty) {
            deviceIdForSend = profile.endpoint!;
          }
        }
      } catch (_) {}

      final String? transferId = await service.sendMessage(utf8.encode(text), {
        'senderId': di.getIt<NetworkManager>().localId,
        'receiverId': deviceIdForSend,
        'senderName': di.getIt<NetworkManager>().localName,
        'receiverName': widget.deviceId,
        'isText': 'true',
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
          vmRef.replacePendingWithPersisted(tempId, rec);
        } else {
          await vmRef.load();
        }
      } catch (_) {
        await vmRef.load();
      }
    } catch (_) {
      vmRef.markFailed(tempId);
      final String msg = AppLocalizations.of(context)?.failedToSendFile ?? 'Failed to send file';
      await widget.showMessage(msg);
    }
  }

  KeyEventResult _onKey(FocusNode node, RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final isEnter = event.logicalKey == LogicalKeyboardKey.enter;
      final bool isShift = event.isShiftPressed;
      if (isEnter && !isShift) {
        _send();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Focus(
              focusNode: _focusNode,
              onKey: _onKey,
              child: TextField(
                controller: _controller,
                maxLines: null,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)?.typeMessageHint ?? 'Type a message',
                ),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.send), onPressed: _send),
        ],
      ),
    );
  }
}
