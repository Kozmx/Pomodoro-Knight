import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/player2/Walk.PNG');
  final image = img.decodeImage(file.readAsBytesSync())!;
  
  List<bool> rowHasPixel = List.filled(image.height, false);
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      if (image.getPixel(x, y).a > 0) {
        rowHasPixel[y] = true;
        break;
      }
    }
  }
  
  List<int> starts = [];
  List<int> ends = [];
  
  if (rowHasPixel[0]) starts.add(0);
  
  for (int y = 1; y < image.height; y++) {
    if (!rowHasPixel[y - 1] && rowHasPixel[y]) {
      starts.add(y);
    } else if (rowHasPixel[y - 1] && !rowHasPixel[y]) {
      ends.add(y - 1);
    }
  }
  if (rowHasPixel[image.height - 1]) ends.add(image.height - 1);
  
  for (int i = 0; i < starts.length; i++) {
    print('Row Block Walk $i: start=${starts[i]}, end=${ends[i]}, height=${ends[i] - starts[i]}');
  }
}
