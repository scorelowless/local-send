import 'package:flutter/material.dart';

import '../../history/data/history_repository.dart';
import 'conversation_detail_screen.dart';
import 'history_view_model.dart';

class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.conv,
    required this.vm,
    required this.iconForType,
  });

  final Conversation conv;
  final HistoryViewModel vm;
  final IconData Function(String?) iconForType;

  @override
  Widget build(BuildContext context) {
    final bool reachable = vm.isReachable(conv.id);
    final String? deviceType = vm.deviceTypeMap[conv.id];

    return ListTile(
      leading: Icon(iconForType(deviceType)),
      title: Row(
        children: [
          Expanded(child: Text(conv.title)),
          const SizedBox(width: 8),
        ],
      ),
      subtitle: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: reachable ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(child: Text(conv.lastMessage)),
        ],
      ),
      trailing: GestureDetector(
        onTap: () async {
          await vm.toggleFavorite(conv.id);
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
          child: conv.favorite
              ? const Icon(Icons.star, key: ValueKey('star_filled'), color: Colors.amber)
              : const Icon(Icons.star_border, key: ValueKey('star_empty')),
        ),
      ),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => ConversationDetailScreen(deviceId: conv.id, title: conv.title),
          ),
        );
        try {
          await vm.refresh();
        } catch (_) {}
      },
    );
  }
}
