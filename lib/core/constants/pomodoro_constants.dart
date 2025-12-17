// Pomodoro zamanlayıcı sabitleri
class PomodoroConstants {
  // Varsayılan süreler (saniye cinsinden)
  static const int defaultWorkDuration = 25 * 60; // 25 dakika
  static const int defaultShortBreakDuration = 5 * 60; // 5 dakika
  static const int defaultLongBreakDuration = 15 * 60; // 15 dakika

  // İzin verilen çalışma süreleri (dakika)
  static const List<int> allowedWorkDurations = [25, 40, 60];
}
