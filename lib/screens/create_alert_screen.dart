import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/flight_alert.dart';
import '../services/alert_service.dart';
import '../data/city_airports.dart';

class CreateAlertScreen extends StatefulWidget {
  const CreateAlertScreen({super.key});

  @override
  State<CreateAlertScreen> createState() => _CreateAlertScreenState();
}

class _CreateAlertScreenState extends State<CreateAlertScreen> {
  final _alertService = AlertService();
  String? _originId;
  String? _destId;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool _flexible = false;
  final _maxPriceCtrl = TextEditingController();
  final _passengersCtrl = TextEditingController(text: '1');
  final _thresholdCtrl = TextEditingController(text: '15');
  bool _loading = false;

  Future<void> _save() async {
    if (_originId == null || _destId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Elegí origen y destino')));
      return;
    }
    setState(() => _loading = true);
    try {
      final alert = FlightAlert(
        id: '',
        userId: FirebaseAuth.instance.currentUser!.uid,
        originCityId: _originId!,
        destinationCityId: _destId!,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        flexibleDates: _flexible,
        maxPrice: double.tryParse(_maxPriceCtrl.text),
        createdAt: DateTime.now(),
        passengers: int.tryParse(_passengersCtrl.text) ?? 1,
        alertThresholdPercent: (int.tryParse(_thresholdCtrl.text) ?? 15).toDouble(),
      );
      await _alertService.saveAlert(alert);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickDate(bool isTo) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => isTo ? _dateTo = picked : _dateFrom = picked);
  }

  void _pickCity(bool isOrigin) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView.builder(
        itemCount: cityGroups.length,
        itemBuilder: (_, i) => ListTile(
          title: Text(cityGroups[i].displayName),
          onTap: () {
            Navigator.pop(ctx);
            setState(() => isOrigin ? _originId = cityGroups[i].id : _destId = cityGroups[i].id);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear alerta')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: Text(_originId == null ? 'Origen' : cityName(_originId!)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickCity(true),
          ),
          ListTile(
            title: Text(_destId == null ? 'Destino' : cityName(_destId!)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickCity(false),
          ),
          SwitchListTile(
            title: const Text('Fechas flexibles'),
            value: _flexible,
            onChanged: (v) => setState(() => _flexible = v),
          ),
          if (!_flexible) ...[
            ListTile(
              title: Text(_dateFrom == null ? 'Fecha de ida' : '${_dateFrom!.day}/${_dateFrom!.month}/${_dateFrom!.year}'),
              onTap: () => _pickDate(false),
            ),
            ListTile(
              title: Text(_dateTo == null ? 'Fecha de vuelta (opcional)' : '${_dateTo!.day}/${_dateTo!.month}/${_dateTo!.year}'),
              onTap: () => _pickDate(true),
            ),
          ],
          TextField(
            controller: _maxPriceCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Precio máximo (USD)', prefixText: '\$'),
          ),
          TextField(
            controller: _passengersCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Pasajeros'),
          ),
          TextField(
            controller: _thresholdCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Umbral de alerta (%)', helperText: 'Te avisamos cuando baje este %'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 48,
            child: FilledButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Guardar alerta', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}
