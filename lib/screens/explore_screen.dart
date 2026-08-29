import 'package:flutter/material.dart';
import '../data/city_airports.dart';
import '../services/location_service.dart';
import 'search_flights_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _locationService = LocationService();
  CityGroup? _detectedCity;
  bool _detectingLocation = true;

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  Future<void> _detectLocation() async {
    CityGroup? city;
    try {
      city = await _locationService
          .detectNearestCity()
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      print('[Location] no se pudo detectar la ciudad: ' + e.toString());
      city = null;
    }

    if (!mounted) return;
    setState(() {
      _detectedCity = city;
      _detectingLocation = false;
    });
  }

  Future<void> _openCitySearch(CityGroup city) async {
    if (_detectingLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Detectando tu ubicacion, espera un momento...')),
      );
      return;
    }

    final origin = _detectedCity ?? cityGroups.firstWhere(
      (c) => c.id == 'buenos_aires',
      orElse: () => cityGroups.first,
    );

    if (origin.id == city.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elegi un destino diferente a tu ciudad de origen.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchFlightsScreen(
          initialOrigin: origin,
          initialDestination: city,
          autoSearch: true,
        ),
      ),
    );
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
            'Toca cualquier destino para ver ofertas de vuelo desde tu ciudad.',
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
                          '${city.country} · ${airports.map((a) => a.iataCode).join(', ')}',
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
}
