import 'dart:io';
import 'package:image/image.dart' as img;

void analyze(String path) {
  final file = File(path);
  if (!file.existsSync()) return;
  final image = img.decodeImage(file.readAsBytesSync())!;
  print('--- Analyzing $path ---');
  print('Size: ${image.width}x${image.height}');
  
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
    print('Block $i: center=${(starts[i]+ends[i])/2}');
  }
  
  List<bool> rowHasPixel = List.filled(image.height, false);
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      if (image.getPixel(x, y).a > 0) {
        rowHasPixel[y] = true;
        break;
      }
    }
  }
  List<int> yStarts = [];
  List<int> yEnds = [];
  if (rowHasPixel[0]) yStarts.add(0);
  for (int y = 1; y < image.height; y++) {
    if (!rowHasPixel[y - 1] && rowHasPixel[y]) {
      yStarts.add(y);
    } else if (rowHasPixel[y - 1] && !rowHasPixel[y]) {
      yEnds.add(y - 1);
    }
  }
  if (rowHasPixel[image.height - 1]) yEnds.add(image.height - 1);
  if (yStarts.isNotEmpty) {
    print('Row Block 0: center=${(yStarts[0]+yEnds[0])/2}');
  }
}

void main() {
  analyze('assets/player2/OkWalk.PNG');
  analyze('assets/player2/Death.png');
}
