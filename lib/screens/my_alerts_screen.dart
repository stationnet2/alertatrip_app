import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../services/alert_service.dart';
import '../models/flight_alert.dart';
import '../data/city_airports.dart';
import 'auth_screen.dart';
import 'create_alert_screen.dart';

class MyAlertsScreen extends StatefulWidget {
  const MyAlertsScreen({super.key});

  @override
  State<MyAlertsScreen> createState() => _MyAlertsScreenState();
}

class _MyAlertsScreenState extends State<MyAlertsScreen> {
  final _alertService = AlertService();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: Text(l10n.alerts, style: const TextStyle(fontWeight: FontWeight.w900)),
          backgroundColor: const Color(0xFFF5F7FB),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.notifications_none_rounded, size: 64, color: Color(0xFF98A2B3)),
                const SizedBox(height: 16),
                Text(
                  l10n.needLoginForMyAlerts,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AuthScreen(
                          onSuccess: () {
                            Navigator.of(context).pop();
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                    child: Text(l10n.loginToContinue, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF5F7FB),
          title: Text(l10n.alerts, style: const TextStyle(fontWeight: FontWeight.w900)),
          bottom: const TabBar(
            indicatorColor: Color(0xFF0F9D8D),
            labelColor: Color(0xFF0B3D37),
            tabs: [
              Tab(text: 'Mis alertas'),
              Tab(text: 'Notificaciones'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAlertsTab(),
            _buildNotificationsTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0F9D8D),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nueva alerta', style: TextStyle(fontWeight: FontWeight.w800)),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateAlertScreen()),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertsTab() {
    return StreamBuilder<List<FlightAlert>>(
      stream: _alertService.watchMyAlerts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final alerts = snapshot.data ?? [];
        if (alerts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.notifications_none_rounded, size: 64, color: Color(0xFFD0D5DD)),
                const SizedBox(height: 16),
                const Text('No tenes alertas guardadas', style: TextStyle(color: Color(0xFF667085), fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('Crea una alerta para recibir notificaciones cuando baje el precio.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF667085))),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index];
            return _buildAlertCard(alert);
          },
        );
      },
    );
  }

  Widget _buildNotificationsTab() {
    return StreamBuilder<List<FlightNotification>>(
      stream: _alertService.watchMyNotifications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final notifications = snapshot.data ?? [];
        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mark_email_unread_outlined, size: 64, color: Color(0xFFD0D5DD)),
                const SizedBox(height: 16),
                const Text('Sin notificaciones todavia', style: TextStyle(color: Color(0xFF667085), fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('Cuando haya una oferta que coincida con tu alerta, vas a verla aca.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF667085))),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final n = notifications[index];
            return _buildNotificationCard(n);
          },
        );
      },
    );
  }

  Widget _buildAlertCard(FlightAlert alert) {
    final originName = cityName(alert.originCityId);
    final destName = cityName(alert.destinationCityId);
    final dateText = alert.flexibleDates
        ? 'Fechas flexibles'
        : alert.dateFrom != null
            ? '${_fmt(alert.dateFrom!)}${alert.dateTo != null ? ' -> ${_fmt(alert.dateTo!)}' : ''}'
            : 'Sin fecha especifica';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$originName -> $destName',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
                if (alert.maxPrice != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F5F1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '<= USD ${alert.maxPrice!.toStringAsFixed(0)}',
                      style: const TextStyle(color: Color(0xFF0B3D37), fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF98A2B3)),
                const SizedBox(width: 6),
                Text(dateText, style: const TextStyle(color: Color(0xFF667085), fontSize: 13)),
              ],
            ),
            if (alert.lastKnownPrice != null) ...[
              const SizedBox(height: 8),
              Text(
                'Ultimo precio visto: USD ${alert.lastKnownPrice!.toStringAsFixed(0)}',
                style: const TextStyle(color: Color(0xFF667085), fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF0F9D8D)),
                    onPressed: () => _alertService.setActive(alert.id, !alert.isActive),
                    icon: Icon(alert.isActive ? Icons.notifications_off_outlined : Icons.notifications_active_outlined),
                    label: Text(alert.isActive ? 'Pausar' : 'Activar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFD92D20)),
                    onPressed: () => _confirmDelete(alert),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Eliminar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(FlightNotification n) {
    final isUnread = !n.read;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnread ? const Color(0xFFE3F5F1) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          _alertService.markNotificationRead(n.id);
          _openBookingLink(n);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isUnread)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(color: Color(0xFF0F9D8D), shape: BoxShape.circle),
                    ),
                  Expanded(
                    child: Text(
                      n.title,
                      style: TextStyle(fontSize: 15, fontWeight: isUnread ? FontWeight.w900 : FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(n.body, style: const TextStyle(color: Color(0xFF667085), fontSize: 13)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0F9D8D)),
                      onPressed: () => _openBookingLink(n),
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('Ver oferta', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFD92D20)),
                    onPressed: () => _alertService.deleteNotification(n.id),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openBookingLink(FlightNotification n) async {
    final link = _bookingLinkForNotification(n);
    if (link.isEmpty) return;
    final uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _bookingLinkForNotification(FlightNotification n) {
    final link = n.affiliateLink.trim();
    if (link.isEmpty) return '';
    if (link.contains('tp.media')) return link;
    final encodedTarget = Uri.encodeComponent(link);
    return 'https://tp.media/r?campaign_id=100&marker=761958&p=4114&trs=567185&u=$encodedTarget';
  }

  Future<void> _confirmDelete(FlightAlert alert) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar alerta?'),
        content: Text('Se va a eliminar la alerta de ${cityName(alert.originCityId)} a ${cityName(alert.destinationCityId)}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed == true) {
      await _alertService.deleteAlert(alert.id);
    }
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}