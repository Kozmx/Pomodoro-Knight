import 'dart:io';
import 'package:image/image.dart' as img;

void printSize(String path) {
  final file = File(path);
  if (!file.existsSync()) return;
  final image = img.decodeImage(file.readAsBytesSync())!;
  print(path);
  print(image.width);
  print(image.height);
}

void main() {
  printSize('assets/skeletonboss/skeletonATTACK.PNG');
  printSize('assets/skeletonboss/skeletonDEATH.PNG');
  printSize('assets/skeletonboss/skeletonWALK.PNG');
}
