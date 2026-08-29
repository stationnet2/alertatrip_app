import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';

class VerifyEmailScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const VerifyEmailScreen({super.key, required this.onLogout});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _sent = false;
  bool _checking = false;

  Future<void> _resend() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await user.sendEmailVerification();
    setState(() => _sent = true);
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await user.reload();
      if (user.emailVerified) {
        if (mounted) setState(() {});
      } else {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.verifyEmailDesc} ${l10n.spamWarning}')),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mark_email_unread_rounded, size: 64, color: Color(0xFF0F9D8D)),
                const SizedBox(height: 20),
                Text(
                  l10n.verifyEmail,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.verifyEmailDesc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF667085), height: 1.4),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF79009).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFF79009)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.spamWarning,
                          style: const TextStyle(color: Color(0xFFF79009), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_sent)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text('✓ Email reenviado', style: TextStyle(color: Color(0xFF18864B), fontWeight: FontWeight.w700)),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _sent ? null : _resend,
                    child: Text(l10n.resendEmail, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _checking ? null : _check,
                    child: _checking
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(l10n.continueText, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: widget.onLogout,
                  child: const Text('Cerrar sesion y usar otra cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
