import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  // Alet çantamız
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // Kullanıcı durumunu dinleyen stream (giriş/çıkış)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // O anki kullanıcı nesnesini (varsa) verir
  User? get currentUser => _auth.currentUser;

  // Google Sign-In'i başlat (main.dart'ta bir kere çağrılmalı)
  Future<void> initializeGoogleSignIn() async {
    await _googleSignIn.initialize();
  }

  // Google ile giriş başlat
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Kullanıcıya hesap seçme penceresini aç
      final GoogleSignInAccount? account = await _googleSignIn.authenticate();

      if (account == null) {
        // Kullanıcı seçimi iptal etti
        return null;
      }

      // 2. Authentication bilgilerini al
      final googleAuth = account.authentication;

      // 3. Firebase için credential oluştur (idToken ile)
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 4. Firebase ile giriş yap ve sonucu döndür
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print("Google giriş hatası: $e");
      return null;
    }
  }

  // E-posta ve Şifre ile Kayıt Ol
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print("Kayıt hatası: $e");
      return null;
    }
  }

  // E-posta ve Şifre ile Giriş Yap
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print("Giriş hatası: $e");
      return null;
    }
  }

  // Misafir olarak giriş yap (Test için)
  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      print("Anonim giriş hatası: $e");
      return null;
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
