// flight_alert.dart
//
// Representa una alerta configurada por el usuario: "avisame si baja
// el precio de Córdoba a Buenos Aires en agosto, por debajo de $80.000".
import 'package:cloud_firestore/cloud_firestore.dart';

class FlightAlert {
  final String id;
  final String userId;
  final String originCityId; // ej "cordoba"
  final String destinationCityId; // ej "buenos_aires"
  final DateTime? dateFrom; // null = fechas flexibles
  final DateTime? dateTo;
  final bool flexibleDates;
  final double? maxPrice; // null = "avisame de cualquier baja significativa"
  final int alertThresholdPercent; // ej 15 = avisar si baja 15% o más (Alineado con Web/Bot)
  final bool isActive;
  final DateTime createdAt;
  final double? lastKnownPrice; // para comparar y detectar bajas
  final int passengers; // cantidad de pasajeros (siempre >= 1)

  const FlightAlert({
    required this.id,
    required this.userId,
    required this.originCityId,
    required this.destinationCityId,
    this.dateFrom,
    this.dateTo,
    this.flexibleDates = false,
    this.maxPrice,
    this.alertThresholdPercent = 15, // Valor por defecto como int
    this.isActive = true,
    required this.createdAt,
    this.lastKnownPrice,
    this.passengers = 1,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'originCityId': originCityId,
      'destinationCityId': destinationCityId,
      'dateFrom': dateFrom != null ? Timestamp.fromDate(dateFrom!) : null,
      'dateTo': dateTo != null ? Timestamp.fromDate(dateTo!) : null,
      'flexibleDates': flexibleDates,
      'maxPrice': maxPrice,
      'alertThresholdPercent': alertThresholdPercent,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'lastKnownPrice': lastKnownPrice,
      'passengers': passengers,
    };
  }

  // ==========================================
  // FUNCIÓN AUXILIAR PARA PARSEAR FECHAS DE FORMA SEGURA
  // Soporta tanto Timestamp (nuevo) como String (alertas viejas)
  // ==========================================
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  factory FlightAlert.fromFirestore(String id, Map<String, dynamic> data) {
    return FlightAlert(
      id: id,
      userId: data['userId'] ?? '',
      originCityId: data['originCityId'] ?? data['origin'] ?? '', // Soporte legacy
      destinationCityId: data['destinationCityId'] ?? data['destination'] ?? '', // Soporte legacy
      dateFrom: _parseDate(data['dateFrom']),
      dateTo: _parseDate(data['dateTo']),
      flexibleDates: data['flexibleDates'] ?? false,
      maxPrice: (data['maxPrice'] as num?)?.toDouble(),
      // Maneja tanto int como double que venga de Firestore
      alertThresholdPercent: (data['alertThresholdPercent'] ?? 15).toInt(),
      isActive: data['isActive'] ?? true,
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      lastKnownPrice: (data['lastKnownPrice'] as num?)?.toDouble(),
      passengers: data['passengers'] ?? 1,
    );
  }
}

// Una oferta puntual encontrada, lista para mostrar y para generar
// el link de afiliado.
class FlightDeal {
  final String originAirportCode; // ej "COR"
  final String destinationAirportCode; // ej "AEP" (puede no ser el que el usuario esperaba)
  final double price;
  final String currency; // Código real devuelto por la API (ej "USD"), no un valor fijo
  final DateTime departureDate;
  final DateTime? returnDate; // null = solo ida
  final String airline;
  final String affiliateLink;
  final int transfers; // cantidad de escalas de ida (0 = vuelo directo)
  final int? durationMinutes; // duración total del viaje en minutos, si está disponible

  const FlightDeal({
    required this.originAirportCode,
    required this.destinationAirportCode,
    required this.price,
    required this.currency,
    required this.departureDate,
    this.returnDate,
    required this.airline,
    required this.affiliateLink,
    this.transfers = 0,
    this.durationMinutes,
  });

  bool get isRoundTrip => returnDate != null;
}