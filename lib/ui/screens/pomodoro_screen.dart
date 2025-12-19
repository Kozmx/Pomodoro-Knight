import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_knight/logic/pomodoro/pomodoro_provider.dart';
import 'package:pomodoro_knight/ui/widgets/gold_display.dart';

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
                  selectedTileColor: Colors.deepPurple.withOpacity(0.3),
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
        title: const Column(
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
          ],
        ),
      ),
      body: Container(
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
                    onTap: () => notifier.setMode(PomodoroMode.work),
                  ),
                  const SizedBox(width: 10),
                  _ModeButton(
                    label: 'Break',
                    isSelected: pomodoroState.mode == PomodoroMode.shortBreak,
                    onTap: () {
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
                  color: Colors.black.withOpacity(0.3),
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
                        color: Colors.white.withOpacity(0.6),
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
              ? Colors.white.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: isSelected
                ? Colors.white.withOpacity(0.5)
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
