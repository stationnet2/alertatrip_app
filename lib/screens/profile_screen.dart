import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  bool get _isAdmin {
    final email = FirebaseAuth.instance.currentUser?.email?.toLowerCase() ?? '';
    return email == 'descuentonadrian@gmail.com';
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar sesion: $e')),
        );
      }
    }
  }

  void _changeLanguage(String code) {
    localeNotifier.value = Locale(code);
  }

  Future<void> _openAdminPanel() async {
    const url = 'https://alertatrip.com/admin.html';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    final verified = user?.emailVerified ?? false;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: Text(l10n.profile, style: const TextStyle(fontWeight: FontWeight.w900)),
          backgroundColor: const Color(0xFFF5F7FB),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_outline_rounded, size: 64, color: Color(0xFF98A2B3)),
                const SizedBox(height: 16),
                Text(
                  l10n.guest,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.needLoginForAlerts,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF667085)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    ),
                    child: Text(l10n.login, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(l10n.profile, style: const TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFFF5F7FB),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: verified ? const Color(0xFF0F9D8D) : const Color(0xFFF79009),
                  child: Text(
                    email!.isNotEmpty ? email[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  email,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                if (!verified)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFF79009)),
                        SizedBox(width: 6),
                        Text(
                          'Email no verificado',
                          style: TextStyle(color: Color(0xFFF79009), fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                else
                  const Text(
                    'AlertaTrip Premium',
                    style: TextStyle(color: Color(0xFF0F9D8D), fontWeight: FontWeight.w700),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.language, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                _buildLanguageOption('es', l10n.spanish, Icons.language),
                _buildLanguageOption('en', l10n.english, Icons.language),
                _buildLanguageOption('pt', l10n.portuguese, Icons.language),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_isAdmin) ...[
            _buildMenuItem(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Panel de administracion',
              subtitle: 'Gestionar destinos desde la web',
              onTap: _openAdminPanel,
            ),
            const SizedBox(height: 12),
          ],
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            title: 'Notificaciones',
            subtitle: 'Configurar alertas push',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Las notificaciones se configuran automaticamente.')),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            icon: Icons.help_outline_rounded,
            title: 'Ayuda',
            subtitle: 'Preguntas frecuentes y soporte',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contactanos por email: soporte@alertatrip.com')),
              );
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD92D20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout_rounded),
              label: Text(l10n.logout, style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String code, String label, IconData icon) {
    final isSelected = localeNotifier.value.languageCode == code;
    return InkWell(
      onTap: () => _changeLanguage(code),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F5F1) : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F9D8D) : const Color(0xFFE0E6EF),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF0F9D8D) : const Color(0xFF98A2B3)),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600))),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: Color(0xFF0F9D8D)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFE3F5F1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF0F9D8D)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF667085), fontSize: 13)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF98A2B3)),
        onTap: onTap,
      ),
    );
  }
}