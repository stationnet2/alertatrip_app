import 'package:cloud_firestore/cloud_firestore.dart';

class FlightNotification {
  final String id;
  final String userId;
  final String alertId;
  final String title;
  final String body;
  final String origin;
  final String destination;
  final String originCityId;
  final String destinationCityId;
  final double price;
  final String currency;
  final String affiliateLink;
  final DateTime? departureDate;
  final DateTime? returnDate;
  final DateTime createdAt;
  final bool read;
  final bool isTest;

  const FlightNotification({
    required this.id,
    required this.userId,
    required this.alertId,
    required this.title,
    required this.body,
    required this.origin,
    required this.destination,
    required this.originCityId,
    required this.destinationCityId,
    required this.price,
    required this.currency,
    required this.affiliateLink,
    this.departureDate,
    this.returnDate,
    required this.createdAt,
    required this.read,
    required this.isTest,
  });

  factory FlightNotification.fromFirestore(String id, Map<String, dynamic> data) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }
    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }
    return FlightNotification(
      id: id,
      userId: (data['userId'] ?? '').toString(),
      alertId: (data['alertId'] ?? '').toString(),
      title: (data['title'] ?? 'Alerta de vuelo').toString(),
      body: (data['body'] ?? '').toString(),
      origin: (data['origin'] ?? '').toString(),
      destination: (data['destination'] ?? '').toString(),
      originCityId: (data['originCityId'] ?? '').toString(),
      destinationCityId: (data['destinationCityId'] ?? '').toString(),
      price: (data['price'] as num?)?.toDouble() ?? 0,
      currency: (data['currency'] ?? 'USD').toString(),
      affiliateLink: (data['affiliateLink'] ?? '').toString(),
      departureDate: parseNullableDate(data['departureDate']),
      returnDate: parseNullableDate(data['returnDate']),
      createdAt: parseDate(data['createdAt']),
      read: data['read'] == true,
      isTest: data['isTest'] == true,
    );
  }
}
