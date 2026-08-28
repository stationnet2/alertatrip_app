import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> register(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String? getErrorMessage(FirebaseAuthException e) {
    final msgs = {
      'user-not-found': 'No existe una cuenta con ese email.',
      'wrong-password': 'Contraseña incorrecta.',
      'invalid-credential': 'Email o contraseña incorrectos.',
      'invalid-email': 'Email no válido.',
      'email-already-in-use': 'Ya existe una cuenta con ese email.',
      'weak-password': 'La contraseña es muy débil.',
    };
    return msgs[e.code] ?? e.message;
  }
}
