import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  const AuthScreen({super.key, this.onSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _loading = false;
  String? _error;
  bool _emailSent = false;

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
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        if (_passCtrl.text.length < 6) {
          throw FirebaseAuthException(code: 'weak-password', message: 'La contrasena debe tener al menos 6 caracteres.');
        }
        if (_passCtrl.text != _pass2Ctrl.text) {
          throw FirebaseAuthException(code: 'passwords-dont-match', message: 'Las contrasenas no coinciden.');
        }
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
        await cred.user?.sendEmailVerification();
        setState(() => _emailSent = true);
      }
    } on FirebaseAuthException catch (e) {
      final msgs = {
        'user-not-found': 'No existe una cuenta con ese email.',
        'wrong-password': 'Contrasena incorrecta.',
        'invalid-credential': 'Email o contrasena incorrectos.',
        'invalid-email': 'Email no valido.',
        'email-already-in-use': 'Ya existe una cuenta con ese email.',
        'weak-password': 'La contrasena es muy debil.',
        'passwords-dont-match': 'Las contrasenas no coinciden.',
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
                  _isLogin ? l10n.login : l10n.register,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0B3D37)),
                ),
                const SizedBox(height: 6),
                Text(
                  _isLogin
                      ? 'Accede a tus alertas desde cualquier dispositivo.'
                      : 'Guarda tus alertas y recibi notificaciones en todos tus dispositivos.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF667085), fontSize: 14),
                ),
                const SizedBox(height: 24),
                if (_emailSent) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF8EE),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFB7E0C0)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.mark_email_read_rounded, color: Color(0xFF18864B), size: 32),
                        const SizedBox(height: 8),
                        const Text(
                          'Cuenta creada!',
                          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF146C3A)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Te enviamos un email de verificacion. Abri el link que te llego para activar tu cuenta. ${l10n.spamWarning}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF146C3A), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() { _isLogin = true; _emailSent = false; _error = null; }),
                    child: const Text('Ya verifique mi email, iniciar sesion', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ] else ...[
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: l10n.email,
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
                      hintText: l10n.password,
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
                        hintText: l10n.repeatPassword,
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
                          : Text(_isLogin ? l10n.enter : l10n.createAccount, style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() { _isLogin = !_isLogin; _error = null; _emailSent = false; }),
                    child: Text(
                      _isLogin ? l10n.noAccount : l10n.haveAccount,
                      style: const TextStyle(color: Color(0xFF0F9D8D), fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
