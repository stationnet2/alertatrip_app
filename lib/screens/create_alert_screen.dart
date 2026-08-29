import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import '../services/alert_service.dart';
import '../data/city_airports.dart';
import 'auth_screen.dart';

class CreateAlertScreen extends StatefulWidget {
  final String? originCityId;
  final String? destinationCityId;
  final DateTime? departureDate;
  final DateTime? returnDate;

  const CreateAlertScreen({
    super.key,
    this.originCityId,
    this.destinationCityId,
    this.departureDate,
    this.returnDate,
  });

  @override
  State<CreateAlertScreen> createState() => _CreateAlertScreenState();
}

class _CreateAlertScreenState extends State<CreateAlertScreen> {
  final _alertService = AlertService();
  final _maxPriceCtrl = TextEditingController();

  String? _origin;
  String? _destination;
  DateTime? _departureDate;
  DateTime? _returnDate;
  bool _flexibleDates = false;
  bool _saving = false;
  bool _roundTrip = true;

  @override
  void initState() {
    super.initState();
    _origin = widget.originCityId;
    _destination = widget.destinationCityId;
    _departureDate = widget.departureDate;
    _returnDate = widget.returnDate;
  }

  @override
  void dispose() {
    _maxPriceCtrl.dispose();
    super.dispose();
  }

  bool get _canSave {
    final hasDates = _flexibleDates ||
        (_roundTrip
            ? (_departureDate != null && _returnDate != null)
            : _departureDate != null);
    return _origin != null && _destination != null && _origin != _destination && hasDates;
  }

  bool get _isLoggedIn => FirebaseAuth.instance.currentUser != null;

  Future<void> _saveAlert() async {
    if (!_isLoggedIn) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      if (FirebaseAuth.instance.currentUser == null) return;
    }

    final maxPrice = double.tryParse(_maxPriceCtrl.text);
    if (maxPrice != null && maxPrice < 20) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.priceTooLow)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _alertService.saveAlert(
        originCityId: _origin!,
        destinationCityId: _destination!,
        dateFrom: _flexibleDates ? null : _departureDate,
        dateTo: _flexibleDates ? null : (_roundTrip ? _returnDate : null),
        flexibleDates: _flexibleDates,
        maxPrice: maxPrice,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alerta guardada correctamente.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        title: const Text('Crear alerta', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCityPicker(
            label: 'Origen',
            value: _origin,
            onTap: () => _pickCity(isOrigin: true),
          ),
          const SizedBox(height: 12),
          _buildCityPicker(
            label: 'Destino',
            value: _destination,
            onTap: () => _pickCity(isOrigin: false),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Ida y vuelta'),
                  selected: _roundTrip,
                  onSelected: (v) => setState(() => _roundTrip = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Solo ida'),
                  selected: !_roundTrip,
                  onSelected: (v) => setState(() => _roundTrip = !v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Fechas flexibles', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Recibir alertas para cualquier fecha'),
            value: _flexibleDates,
            activeColor: const Color(0xFF0F9D8D),
            onChanged: (v) => setState(() => _flexibleDates = v),
          ),
          if (!_flexibleDates) ...[
            const SizedBox(height: 12),
            _buildDatePicker(
              label: 'Fecha de salida',
              value: _departureDate,
              onTap: () => _pickDate(isDeparture: true),
            ),
            if (_roundTrip) ...[
              const SizedBox(height: 12),
              _buildDatePicker(
                label: 'Fecha de regreso',
                value: _returnDate,
                onTap: () => _pickDate(isDeparture: false),
              ),
            ],
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _maxPriceCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Precio maximo (USD)',
              hintText: 'Ej: 500',
              prefixIcon: Icon(Icons.attach_money_rounded),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'El precio minimo permitido es USD 20.',
            style: TextStyle(color: Color(0xFF667085), fontSize: 12),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: (_canSave && !_saving) ? _saveAlert : null,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      _isLoggedIn ? l10n.saveAlert : l10n.loginToSave,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityPicker({required String label, required String? value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E6EF)),
        ),
        child: Row(
          children: [
            Icon(
              label == 'Origen' ? Icons.flight_takeoff_rounded : Icons.flight_land_rounded,
              color: const Color(0xFF0F9D8D),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Color(0xFF667085), fontSize: 12)),
                  Text(
                    value != null ? cityName(value) : 'Seleccionar ciudad',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: value != null ? const Color(0xFF0B3D37) : const Color(0xFF98A2B3),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF98A2B3)),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker({required String label, required DateTime? value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E6EF)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: Color(0xFF0F9D8D)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Color(0xFF667085), fontSize: 12)),
                  Text(
                    value != null ? '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}' : 'Seleccionar fecha',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: value != null ? const Color(0xFF0B3D37) : const Color(0xFF98A2B3),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF98A2B3)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCity({required bool isOrigin}) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isOrigin ? 'Seleccionar origen' : 'Seleccionar destino'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: cityGroups.length,
            itemBuilder: (ctx, i) {
              final city = cityGroups[i];
              return ListTile(
                title: Text(city.displayName, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(city.country),
                onTap: () => Navigator.pop(ctx, city.id),
              );
            },
          ),
        ),
      ),
    );
    if (selected != null) {
      setState(() {
        if (isOrigin) {
          _origin = selected;
        } else {
          _destination = selected;
        }
      });
    }
  }

  Future<void> _pickDate({required bool isDeparture}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale('es'),
    );
    if (picked != null) {
      setState(() {
        if (isDeparture) {
          _departureDate = picked;
          if (_returnDate != null && _returnDate!.isBefore(picked)) {
            _returnDate = null;
          }
        } else {
          _returnDate = picked;
        }
      });
    }
  }
}
