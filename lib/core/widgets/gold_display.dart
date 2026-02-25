import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_knight/features/auth/presentation/user_provider.dart';
import 'package:intl/intl.dart';

class GoldDisplay extends ConsumerWidget {
  final bool showIcon;
  final double fontSize;
  const GoldDisplay({super.key, this.showIcon = true, this.fontSize = 16});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // userProvider'ın ham durumunu izle (loading/data/error hangisinde?)
    final userAsync = ref.watch(userProvider);
    final formatter = NumberFormat('#,###', 'en_US');

    // DEBUG: Konsolda userProvider durumunu göster
    debugPrint('🪙 GoldDisplay → userProvider state: $userAsync');

    return userAsync.when(
      loading: () {
        debugPrint('🪙 GoldDisplay → LOADING...');
        return _buildContainer(formatter.format(0), showIcon);
      },
      error: (err, stack) {
        debugPrint('🪙 GoldDisplay → ERROR: $err');
        debugPrint('🪙 GoldDisplay → STACK: $stack');
        return _buildContainer('ERR', showIcon);
      },
      data: (user) {
        final gold = user?.wallet.gold ?? 0;
        debugPrint('🪙 GoldDisplay → DATA: gold=$gold, user=${user?.uid}');
        return _buildContainer(formatter.format(gold), showIcon);
      },
    );
  }

  Widget _buildContainer(String text, bool showIcon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.zero,
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
            text,
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
