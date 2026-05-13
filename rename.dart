import 'dart:io';
void main() {
  final dir = Directory('assets/player2/');
  for (var f in dir.listSync()) {
    if (f.path.contains('Ok') || f.path.contains('at')) {
      f.renameSync('assets/player2/ok_atis.png');
      print('Renamed to ok_atis.png');
      break;
    }
  }
}
