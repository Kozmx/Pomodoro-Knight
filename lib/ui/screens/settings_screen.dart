import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_knight/logic/audio/audio_provider.dart';
import 'package:pomodoro_knight/game/services/game_audio_service.dart';
import 'package:pomodoro_knight/ui/widgets/sound_button.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final GameAudioService _gameAudio = GameAudioService();

  @override
  Widget build(BuildContext context) {
    final audioSettings = ref.watch(audioProvider);
    final audioNotifier = ref.read(audioProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '⚙️ Ayarlar',
          style: TextStyle(fontFamily: 'Minecraftia', fontSize: 20),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        leading: SoundButton(
          onPressed: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ses Ayarları Bölümü
            _buildSectionTitle('🔊 Ses Ayarları'),
            const SizedBox(height: 16),
            _buildSettingsCard(
              children: [
                // Ses Aç/Kapa Toggle
                _buildSoundToggle(context, audioSettings, audioNotifier),
                const Divider(color: Colors.white24),
                // Ses Seviyesi Slider
                _buildVolumeSlider(context, audioSettings, audioNotifier),
                const Divider(color: Colors.white24),
                // Ses Test Butonları
                _buildSoundTestSection(context, audioNotifier),
              ],
            ),
            const SizedBox(height: 30),

            // Diğer Ayarlar (gelecekte eklenebilir)
            _buildSectionTitle('🎮 Oyun Sesleri'),
            const SizedBox(height: 16),
            _buildSettingsCard(
              children: [
                // Oyun Sesi Aç/Kapa Toggle
                _buildGameSoundToggle(context),
                const Divider(color: Colors.white24),
                // Master Volume
                _buildGameVolumeSlider(context, 'Master', _gameAudio.volume, (v) {
                  setState(() => _gameAudio.setVolume(v));
                }),
                const Divider(color: Colors.white24),
                // SFX Volume
                _buildGameVolumeSlider(context, 'SFX', _gameAudio.sfxVolume, (v) {
                  setState(() => _gameAudio.setSfxVolume(v));
                }),
                const Divider(color: Colors.white24),
                // Game Sound Test Buttons
                _buildGameSoundTestSection(context),
              ],
            ),
            const SizedBox(height: 30),
            
            _buildSectionTitle('📱 Uygulama'),
            const SizedBox(height: 16),
            _buildSettingsCard(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.info_outline,
                    color: Colors.white70,
                  ),
                  title: const Text(
                    'Versiyon',
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: const Text(
                    'v0.1.0',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontFamily: 'Minecraftia',
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSoundToggle(
    BuildContext context,
    AudioSettings settings,
    AudioNotifier notifier,
  ) {
    return SwitchListTile(
      secondary: Icon(
        settings.soundEnabled ? Icons.volume_up : Icons.volume_off,
        color: settings.soundEnabled ? Colors.greenAccent : Colors.white54,
      ),
      title: const Text('UI Sesleri', style: TextStyle(color: Colors.white)),
      subtitle: Text(
        settings.soundEnabled ? 'Sesler açık' : 'Sesler kapalı',
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      value: settings.soundEnabled,
      activeColor: Colors.greenAccent,
      onChanged: (value) {
        notifier.setSoundEnabled(value);
        if (value) {
          notifier.playSwitch();
        }
      },
    );
  }

  Widget _buildVolumeSlider(
    BuildContext context,
    AudioSettings settings,
    AudioNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.volume_down, color: Colors.white54, size: 20),
              Expanded(
                child: Slider(
                  value: settings.volume,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  activeColor: Colors.deepPurpleAccent,
                  inactiveColor: Colors.white24,
                  label: '${(settings.volume * 100).round()}%',
                  onChanged: settings.soundEnabled
                      ? (value) {
                          notifier.setVolume(value);
                        }
                      : null,
                  onChangeEnd: settings.soundEnabled
                      ? (value) {
                          notifier.playClick();
                        }
                      : null,
                ),
              ),
              const Icon(Icons.volume_up, color: Colors.white54, size: 20),
            ],
          ),
          Center(
            child: Text(
              'Ses Seviyesi: ${(settings.volume * 100).round()}%',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundTestSection(BuildContext context, AudioNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sesleri Test Et',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildTestSoundButton(
                'Tıklama',
                Icons.touch_app,
                Colors.blue,
                () => notifier.playSound(UiSound.click1),
              ),
              _buildTestSoundButton(
                'Hover',
                Icons.mouse,
                Colors.orange,
                () => notifier.playSound(UiSound.rollover),
              ),
              _buildTestSoundButton(
                'Switch',
                Icons.toggle_on,
                Colors.green,
                () => notifier.playSound(UiSound.switch1),
              ),
              _buildTestSoundButton(
                'Click 2',
                Icons.ads_click,
                Colors.purple,
                () => notifier.playSound(UiSound.click2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestSoundButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.2),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  // ==================== GAME SOUND WIDGETS ====================

  Widget _buildGameSoundToggle(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(
        _gameAudio.soundEnabled ? Icons.videogame_asset : Icons.videogame_asset_off,
        color: _gameAudio.soundEnabled ? Colors.cyanAccent : Colors.white54,
      ),
      title: const Text('Oyun Sesleri', style: TextStyle(color: Colors.white)),
      subtitle: Text(
        _gameAudio.soundEnabled ? 'Oyun sesleri açık' : 'Oyun sesleri kapalı',
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      value: _gameAudio.soundEnabled,
      activeColor: Colors.cyanAccent,
      onChanged: (value) {
        setState(() => _gameAudio.setSoundEnabled(value));
        if (value) {
          _gameAudio.playPowerUp();
        }
      },
    );
  }

  Widget _buildGameVolumeSlider(
    BuildContext context,
    String label,
    double value,
    Function(double) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.volume_down, color: Colors.white54, size: 20),
              Expanded(
                child: Slider(
                  value: value,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  activeColor: Colors.cyanAccent,
                  inactiveColor: Colors.white24,
                  label: '${(value * 100).round()}%',
                  onChanged: _gameAudio.soundEnabled ? onChanged : null,
                ),
              ),
              const Icon(Icons.volume_up, color: Colors.white54, size: 20),
            ],
          ),
          Center(
            child: Text(
              '$label: ${(value * 100).round()}%',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameSoundTestSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Oyun Seslerini Test Et',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTestSoundButton('Kılıç', Icons.gavel, Colors.orange, 
                () => _gameAudio.playSwordSwoosh()),
              _buildTestSoundButton('Vuruş', Icons.flash_on, Colors.red, 
                () => _gameAudio.playSwordHit()),
              _buildTestSoundButton('Zıplama', Icons.arrow_upward, Colors.blue, 
                () => _gameAudio.playJump()),
              _buildTestSoundButton('Hasar', Icons.heart_broken, Colors.pink, 
                () => _gameAudio.playPlayerHurt()),
              _buildTestSoundButton('Ölüm', Icons.dangerous, Colors.grey, 
                () => _gameAudio.playPlayerDeath()),
              _buildTestSoundButton('Slime', Icons.water_drop, Colors.green, 
                () => _gameAudio.playSlimeDeath()),
              _buildTestSoundButton('Kalkan', Icons.shield, Colors.cyan, 
                () => _gameAudio.playShieldBlock()),
              _buildTestSoundButton('Güç', Icons.auto_awesome, Colors.yellow, 
                () => _gameAudio.playPowerUp()),
              _buildTestSoundButton('XP', Icons.star, Colors.amber, 
                () => _gameAudio.playXpCollect()),
              _buildTestSoundButton('Coin', Icons.monetization_on, Colors.yellow, 
                () => _gameAudio.playCoinCollect()),
              _buildTestSoundButton('Can', Icons.favorite, Colors.red, 
                () => _gameAudio.playHeal()),
              _buildTestSoundButton('Asansör', Icons.elevator, Colors.purple, 
                () => _gameAudio.playElevatorDing()),
              _buildTestSoundButton('Level', Icons.celebration, Colors.teal, 
                () => _gameAudio.playLevelComplete()),
            ],
          ),
        ],
      ),
    );
  }
}
