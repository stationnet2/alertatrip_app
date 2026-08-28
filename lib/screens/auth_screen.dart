import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = AuthService();
  bool _isLogin = true;
  bool _loading = false;
  String? _error;
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (_isLogin) {
        await _auth.signIn(_email.text.trim(), _pass.text);
      } else {
        if (_pass.text.length < 6) throw Exception('Mínimo 6 caracteres');
        if (_pass.text != _pass2.text) throw Exception('Las contraseñas no coinciden');
        await _auth.register(_email.text.trim(), _pass.text);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _auth.getErrorMessage(e));
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
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.flight_takeoff_rounded, size: 64, color: Color(0xFF0F9D8D)),
              const SizedBox(height: 16),
              Text(_isLogin ? 'Iniciar sesión' : 'Crear cuenta',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0B3D37))),
              const SizedBox(height: 6),
              Text(
                _isLogin ? 'Accedé a tus alertas desde cualquier dispositivo.' : 'Guardá tus alertas y recibí notificaciones.',
                textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF667085), fontSize: 14)),
              const SizedBox(height: 24),
              _field(_email, 'Email', TextInputType.emailAddress),
              const SizedBox(height: 12),
              _field(_pass, 'Contraseña', null, obscure: true),
              if (!_isLogin) ...[
                const SizedBox(height: 12),
                _field(_pass2, 'Repetir contraseña', null, obscure: true),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Color(0xFFD92D20), fontSize: 13)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 48,
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
                child: Text(_isLogin ? '¿No tenés cuenta? Registrate' : '¿Ya tenés cuenta? Iniciar sesión',
                    style: const TextStyle(color: Color(0xFF0F9D8D), fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, TextInputType? type, {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
