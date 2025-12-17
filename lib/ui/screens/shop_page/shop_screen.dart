import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_knight/ui/screens/shop_page/tabs/shop_tab.dart';
import 'package:pomodoro_knight/ui/screens/shop_page/tabs/upgrades_tab.dart';
import 'package:pomodoro_knight/ui/widgets/gold_display.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: const [
          Padding(padding: EdgeInsets.only(right: 16.0), child: GoldDisplay()),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: 'Shop', icon: Icon(Icons.shopping_cart)),
                Tab(text: 'Upgrades', icon: Icon(Icons.upgrade)),
              ],
            ),
            Expanded(child: TabBarView(children: [ShopTab(), UpgradesTab()])),
          ],
        ),
      ),
    );
  }
}
