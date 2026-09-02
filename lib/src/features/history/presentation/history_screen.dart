import 'package:flutter/material.dart';

import '../../../di/di.dart' as di;
import '../../../l10n/app_localizations.dart';
import '../data/history_repository.dart';
import 'conversation_tile.dart';
import 'history_view_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final HistoryViewModel vm;

  @override
  void initState() {
    super.initState();
    vm = di.getIt<HistoryViewModel>();
    vm.load();
  }

  IconData _iconForDeviceType(String? type) {
    switch (type) {
      case 'phone':
        return Icons.phone_android;
      case 'laptop':
        return Icons.laptop;
      case 'tablet':
        return Icons.tablet;
      default:
        return Icons.devices;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.historyTitle ?? 'Conversation history'),
      ),
      body: AnimatedBuilder(
        animation: vm,
        builder: (context, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (vm.conversations.isEmpty) {
            return Center(
              child: Text(AppLocalizations.of(context)?.noConversations ?? 'No conversations yet'),
            );
          }
          return ListView.builder(
            itemCount: vm.conversations.length,
            itemBuilder: (context, index) {
              final Conversation conv = vm.conversations[index];
              return ConversationTile(conv: conv, vm: vm, iconForType: _iconForDeviceType);
            },
          );
        },
      ),
    );
  }
}
