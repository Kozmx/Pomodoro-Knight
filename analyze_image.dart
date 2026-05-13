import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/player2/Walk.PNG');
  final image = img.decodeImage(file.readAsBytesSync())!;
  
  print('Image size: ${image.width}x${image.height}');
  
  // Find non-transparent columns
  List<bool> colHasPixel = List.filled(image.width, false);
  for (int x = 0; x < image.width; x++) {
    for (int y = 0; y < image.height; y++) {
      if (image.getPixel(x, y).a > 0) {
        colHasPixel[x] = true;
        break;
      }
    }
  }
  
  // Find transitions
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
  
  if (colHasPixel[image.width - 1]) {
    ends.add(image.width - 1);
  }
  
  print('Found ${starts.length} separate elements');
  
  if (starts.length > 1) {
    List<int> distances = [];
    for (int i = 1; i < starts.length; i++) {
      distances.add(starts[i] - starts[i - 1]);
    }
    print('Distances between starts: $distances');
    // Calculate average or median
    distances.sort();
    print('Median distance (likely frame width): ${distances[distances.length ~/ 2]}');
  }
}
