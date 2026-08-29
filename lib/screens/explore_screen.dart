import 'package:flutter/material.dart';
import '../data/city_airports.dart';
import '../services/travelpayouts_service.dart';
import '../models/flight_alert.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _travelpayoutsService = TravelpayoutsService();
  List<FlightDeal>? _offers;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    try {
      final offers = await _travelpayoutsService.fetchSpecialOffers('EZE');
      if (!mounted) return;
      setState(() {
        _offers = offers;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Explorar destinos', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFFF5F7FB),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Destinos populares',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Toca cualquier destino para ver ofertas de vuelo.',
            style: TextStyle(color: Color(0xFF667085)),
          ),
          const SizedBox(height: 16),
          ...cityGroups.map((city) => _buildCityCard(city)),
        ],
      ),
    );
  }

  Widget _buildCityCard(CityGroup city) {
    final airports = city.airportCodes.map(airportByCode).whereType<Airport>().toList();
    final imageUrl = city.imageUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openCitySearch(city),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  imageUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 140,
                    color: const Color(0xFF0F9D8D),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          city.displayName,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${city.country} * ${airports.map((a) => a.iataCode).join(', ')}',
                          style: const TextStyle(color: Color(0xFF667085), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, color: Color(0xFF0F9D8D)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCitySearch(CityGroup city) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Buscando ofertas a ${city.displayName}...')),
    );
  }
}
