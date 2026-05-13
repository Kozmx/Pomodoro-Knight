import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final dir = Directory('assets/player2/');
  final files = dir.listSync();
  File? okFile;
  for (var f in files) {
    if (f.path.contains('Ok') || f.path.contains('at')) {
      okFile = File(f.path);
      break;
    }
  }
  
  if (okFile == null) return;
  print('Found file: \${okFile.path}');
  final image = img.decodeImage(okFile.readAsBytesSync())!;
  
  // Horizontal
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
    print('Block \$i: start=\${starts[i]}, end=\${ends[i]} -> center=\${(starts[i]+ends[i])/2}');
  }
  
  // Vertical
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
  for (int i = 0; i < yStarts.length; i++) {
    print('Row Block \$i: start=\${yStarts[i]}, end=\${yEnds[i]} -> center=\${(yStarts[i]+yEnds[i])/2}');
  }
}
