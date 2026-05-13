import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/player2/Walk.PNG');
  final image = img.decodeImage(file.readAsBytesSync())!;
  
  List<bool> colHasPixel = List.filled(image.width, false);
  for (int x = 0; x < image.width; x++) {
    for (int y = 0; y < image.height; y++) {
      if (image.getPixel(x, y).a > 0) {
        colHasPixel[x] = true;
        break;
      }
    }
  }
  
  List<int> starts = [];
  List<int> ends = [];
  
  if (colHasPixel[0]) starts.add(0);
  
  for (int x = 1; x < image.width; x++) {
    if (!colHasPixel[x - 1] && colHasPixel[x]) {
      starts.add(x);
    } else if (colHasPixel[x - 1] && !colHasPixel[x]) {
      ends.add(x - 1);
    }
  }
  if (colHasPixel[image.width - 1]) ends.add(image.width - 1);
  
  for (int i = 0; i < starts.length; i++) {
    print('Block $i: start=${starts[i]}, end=${ends[i]}, width=${ends[i] - starts[i]}');
  }
}
