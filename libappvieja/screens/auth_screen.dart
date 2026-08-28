import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
      } else {
        if (_passCtrl.text.length < 6) {
          throw FirebaseAuthException(code: 'weak-password', message: 'La contraseña debe tener al menos 6 caracteres.');
        }
        if (_passCtrl.text != _pass2Ctrl.text) {
          throw FirebaseAuthException(code: 'passwords-dont-match', message: 'Las contraseñas no coinciden.');
        }
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      final msgs = {
        'user-not-found': 'No existe una cuenta con ese email.',
        'wrong-password': 'Contraseña incorrecta.',
        'invalid-credential': 'Email o contraseña incorrectos.',
        'invalid-email': 'Email no válido.',
        'email-already-in-use': 'Ya existe una cuenta con ese email.',
        'weak-password': 'La contraseña es muy débil.',
        'passwords-dont-match': 'Las contraseñas no coinciden.',
      };
      setState(() => _error = msgs[e.code] ?? e.message ?? 'Error desconocido');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flight_takeoff_rounded, size: 64, color: Color(0xFF0F9D8D)),
                const SizedBox(height: 16),
                Text(
                  _isLogin ? 'Iniciar sesión' : 'Crear cuenta',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0B3D37)),
                ),
                const SizedBox(height: 6),
                Text(
                  _isLogin
                      ? 'Accedé a tus alertas desde cualquier dispositivo.'
                      : 'Guardá tus alertas y recibí notificaciones en todos tus dispositivos.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF667085), fontSize: 14),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Contraseña',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                if (!_isLogin) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pass2Ctrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Repetir contraseña',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Color(0xFFD92D20), fontSize: 13)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isLogin ? 'Ingresar' : 'Crear cuenta', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() { _isLogin = !_isLogin; _error = null; }),
                  child: Text(
                    _isLogin ? '¿No tenés cuenta? Registrate' : '¿Ya tenés cuenta? Iniciar sesión',
                    style: const TextStyle(color: Color(0xFF0F9D8D), fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
