import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_knight/logic/economy/economy_provider.dart';
import 'package:intl/intl.dart';

class GoldDisplay extends ConsumerWidget {
  final bool showIcon;
  final double fontSize;

  const GoldDisplay({super.key, this.showIcon = true, this.fontSize = 16});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gold = ref.watch(economyProvider).gold;
    final formatter = NumberFormat('#,###', 'en_US');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD700), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            const Icon(
              Icons.monetization_on,
              color: Color(0xFFFFD700),
              size: 20,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            formatter.format(gold),
            style: TextStyle(
              color: const Color(0xFFFFD700),
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
