import 'package:flame/components.dart';

class GameBackground extends SpriteComponent with HasGameRef {
  // Dünya boyutları - tüm oyun bu koordinatları kullanacak
  static const double worldWidth = 2000;
  static const double worldHeight = 1000;
  
  GameBackground() : super(priority: -100); // En arkada olsun

  @override
  Future<void> onLoad() async {
    sprite = Sprite(await gameRef.images.load('background/background.PNG'));
    
    // Resmi dünya boyutlarına stretch et (dikey olsa bile yatay görünecek)
    size = Vector2(worldWidth, worldHeight);
    position = Vector2.zero();
    anchor = Anchor.topLeft;
  }
}
