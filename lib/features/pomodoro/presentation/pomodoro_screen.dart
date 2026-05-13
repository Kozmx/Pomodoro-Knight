import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_knight/features/pomodoro/presentation/pomodoro_provider.dart';
import 'package:pomodoro_knight/core/widgets/gold_display.dart';
import 'package:pomodoro_knight/features/auth/presentation/auth_provider.dart';


class PomodoroScreen extends ConsumerWidget {
  const PomodoroScreen({super.key});

  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showDurationPicker(
    BuildContext context,
    WidgetRef ref,
    String title,
    int currentValue,
    Function(int) onSaved, {
    List<int>? allowedValues,
  }) {
    int selectedValue = currentValue ~/ 60;
    final List<int> items =
        allowedValues ?? List.generate(60, (index) => index + 1);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final minute = items[index];
                return ListTile(
                  title: Text(
                    '$minute min',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  selected: minute == selectedValue,
                  selectedTileColor: Colors.deepPurple.withValues(alpha: 0.3),
                  onTap: () {
                    onSaved(minute);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pomodoroState = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'POMODORO',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pixelmania',
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'KNIGHT',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pixelmania',
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          Padding(padding: EdgeInsets.only(right: 16.0), child: GoldDisplay()),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1E1E1E),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.purpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Icon(Icons.settings, color: Colors.white, size: 40),
                  SizedBox(height: 10),
                  Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.timer, color: Colors.purpleAccent),
              title: const Text(
                'Work Duration',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                '${pomodoroState.workDuration ~/ 60} minutes',
                style: const TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDurationPicker(
                  context,
                  ref,
                  'Set Work Duration',
                  pomodoroState.workDuration,
                  (val) => notifier.setWorkDuration(val),
                  allowedValues: [25, 40, 60],
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.coffee, color: Colors.purpleAccent),
              title: const Text(
                'Short Break Duration',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                '${pomodoroState.shortBreakDuration ~/ 60} minutes',
                style: const TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDurationPicker(
                  context,
                  ref,
                  'Set Short Break Duration',
                  pomodoroState.shortBreakDuration,
                  (val) => notifier.setShortBreakDuration(val),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.orangeAccent),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Minecraftia',
                  fontSize: 13,
                ),
              ),
              onTap: () {
                Navigator.pop(context); // Drawer'ı kapat
                ref.read(authRepositoryProvider).signOut();
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background/pomodoro_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Mode Selector - Üstte
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ModeButton(
                    label: 'Work',
                    isSelected: pomodoroState.mode == PomodoroMode.work,
                    onTap: () {
                      if (pomodoroState.mode == PomodoroMode.work) return;
                      notifier.setMode(PomodoroMode.work);
                    },
                  ),
                  const SizedBox(width: 10),
                  _ModeButton(
                    label: 'Break',
                    isSelected: pomodoroState.mode == PomodoroMode.shortBreak,
                    onTap: () {
                      if (pomodoroState.mode == PomodoroMode.shortBreak) return;

                      if (pomodoroState.mode == PomodoroMode.work &&
                          pomodoroState.remainingSeconds > 0 &&
                          pomodoroState.remainingSeconds <
                              pomodoroState.initialSeconds) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'You must finish your work session first!',
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }
                      notifier.setMode(PomodoroMode.shortBreak);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Timer with Green Rectangle Border
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 30,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.greenAccent, width: 4),
                  borderRadius: BorderRadius.zero,
                  color: Colors.black.withValues(alpha: 0.3),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(pomodoroState.remainingSeconds),
                      style: const TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pomodoroState.status == PomodoroStatus.running
                          ? 'FOCUS'
                          : 'READY',
                      style: TextStyle(
                        fontSize: 16,
                        letterSpacing: 4,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // Karakter GIF - Moda göre değişir
              Expanded(
                child: Center(
                  child: pomodoroState.mode == PomodoroMode.shortBreak
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/background/test_char.gif',
                              width: 150,
                              height: 150,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 10),
                            Image.asset(
                              'assets/background/campfire.gif',
                              width: 150,
                              height: 150,
                              fit: BoxFit.contain,
                            ),
                          ],
                        )
                      : Image.asset(
                          'assets/background/test_char.gif',
                          width: 200,
                          height: 200,
                          fit: BoxFit.contain,
                        ),
                ),
              ),

              // Controls - Navigation bar üstünde
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        if (pomodoroState.status == PomodoroStatus.running) {
                          notifier.pauseTimer();
                        } else {
                          notifier.startTimer();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            pomodoroState.status == PomodoroStatus.running
                            ? Colors.orange
                            : Colors.greenAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      icon: Icon(
                        pomodoroState.status == PomodoroStatus.running
                            ? Icons.pause
                            : Icons.play_arrow,
                        size: 24,
                      ),
                      label: Text(
                        pomodoroState.status == PomodoroStatus.running
                            ? 'PAUSE'
                            : pomodoroState.mode == PomodoroMode.work
                            ? 'START WORK'
                            : 'START BREAK',
                        style: const TextStyle(
                          fontFamily: 'Minecraftia',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: notifier.resetTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      icon: const Icon(Icons.refresh, size: 24),
                      label: const Text(
                        'RESET',
                        style: TextStyle(
                          fontFamily: 'Minecraftia',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
        // Coin Animation Overlay
        const CoinAnimationOverlay(),
        ],
      ),
    );
  }
}

class CoinAnimationOverlay extends ConsumerStatefulWidget {
  const CoinAnimationOverlay({super.key});

  @override
  ConsumerState<CoinAnimationOverlay> createState() => _CoinAnimationOverlayState();
}

class _CoinAnimationOverlayState extends ConsumerState<CoinAnimationOverlay> {
  int _lastGold = 0;
  final List<_CoinPopupItem> _popups = [];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pomodoroProvider);
    
    // Altın arttıysa yeni bir popup oluştur
    if (state.earnedGold > _lastGold) {
      _lastGold = state.earnedGold;
      
      // Aynı anda birden fazla gelebilir (eğer multiplier yüksekse)
      // Ama biz sadece 1 tane altın efekti gösterelim, karışıklık olmasın
      final popup = _CoinPopupItem(id: DateTime.now().millisecondsSinceEpoch);
      
      // Build anında state değiştiremeyeceğimiz için frame sonrasına bırakıyoruz
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _popups.add(popup);
          });
          
          // 2 saniye sonra ekrandan sil
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _popups.remove(popup);
              });
            }
          });
        }
      });
    } else if (state.earnedGold < _lastGold) {
      // Eğer resetlenmişse (örn. timer bitince sıfırlanır) lastGold'u güncelle
      // Build sırasında state güncellemeye gerek yok, sadece değişkende tutuyoruz
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _lastGold = state.earnedGold;
      });
    }

    return Stack(
      children: _popups.map((p) => _AnimatedCoinWidget(key: ValueKey(p.id))).toList(),
    );
  }
}

class _CoinPopupItem {
  final int id;
  _CoinPopupItem({required this.id});
}

class _AnimatedCoinWidget extends StatefulWidget {
  const _AnimatedCoinWidget({super.key});

  @override
  State<_AnimatedCoinWidget> createState() => _AnimatedCoinWidgetState();
}

class _AnimatedCoinWidgetState extends State<_AnimatedCoinWidget> with TickerProviderStateMixin {
  late AnimationController _moveController;
  late Animation<double> _moveAnimation;
  late AnimationController _spriteController;

  @override
  void initState() {
    super.initState();
    _moveController = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 2)
    )..forward();
    
    _moveAnimation = Tween<double>(begin: 0, end: -150).animate(
      CurvedAnimation(parent: _moveController, curve: Curves.easeOut)
    );
    
    _spriteController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 600)
    )..repeat();
  }

  @override
  void dispose() {
    _moveController.dispose();
    _spriteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _moveController,
      builder: (context, child) {
        return Positioned(
          // Ekranın tam ortasında Timer'ın oradan çıksın
          bottom: MediaQuery.of(context).size.height / 2 + _moveAnimation.value - 50,
          left: MediaQuery.of(context).size.width / 2 - 32,
          child: Opacity(
            opacity: 1.0 - _moveController.value, // Yükseldikçe silin
            child: child,
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _spriteController,
        builder: (context, child) {
          // 8 frame (0'dan 7'ye kadar)
          final frame = (_spriteController.value * 8).floor() % 8;
          return Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/Coin.png'),
                fit: BoxFit.none,
                // Offset fraction = 0 ile 1 arası
                alignment: FractionalOffset(frame / 7.0, 0),
                scale: 128 / 64, // orjinal 128px yükseklik, biz 64px kutuda gösteriyoruz
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
