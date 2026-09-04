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
  
  // ✅ CORREGIDO: Variable de estado ahora es double para coincidir con el modelo
  double _alertThresholdPercent = 15.0;

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
      final errorMsg = l10n?.priceTooLow ?? 'El precio mínimo para una alerta es de USD 20.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
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
        alertThresholdPercent: _alertThresholdPercent, // ✅ Ahora coincide el tipo double
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
          
          // ✅ NUEVO: Selector visual de umbral de notificación
          const SizedBox(height: 16),
          _buildThresholdPicker(
            label: 'Avisarme si el precio baja un',
            value: _alertThresholdPercent,
            onTap: _pickThreshold,
          ),
          const SizedBox(height: 8),
          const Text(
            'Te notificaremos cuando encontremos una oferta que supere este descuento.',
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
                      _isLoggedIn ? (l10n?.saveAlert ?? 'Guardar alerta') : (l10n?.loginToSave ?? 'Iniciar sesión para guardar'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ CORREGIDO: El valor ahora es double
  Widget _buildThresholdPicker({required String label, required double value, required VoidCallback onTap}) {
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
            const Icon(Icons.percent_rounded, color: Color(0xFF0F9D8D)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Color(0xFF667085), fontSize: 12)),
                  Text(
                    '${value.toInt()}%', // Mostramos como entero en la UI para que se vea limpio (ej: "15%")
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0B3D37),
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

  // ✅ CORREGIDO: Las opciones y el diálogo ahora usan double
  Future<void> _pickThreshold() async {
    final options = [5.0, 10.0, 15.0, 20.0, 30.0];
    final descriptions = [
      '5% (Muy sensible)',
      '10% (Recomendado)',
      '15% (Estándar)',
      '20%',
      '30% (Solo grandes bajadas)'
    ];

    final selected = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Umbral de notificación'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (ctx, i) {
              final isSelected = options[i] == _alertThresholdPercent;
              return ListTile(
                title: Text(descriptions[i], style: const TextStyle(fontWeight: FontWeight.w700)),
                trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF0F9D8D)) : null,
                onTap: () => Navigator.pop(ctx, options[i]),
              );
            },
          ),
        ),
      ),
    );
    if (selected != null) {
      setState(() {
        _alertThresholdPercent = selected;
      });
    }
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