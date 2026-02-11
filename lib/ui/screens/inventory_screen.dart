import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_knight/core/data/mock_shop_items.dart';
import 'package:pomodoro_knight/core/models/shop_item.dart';
import 'package:pomodoro_knight/logic/inventory/inventory_provider.dart';
import 'package:pomodoro_knight/logic/audio/audio_provider.dart';
import 'package:pomodoro_knight/ui/widgets/gold_display.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🎒 Envanter',
          style: TextStyle(fontFamily: 'Minecraftia', fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: const [
          Padding(padding: EdgeInsets.only(right: 16.0), child: GoldDisplay()),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.deepPurpleAccent,
          labelColor: Colors.deepPurpleAccent,
          unselectedLabelColor: Colors.grey,
          onTap: (_) {
            ref.read(audioProvider.notifier).playClick();
          },
          tabs: const [
            Tab(icon: Icon(Icons.gavel), text: 'Silahlar'),
            Tab(icon: Icon(Icons.shield), text: 'Zırhlar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _WeaponsTab(),
          _ArmorsTab(),
        ],
      ),
    );
  }
}

class _WeaponsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(inventoryProvider);
    final ownedWeapons = mockWeapons
        .where((w) => inventory.ownedWeapons.contains(w.id))
        .toList();

    if (ownedWeapons.isEmpty) {
      return _buildEmptyState(
        icon: Icons.gavel,
        message: 'Henüz silahın yok!\nMağazadan silah satın al.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: ownedWeapons.length,
      itemBuilder: (context, index) {
        return _InventoryItemCard(
          item: ownedWeapons[index],
          isEquipped: inventory.equippedWeapon == ownedWeapons[index].id,
        );
      },
    );
  }
}

class _ArmorsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(inventoryProvider);
    final ownedArmors = mockArmors
        .where((a) => inventory.ownedArmors.contains(a.id))
        .toList();

    if (ownedArmors.isEmpty) {
      return _buildEmptyState(
        icon: Icons.shield,
        message: 'Henüz zırhın yok!\nMağazadan zırh satın al.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: ownedArmors.length,
      itemBuilder: (context, index) {
        return _InventoryItemCard(
          item: ownedArmors[index],
          isEquipped: inventory.equippedArmor == ownedArmors[index].id,
        );
      },
    );
  }
}

Widget _buildEmptyState({required IconData icon, required String message}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 80, color: Colors.grey.withOpacity(0.3)),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.withOpacity(0.7),
            fontSize: 16,
          ),
        ),
      ],
    ),
  );
}

class _InventoryItemCard extends ConsumerStatefulWidget {
  final ShopItem item;
  final bool isEquipped;

  const _InventoryItemCard({
    required this.item,
    required this.isEquipped,
  });

  @override
  ConsumerState<_InventoryItemCard> createState() => _InventoryItemCardState();
}

class _InventoryItemCardState extends ConsumerState<_InventoryItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isEquipped) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _InventoryItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEquipped && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isEquipped && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    ref.read(audioProvider.notifier).playClick();

    if (widget.isEquipped) {
      // Zaten equipped ise bilgi göster
      _showItemInfo(context, widget.item);
    } else {
      // Equip et
      _showEquipDialog(context, ref, widget.item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isEquipped ? _scaleAnimation.value : 1.0,
          child: GestureDetector(
            onTap: _onTap,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isEquipped
                      ? Colors.amber
                      : widget.item.color.withOpacity(0.5),
                  width: widget.isEquipped ? 3 : 2,
                ),
                boxShadow: widget.isEquipped
                    ? [
                        BoxShadow(
                          color: Colors.amber.withOpacity(_glowAnimation.value),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Equipped badge
                    if (widget.isEquipped)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '⚔️ EQUIPPED',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 14),

                    const SizedBox(height: 4),

                    // Icon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: widget.item.color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.item.icon,
                        color: widget.item.color,
                        size: 26,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Item adı
                    Text(
                      widget.item.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Stats preview
                    _buildStatsPreview(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsPreview() {
    if (widget.item is WeaponItem) {
      final weapon = widget.item as WeaponItem;
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flash_on, size: 12, color: Colors.red.shade300),
          Text(
            ' ${weapon.damage}',
            style: TextStyle(fontSize: 10, color: Colors.red.shade300),
          ),
          const SizedBox(width: 8),
          Icon(Icons.speed, size: 12, color: Colors.blue.shade300),
          Text(
            ' ${weapon.attackSpeed}x',
            style: TextStyle(fontSize: 10, color: Colors.blue.shade300),
          ),
        ],
      );
    } else if (widget.item is ArmorItem) {
      final armor = widget.item as ArmorItem;
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield, size: 12, color: Colors.blue.shade300),
          Text(
            ' ${armor.defense}',
            style: TextStyle(fontSize: 10, color: Colors.blue.shade300),
          ),
          const SizedBox(width: 8),
          Icon(Icons.favorite, size: 12, color: Colors.green.shade300),
          Text(
            ' +${armor.health}',
            style: TextStyle(fontSize: 10, color: Colors.green.shade300),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

void _showEquipDialog(BuildContext context, WidgetRef ref, ShopItem item) {
  ref.read(audioProvider.notifier).playSwitch();

  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1E1E1E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Consumer(
        builder: (context, ref, child) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Item icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: item.color, width: 3),
                  ),
                  child: Icon(item.icon, color: item.color, size: 40),
                ),
                const SizedBox(height: 16),

                // Item name
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  item.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 16),

                // Stats
                _buildDetailedStats(item),

                const SizedBox(height: 24),

                // Equip button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(audioProvider.notifier).playClick();
                      if (item is WeaponItem) {
                        ref.read(inventoryProvider.notifier).equipWeapon(item.id);
                      } else if (item is ArmorItem) {
                        ref.read(inventoryProvider.notifier).equipArmor(item.id);
                      }
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('⚔️ ${item.name} kuşanıldı!'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text(
                      'KUŞAN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      );
    },
  );
}

void _showItemInfo(BuildContext context, ShopItem item) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1E1E1E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Equipped badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.black, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'ŞUAN KUŞANILI',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Item icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: item.color, width: 3),
              ),
              child: Icon(item.icon, color: item.color, size: 40),
            ),
            const SizedBox(height: 16),

            // Item name
            Text(
              item.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              item.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),

            // Stats
            _buildDetailedStats(item),

            const SizedBox(height: 24),
          ],
        ),
      );
    },
  );
}

Widget _buildDetailedStats(ShopItem item) {
  if (item is WeaponItem) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildStatRow('Hasar', '${item.damage}', Icons.flash_on, Colors.red),
          const SizedBox(height: 8),
          _buildStatRow(
              'Hız', '${item.attackSpeed}x', Icons.speed, Colors.blue),
          const SizedBox(height: 8),
          _buildStatRow('Kritik Bonus', '+${(item.critBonus * 100).toInt()}%',
              Icons.auto_awesome, Colors.amber),
          if (item.specialEffect != 'None') ...[
            const SizedBox(height: 8),
            _buildStatRow(
                'Özel', item.specialEffect, Icons.stars, Colors.purple),
          ],
        ],
      ),
    );
  } else if (item is ArmorItem) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildStatRow('Savunma', '${item.defense}', Icons.shield, Colors.blue),
          const SizedBox(height: 8),
          _buildStatRow(
              'Can Bonusu', '+${item.health}', Icons.favorite, Colors.green),
        ],
      ),
    );
  }
  return const SizedBox.shrink();
}

Widget _buildStatRow(String label, String value, IconData icon, Color color) {
  return Row(
    children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 8),
      Text(
        label,
        style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      ),
      const Spacer(),
      Text(
        value,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    ],
  );
}
