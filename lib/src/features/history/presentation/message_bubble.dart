import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import 'conversation_detail_view_model.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.entry,
    required this.sentColor,
    required this.receivedColor,
    required this.vm,
    required this.onOpenFile,
  });

  final MessageEntry entry;
  final Color? sentColor;
  final Color? receivedColor;
  final ConversationDetailViewModel vm;
  final Future<void> Function(String path) onOpenFile;

  @override
  Widget build(BuildContext context) {
    final isSent = entry.direction == MessageDirection.sent;
    final Alignment align = isSent ? Alignment.centerRight : Alignment.centerLeft;
    final Color defaultSent = Colors.blue.shade200;
    final Color defaultReceived = Colors.grey.shade300;
    final Color bubbleBaseColor = isSent
        ? (sentColor ?? defaultSent)
        : (receivedColor ?? defaultReceived);

    final String? content = entry.record.content;
    final String body;
    if (content != null) {
      body = content;
    } else if (entry.record.metadata['filename'] != null) {
      final String name = entry.record.metadata['filename']!;
      body = '$name (${entry.record.size} ${AppLocalizations.of(context)?.bytesLabel ?? 'bytes'})';
    } else {
      body = '${entry.record.size} ${AppLocalizations.of(context)?.bytesLabel ?? 'bytes'}';
    }

    final opacity =
        (entry.direction == MessageDirection.sent && entry.status == MessageStatus.pending)
        ? 0.55
        : 1.0;
    final Color bubbleColor = bubbleBaseColor.withOpacity(opacity);

    final Locale locale = Localizations.localeOf(context);
    final DateTime tsLocal = entry.record.timestamp.toLocal();
    final nowLocal = DateTime.now();
    final bool isSameDay =
        tsLocal.year == nowLocal.year &&
        tsLocal.month == nowLocal.month &&
        tsLocal.day == nowLocal.day;
    final String timeText = isSameDay
        ? DateFormat.jm(locale.toString()).format(tsLocal)
        : '${DateFormat.yMMMd(locale.toString()).format(tsLocal)} ${DateFormat.jm(locale.toString()).format(tsLocal)}';

    final String? localPath = entry.record.metadata['localPath'];

    Widget contentWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(body),
        const SizedBox(height: 6),
        Text(timeText, style: const TextStyle(fontSize: 10)),
      ],
    );

    if (localPath != null) {
      contentWidget = InkWell(
        onTap: () async {
          await onOpenFile(localPath);
        },
        child: contentWidget,
      );
    }

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(color: bubbleColor, borderRadius: BorderRadius.circular(12)),
        child: contentWidget,
      ),
    );
  }
}
