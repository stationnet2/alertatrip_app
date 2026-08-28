import 'package:flutter/material.dart';
import '../models/destination.dart';
import '../services/destination_service.dart';

class AdminDestinationsScreen extends StatefulWidget {
  const AdminDestinationsScreen({super.key});

  @override
  State<AdminDestinationsScreen> createState() => _AdminDestinationsScreenState();
}

class _AdminDestinationsScreenState extends State<AdminDestinationsScreen> {
  final _service = DestinationService();
  final _idCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _airportCodeCtrl = TextEditingController();
  final _airportNameCtrl = TextEditingController();

  Future<void> _save() async {
    final dest = Destination(
      id: _idCtrl.text.trim(),
      displayName: _nameCtrl.text.trim(),
      country: _countryCtrl.text.trim(),
      airports: [
        Airport(
          code: _airportCodeCtrl.text.trim().toUpperCase(),
          name: _airportNameCtrl.text.trim(),
          isPrimary: true,
          lat: 0,
          lng: 0,
        ),
      ],
      imageUrl: _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
    );
    await _service.saveDestination(dest);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Destino guardado')));
      _clear();
    }
  }

  void _clear() {
    _idCtrl.clear(); _nameCtrl.clear(); _countryCtrl.clear(); _imageCtrl.clear();
    _airportCodeCtrl.clear(); _airportNameCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administrar destinos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Agregar destino', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(controller: _idCtrl, decoration: const InputDecoration(labelText: 'ID (ej: buenos_aires)')),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
          TextField(controller: _countryCtrl, decoration: const InputDecoration(labelText: 'País')),
          TextField(controller: _imageCtrl, decoration: const InputDecoration(labelText: 'URL de imagen')),
          TextField(controller: _airportCodeCtrl, decoration: const InputDecoration(labelText: 'Código de aeropuerto')),
          TextField(controller: _airportNameCtrl, decoration: const InputDecoration(labelText: 'Nombre del aeropuerto')),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: const Text('Guardar destino')),
          const Divider(height: 40),
          const Text('Destinos existentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          StreamBuilder<List<Destination>>(
            stream: _service.watchDestinations(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const CircularProgressIndicator();
              return Column(
                children: snap.data!.map((d) => ListTile(
                  title: Text(d.displayName),
                  subtitle: Text(d.airports.map((a) => a.code).join(', ')),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _service.deleteDestination(d.id),
                  ),
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
