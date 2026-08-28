import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/travelpayouts_service.dart';
import '../models/flight_alert.dart';
import '../data/city_airports.dart';
import 'create_alert_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _tp = TravelpayoutsService();
  final _originCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  DateTime? _departure;
  DateTime? _return;
  bool _roundTrip = false;
  bool _loading = false;
  List<FlightDeal> _results = [];
  String? _error;

  String? _originId;
  String? _destId;

  Future<void> _search() async {
    if (_originId == null || _destId == null) {
      setState(() => _error = 'Elegí origen y destino');
      return;
    }
    setState(() { _loading = true; _error = null; _results = []; });
    try {
      final originCode = primaryAirportCode(_originId!) ?? 'EZE';
      final destCode = primaryAirportCode(_destId!) ?? 'MAD';
      final deals = await _tp.searchFlights(
        originCode: originCode,
        destCode: destCode,
        departure: _departure,
        returnDate: _roundTrip ? _return : null,
        tripType: _roundTrip ? 'round_trip' : 'one_way',
      );
      setState(() => _results = deals);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickDate(bool isReturn) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isReturn) _return = picked; else _departure = picked;
      });
    }
  }

  void _openPicker(bool isOrigin) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _CityPicker(
        onSelect: (city) {
          Navigator.pop(ctx);
          setState(() {
            if (isOrigin) { _originId = city.id; _originCtrl.text = city.displayName; }
            else { _destId = city.id; _destCtrl.text = city.displayName; }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AlertaTrip'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSearchCard(),
          const SizedBox(height: 16),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          ..._results.map(_buildResultCard),
        ],
      ),
    );
  }

  Widget _buildSearchCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
            controller: _originCtrl,
            readOnly: true,
            onTap: () => _openPicker(true),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.flight_takeoff), hintText: 'Origen'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _destCtrl,
            readOnly: true,
            onTap: () => _openPicker(false),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.flight_land), hintText: 'Destino'),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: InkWell(
                onTap: () => _pickDate(false),
                child: InputDecorator(
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.calendar_today)),
                  child: Text(_departure == null ? 'Ida' : '${_departure!.day}/${_departure!.month}/${_departure!.year}'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (_roundTrip)
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(true),
                  child: InputDecorator(
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.calendar_today)),
                    child: Text(_return == null ? 'Vuelta' : '${_return!.day}/${_return!.month}/${_return!.year}'),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            FilterChip(
              label: const Text('Ida y vuelta'),
              selected: _roundTrip,
              onSelected: (v) => setState(() => _roundTrip = v),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _search,
              icon: const Icon(Icons.search),
              label: const Text('Buscar'),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildResultCard(FlightDeal deal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text('${deal.originAirportCode} → ${deal.destinationAirportCode}'),
        subtitle: Text('${deal.airline} · ${_fmt(deal.departureDate)}${deal.returnDate != null ? ' → ${_fmt(deal.returnDate!)}' : ''}'),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('${deal.currency} ${deal.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        onTap: () => _showDealDialog(deal),
      ),
    );
  }

  Future<void> _showDealDialog(FlightDeal deal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reservar vuelo'),
        content: const Text('Vas a salir de la app para continuar en Aviasales. El precio final se confirma allí.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continuar')),
        ],
      ),
    );
    if (confirmed == true && deal.affiliateLink.isNotEmpty) {
      await launchUrl(Uri.parse(deal.affiliateLink), mode: LaunchMode.externalApplication);
    }
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _CityPicker extends StatelessWidget {
  final void Function(CityGroup) onSelect;
  const _CityPicker({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (_, scrollCtrl) => ListView.builder(
        controller: scrollCtrl,
        itemCount: cityGroups.length,
        itemBuilder: (_, i) {
          final city = cityGroups[i];
          return ListTile(
            title: Text(city.displayName),
            subtitle: Text(city.country),
            onTap: () => onSelect(city),
          );
        },
      ),
    );
  }
}
