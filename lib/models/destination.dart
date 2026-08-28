class Destination {
  final String id;
  final String displayName;
  final String country;
  final List<Airport> airports;
  final String? imageUrl;
  final String? klookSvalue;
  final String klookStype;
  final String? klookCityId;

  const Destination({
    required this.id,
    required this.displayName,
    required this.country,
    required this.airports,
    this.imageUrl,
    this.klookSvalue,
    this.klookStype = 'city',
    this.klookCityId,
  });

  factory Destination.fromFirestore(String id, Map<String, dynamic> data) {
    final airportsData = (data['airports'] as List? ?? []);
    return Destination(
      id: id,
      displayName: data['displayName'] ?? id,
      country: data['country'] ?? '',
      airports: airportsData.map((a) => Airport.fromMap(a as Map<String, dynamic>)).toList(),
      imageUrl: data['imageUrl'],
      klookSvalue: data['klookSvalue'],
      klookStype: data['klookStype'] ?? 'city',
      klookCityId: data['klookCityId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'country': country,
      'airports': airports.map((a) => a.toMap()).toList(),
      'imageUrl': imageUrl,
      'klookSvalue': klookSvalue,
      'klookStype': klookStype,
      'klookCityId': klookCityId,
    };
  }

  String? get primaryAirportCode {
    final primary = airports.where((a) => a.isPrimary).firstOrNull;
    return primary?.code ?? airports.firstOrNull?.code;
  }
}

class Airport {
  final String code;
  final String name;
  final bool isPrimary;
  final double lat;
  final double lng;

  const Airport({
    required this.code,
    required this.name,
    this.isPrimary = false,
    required this.lat,
    required this.lng,
  });

  factory Airport.fromMap(Map<String, dynamic> map) {
    return Airport(
      code: map['code'] ?? '',
      name: map['name'] ?? map['code'] ?? '',
      isPrimary: map['isPrimary'] ?? false,
      lat: (map['lat'] as num?)?.toDouble() ?? 0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'isPrimary': isPrimary,
      'lat': lat,
      'lng': lng,
    };
  }
}
