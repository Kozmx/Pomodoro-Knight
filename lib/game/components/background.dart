import 'package:flame/components.dart';

class GameBackground extends SpriteComponent with HasGameRef {
  // Dünya boyutları - tüm oyun bu koordinatları kullanacak
  static const double worldWidth = 2000;
  static const double worldHeight = 1000;
  
  GameBackground() : super(priority: -100); // En arkada olsun

  @override
  Future<void> onLoad() async {
    // gameRef.images kullanarak Flame'in cache sistemini kullan
    sprite = Sprite(await gameRef.images.load('background/background_test.jpg'));
    
    // Resmi dünya boyutlarına stretch et (dikey olsa bile yatay görünecek)
    size = Vector2(worldWidth, worldHeight);
    position = Vector2.zero();
    anchor = Anchor.topLeft;
  }
}
