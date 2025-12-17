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
        title: const Text(
          'Pomodoro Knight',
          style: TextStyle(fontWeight: FontWeight.bold),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mode Selector
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
            const SizedBox(height: 50),
            // Circular Timer
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 300,
                  height: 300,
                  child: CircularProgressIndicator(
                    value: pomodoroState.progress,
                    strokeWidth: 20,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      pomodoroState.mode == PomodoroMode.work
                          ? Colors.deepPurpleAccent
                          : Colors.greenAccent,
                    ),
                  ),
                ),
                Column(
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
              ],
            ),
            const SizedBox(height: 60),
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton.large(
                  onPressed: () {
                    if (pomodoroState.status == PomodoroStatus.running) {
                      notifier.pauseTimer();
                    } else {
                      notifier.startTimer();
                    }
                  },
                  backgroundColor: pomodoroState.mode == PomodoroMode.work
                      ? Colors.deepPurpleAccent
                      : Colors.greenAccent,
                  child: Icon(
                    pomodoroState.status == PomodoroStatus.running
                        ? Icons.pause
                        : Icons.play_arrow,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 20),
                FloatingActionButton(
                  onPressed: notifier.resetTimer,
                  backgroundColor: Colors.grey[800],
                  child: const Icon(Icons.refresh, color: Colors.white),
                ),
              ],
            ),
          ],
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
          borderRadius: BorderRadius.circular(30),
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
