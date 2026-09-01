import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/destination_service.dart';
import '../models/destination.dart';

class AdminDestinationsScreen extends StatefulWidget {
  const AdminDestinationsScreen({super.key});

  @override
  State<AdminDestinationsScreen> createState() => _AdminDestinationsScreenState();
}

class _AdminDestinationsScreenState extends State<AdminDestinationsScreen> {
  final _destinationService = DestinationService();
  final _displayNameCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _klookSvalueCtrl = TextEditingController();
  final _klookCityIdCtrl = TextEditingController();
  final _airportCodeCtrl = TextEditingController();
  final _airportNameCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();

  bool _isPrimary = true;
  bool _saving = false;
  List<DestinationAirport> _airports = [];

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _countryCtrl.dispose();
    _imageUrlCtrl.dispose();
    _klookSvalueCtrl.dispose();
    _klookCityIdCtrl.dispose();
    _airportCodeCtrl.dispose();
    _airportNameCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  void _addAirport() {
    if (_airportCodeCtrl.text.isEmpty || _airportNameCtrl.text.isEmpty) return;
    setState(() {
      _airports.add(DestinationAirport(
        code: _airportCodeCtrl.text.trim().toUpperCase(),
        name: _airportNameCtrl.text.trim(),
        isPrimary: _isPrimary,
        lat: double.tryParse(_latCtrl.text) ?? 0,
        lng: double.tryParse(_lngCtrl.text) ?? 0,
      ));
      _airportCodeCtrl.clear();
      _airportNameCtrl.clear();
      _latCtrl.clear();
      _lngCtrl.clear();
      _isPrimary = false;
    });
  }

  Future<void> _save() async {
    if (_displayNameCtrl.text.isEmpty || _countryCtrl.text.isEmpty || _airports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completá al menos el nombre, país y un aeropuerto.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final id = _displayNameCtrl.text.trim().toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
      await _destinationService.saveDestination(
        id: id,
        displayName: _displayNameCtrl.text.trim(),
        country: _countryCtrl.text.trim(),
        airports: _airports,
        imageUrl: _imageUrlCtrl.text.trim().isEmpty ? null : _imageUrlCtrl.text.trim(),
        klookSvalue: _klookSvalueCtrl.text.trim().isEmpty ? null : _klookSvalueCtrl.text.trim(),
        klookCityId: _klookCityIdCtrl.text.trim().isEmpty ? null : _klookCityIdCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Destino guardado correctamente.')),
      );
      _clearForm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _clearForm() {
    _displayNameCtrl.clear();
    _countryCtrl.clear();
    _imageUrlCtrl.clear();
    _klookSvalueCtrl.clear();
    _klookCityIdCtrl.clear();
    _airports = [];
    setState(() {});
  }

  Future<void> _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar destino?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _destinationService.deleteDestination(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Destino eliminado.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Administrar destinos', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFFF5F7FB),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildForm(),
          const SizedBox(height: 32),
          const Text('Destinos existentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          _buildDestinationsList(),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nuevo destino', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          TextField(
            controller: _displayNameCtrl,
            decoration: const InputDecoration(labelText: 'Nombre de la ciudad', hintText: 'Ej: Buenos Aires'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _countryCtrl,
            decoration: const InputDecoration(labelText: 'País', hintText: 'Ej: Argentina'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _imageUrlCtrl,
            decoration: const InputDecoration(labelText: 'URL de imagen (opcional)', hintText: 'https://...'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _klookSvalueCtrl,
                  decoration: const InputDecoration(labelText: 'Klook svalue (opcional)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _klookCityIdCtrl,
                  decoration: const InputDecoration(labelText: 'Klook city_id (opcional)'),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          const Text('Aeropuertos', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _airportCodeCtrl,
                  decoration: const InputDecoration(labelText: 'Código IATA', hintText: 'EZE'),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _airportNameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre', hintText: 'Ministro Pistarini'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _latCtrl,
                  decoration: const InputDecoration(labelText: 'Latitud', hintText: '-34.82'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _lngCtrl,
                  decoration: const InputDecoration(labelText: 'Longitud', hintText: '-58.53'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Checkbox(
                value: _isPrimary,
                onChanged: (v) => setState(() => _isPrimary = v ?? false),
              ),
              const Text('Primario'),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addAirport,
            icon: const Icon(Icons.add),
            label: const Text('Agregar aeropuerto'),
          ),
          if (_airports.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _airports.map((a) => Chip(
                label: Text('${a.code} ${a.isPrimary ? "(P)" : ""}'),
                onDeleted: () => setState(() => _airports.remove(a)),
              )).toList(),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Guardar destino', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('destinations').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Text('No hay destinos en Firestore todavía.', style: TextStyle(color: Color(0xFF667085)));
        }
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final airports = (data['airports'] as List<dynamic>? ?? []).length;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                title: Text(data['displayName'] ?? doc.id, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${data['country'] ?? ''} · $airports aeropuerto(s)'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFD92D20)),
                  onPressed: () => _delete(doc.id),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
