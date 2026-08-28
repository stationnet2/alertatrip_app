import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/alert_service.dart';
import '../models/flight_alert.dart';
import '../models/flight_notification.dart';
import '../data/city_airports.dart';
import 'create_alert_screen.dart';

class MyAlertsScreen extends StatefulWidget {
  const MyAlertsScreen({super.key});

  @override
  State<MyAlertsScreen> createState() => _MyAlertsScreenState();
}

class _MyAlertsScreenState extends State<MyAlertsScreen> {
  final _service = AlertService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis alertas')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateAlertScreen())),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<FlightNotification>>(
        stream: _service.watchNotifications(),
        builder: (ctx, notifSnap) {
          final notifications = notifSnap.data ?? [];
          final unread = notifications.where((n) => !n.read && !n.isTest).length;

          return StreamBuilder<List<FlightAlert>>(
            stream: _service.watchAlerts(),
            builder: (ctx, alertSnap) {
              final alerts = alertSnap.data ?? [];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (unread > 0) _buildBanner(unread),
                  if (notifications.isNotEmpty) ...[
                    const Text('Novedades', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...notifications.take(5).map(_buildNotifCard),
                    const SizedBox(height: 16),
                  ],
                  const Text('Tus alertas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (alerts.isEmpty)
                    const Card(child: ListTile(title: Text('No tenés alertas'), subtitle: Text('Creá una para recibir notificaciones.')))
                  else
                    ...alerts.map(_buildAlertCard),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBanner(int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFD92D20), Color(0xFFFF6B35)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        const Icon(Icons.notifications_active, color: Colors.white),
        const SizedBox(width: 12),
        Expanded(child: Text(
          count == 1 ? '¡Tenés 1 alerta encontrada!' : '¡Tenés $count alertas encontradas!',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        )),
      ]),
    );
  }

  Widget _buildNotifCard(FlightNotification n) {
    final link = _buildLink(n);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text('${cityName(n.originCityId)} → ${cityName(n.destinationCityId)}'),
        subtitle: Text('${n.currency} ${n.price.toStringAsFixed(0)} · ${_fmt(n.createdAt)}'),
        trailing: n.read ? null : const Icon(Icons.circle, color: Colors.red, size: 12),
        onTap: () async {
          await _service.markRead(n.id);
          if (link.isNotEmpty) {
            await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
          }
        },
      ),
    );
  }

  Widget _buildAlertCard(FlightAlert a) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('${cityName(a.originCityId)} → ${cityName(a.destinationCityId)}'),
        subtitle: Text('Tope: ${a.maxPrice?.toStringAsFixed(0) ?? 'Sin tope'} USD · ${a.passengers} pasajero(s)'),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Switch(value: a.isActive, onChanged: (v) => _service.setActive(a.id, v)),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _service.deleteAlert(a.id)),
        ]),
      ),
    );
  }

  String _buildLink(FlightNotification n) {
    final o = (n.origin.isNotEmpty ? n.origin : primaryAirportCode(n.originCityId) ?? 'EZE').toUpperCase();
    final d = (n.destination.isNotEmpty ? n.destination : primaryAirportCode(n.destinationCityId) ?? 'MAD').toUpperCase();
    final ddmm = (DateTime dt) => '${dt.day.toString().padLeft(2, '0')}${dt.month.toString().padLeft(2, '0')}';
    if (n.departureDate != null && n.returnDate != null) {
      return 'https://www.aviasales.com/search/$o${ddmm(n.departureDate!)}$d${ddmm(n.returnDate!)}1?marker=761958&locale=es';
    } else if (n.departureDate != null) {
      return 'https://www.aviasales.com/search/$o${ddmm(n.departureDate!)}$d1?marker=761958&locale=es';
    }
    return 'https://www.aviasales.com/search/$o${d}1?marker=761958&locale=es';
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
