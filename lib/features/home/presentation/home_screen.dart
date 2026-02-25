import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_knight/features/home/presentation/navigation_provider.dart';
import 'package:pomodoro_knight/features/auth/presentation/user_provider.dart';
import 'package:pomodoro_knight/features/audio/presentation/audio_provider.dart';
import 'package:pomodoro_knight/features/auth/presentation/auth_provider.dart';
import 'package:pomodoro_knight/features/pomodoro/presentation/pomodoro_screen.dart';
import 'package:pomodoro_knight/features/home/presentation/game_screen.dart';
import 'package:pomodoro_knight/features/shop/presentation/shop_screen.dart';
import 'package:pomodoro_knight/features/inventory/presentation/inventory_screen.dart';
import 'package:pomodoro_knight/core/widgets/sound_button.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Screens: 0=Pomodoro, 1=Shop, 2=Game(FAB), 3=Inventory, 4=Leaderboard
  final List<Widget> _screens = [
    const PomodoroScreen(),
    const ShopScreen(),
    const GameScreen(), // Center (FAB ile açılacak)
    const InventoryScreen(),
    const Center(child: Text('Leaderboard Screen Placeholder')),
  ];

  // FAB animation controller
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _fabGlowAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );

    _fabGlowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    ref.read(audioProvider.notifier).playClick();
    // BottomNav indekslerini gerçek screen indekslerine map et
    // BottomNav: 0=Pomodoro, 1=Shop, 2=Inventory, 3=Leaderboard
    // Screens:   0=Pomodoro, 1=Shop, 2=Game, 3=Inventory, 4=Leaderboard
    int screenIndex;
    if (index <= 1) {
      screenIndex = index; // Pomodoro ve Shop aynı
    } else {
      screenIndex = index + 1; // +1 çünkü Game ortada
    }
    ref.read(navigationIndexProvider.notifier).setIndex(screenIndex);
  }

  void _onGameTabPressed() {
    ref.read(audioProvider.notifier).playClick();
    ref.read(navigationIndexProvider.notifier).setIndex(2); // Game index
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
              SoundListTile(
                leading: const Icon(
                  Icons.monetization_on,
                  color: Color(0xFFFFD700),
                ),
                title: const Text(
                  'Add +1000 Gold',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  final user = ref.read(authStateProvider).value;
                  if (user != null) {
                    await ref
                        .read(userRepositoryProvider)
                        .addGold(user.uid, 1000);
                  }
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              SoundListTile(
                leading: const Icon(Icons.add_circle, color: Colors.blue),
                title: const Text(
                  'Add 500 Gold',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  final user = ref.read(authStateProvider).value;
                  if (user != null) {
                    await ref
                        .read(userRepositoryProvider)
                        .addGold(user.uid, 500);
                  }
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              SoundListTile(
                leading: const Icon(Icons.remove_circle, color: Colors.red),
                title: const Text(
                  'Reset Gold to 0',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  final user = ref.read(authStateProvider).value;
                  if (user != null) {
                    await ref.read(userRepositoryProvider).resetStats(user.uid);
                  }
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              SoundListTile(
                leading: const Icon(Icons.logout, color: Colors.orange),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  ref.read(authRepositoryProvider).signOut();
                  Navigator.pop(context);
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

    // BottomNav için seçili index hesaplama (Game ortada olduğundan)
    // Screens:   0=Pomodoro, 1=Shop, 2=Game, 3=Inventory, 4=Leaderboard
    // BottomNav: 0=Pomodoro, 1=Shop, (FAB), 2=Inventory, 3=Leaderboard
    int bottomNavIndex;
    if (selectedIndex <= 1) {
      bottomNavIndex = selectedIndex;
    } else if (selectedIndex == 2) {
      bottomNavIndex = -1; // Game seçili, ama BottomNav'da yok
    } else {
      bottomNavIndex = selectedIndex - 1;
    }

    return Scaffold(
      body: _screens[selectedIndex],
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF1E1E1E),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Pomodoro
              Expanded(
                child: _buildNavItem(
                  icon: Icons.timer,
                  label: 'Timer',
                  index: 0,
                  isSelected: bottomNavIndex == 0,
                ),
              ),
              // Shop
              Expanded(
                child: _buildNavItem(
                  icon: Icons.shopping_bag,
                  label: 'Shop',
                  index: 1,
                  isSelected: bottomNavIndex == 1,
                ),
              ),
              // Boş alan (FAB için)
              const SizedBox(width: 56),
              // Inventory
              Expanded(
                child: _buildNavItem(
                  icon: Icons.backpack,
                  label: 'Bag',
                  index: 2,
                  isSelected: bottomNavIndex == 2,
                ),
              ),
              // Leaderboard
              Expanded(
                child: _buildNavItem(
                  icon: Icons.leaderboard,
                  label: 'Rank',
                  index: 3,
                  isSelected: bottomNavIndex == 3,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabAnimationController,
        builder: (context, child) {
          final isGameSelected = selectedIndex == 2;
          return Transform.scale(
            scale: isGameSelected ? _fabScaleAnimation.value : 1.0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurpleAccent.withOpacity(
                      isGameSelected ? _fabGlowAnimation.value : 0.3,
                    ),
                    blurRadius: isGameSelected ? 20 : 12,
                    spreadRadius: isGameSelected ? 4 : 2,
                  ),
                ],
              ),
              child: GestureDetector(
                onLongPress: kDebugMode ? _showDebugMenu : null,
                child: FloatingActionButton(
                  onPressed: _onGameTabPressed,
                  backgroundColor: isGameSelected
                      ? Colors.deepPurpleAccent
                      : const Color(0xFF2A2A2A),
                  elevation: 8,
                  child: Icon(
                    Icons.videogame_asset,
                    color: isGameSelected
                        ? Colors.white
                        : Colors.deepPurpleAccent,
                    size: 32,
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.deepPurpleAccent : Colors.grey,
              size: 22,
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.deepPurpleAccent : Colors.grey,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
