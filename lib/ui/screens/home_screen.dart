import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_knight/logic/navigation/navigation_provider.dart';
import 'package:pomodoro_knight/logic/economy/economy_provider.dart';
import 'package:pomodoro_knight/logic/upgrades/upgrades_provider.dart';
import 'package:pomodoro_knight/ui/screens/pomodoro_screen.dart';
import 'package:pomodoro_knight/ui/screens/game_screen.dart';
import 'package:pomodoro_knight/ui/screens/shop_page/shop_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final List<Widget> _screens = [
    const PomodoroScreen(),
    const GameScreen(),
    const ShopScreen(),
    const Center(child: Text('Leaderboard Screen Placeholder')),
  ];

  void _onItemTapped(int index) {
    ref.read(navigationIndexProvider.notifier).setIndex(index);
  }

  void _showDebugMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🛠️ Debug Menu',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(
                  Icons.monetization_on,
                  color: Color(0xFFFFD700),
                ),
                title: const Text(
                  'Add +1000 Gold',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  ref.read(economyProvider.notifier).addGold(1000);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ +1000 Gold added!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_circle, color: Colors.blue),
                title: const Text(
                  'Add 500 Gold',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  ref.read(economyProvider.notifier).addGold(500);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ 500 Gold added!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.remove_circle, color: Colors.red),
                title: const Text(
                  'Reset Gold to 0',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  ref.read(economyProvider.notifier).resetGold();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔄 Gold reset to 0'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.purple),
                title: const Text(
                  'Reset All Upgrades',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  ref.read(upgradesProvider.notifier).resetAllUpgrades();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔄 All upgrades reset to 0'),
                      backgroundColor: Colors.purple,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(navigationIndexProvider);

    return Scaffold(
      body: _screens[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.grey,
        iconSize: 24,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Pomodoro'),
          BottomNavigationBarItem(icon: Icon(Icons.gamepad), label: 'Game'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Shop',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Leaderboard',
          ),
        ],
        currentIndex: selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: kDebugMode
          ? FloatingActionButton(
              onPressed: _showDebugMenu,
              backgroundColor: Colors.orange,
              child: const Icon(Icons.bug_report, color: Colors.white),
            )
          : null,
    );
  }
}
