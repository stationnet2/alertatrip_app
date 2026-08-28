import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/flight_alert.dart';

class TravelpayoutsService {
  static const String _marker = '761958';
  static const String _workerUrl = 'https://api-alertatrip.descuentonadrian.workers.dev';
  static const String _currency = 'usd';

  Future<List<FlightDeal>> fetchSpecialOffers(String originCode) async {
    final uri = Uri.parse('$_workerUrl/special-offers').replace(queryParameters: {
      'origin': originCode,
      'currency': _currency,
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) return [];
    final json = jsonDecode(res.body);
    if (json['success'] != true) return [];
    final data = json['data'] as List? ?? [];
    return data.map((e) => _parseDeal(e)).toList();
  }

  Future<List<FlightDeal>> searchFlights({
    required String originCode,
    required String destCode,
    DateTime? departure,
    DateTime? returnDate,
    String tripType = 'one_way',
  }) async {
    final params = <String, String>{
      'origin': originCode,
      'destination': destCode,
      'currency': _currency,
      'trip_type': tripType,
    };
    if (departure != null) params['departure_at'] = _fmt(departure);
    if (returnDate != null) params['return_at'] = _fmt(returnDate);

    final uri = Uri.parse('$_workerUrl/search-flights').replace(queryParameters: params);
    final res = await http.get(uri);
    if (res.statusCode != 200) return [];
    final json = jsonDecode(res.body);
    if (json['success'] != true) return [];
    final data = json['data'] as List? ?? [];
    return data.map((e) => _parseDeal(e)).toList();
  }

  FlightDeal _parseDeal(Map<String, dynamic> e) {
    return FlightDeal(
      originAirportCode: e['origin_airport'] ?? '',
      destinationAirportCode: e['destination_airport'] ?? '',
      price: (e['price'] as num).toDouble(),
      currency: (e['currency'] ?? 'USD').toString().toUpperCase(),
      departureDate: DateTime.parse(e['departure_at']),
      returnDate: e['return_at'] != null ? DateTime.parse(e['return_at']) : null,
      airline: e['airline'] ?? '',
      affiliateLink: _buildLink(e['link']),
      transfers: e['transfers'] ?? 0,
    );
  }

  String _buildLink(String? rawLink) {
    if (rawLink == null || rawLink.isEmpty) return '';
    final uri = Uri.tryParse(rawLink);
    if (uri == null) return '';
    final params = Map<String, String>.from(uri.queryParameters);
    params['marker'] = _marker;
    params['locale'] = 'es';
    return Uri.parse('https://www.aviasales.com')
        .replace(path: uri.path, queryParameters: params)
        .toString();
  }

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
