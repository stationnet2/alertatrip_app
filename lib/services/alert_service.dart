import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/flight_alert.dart';

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
    required this.departureDate,
    required this.returnDate,
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

class AlertService {
  final _db = FirebaseFirestore.instance;

  String get _userId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No hay usuario logueado.');
    }
    return user.uid;
  }

  bool get _isEmailVerified {
    return FirebaseAuth.instance.currentUser?.emailVerified ?? false;
  }

  /// Valida el límite de alertas leyendo appConfig y contando TODAS las alertas
  Future<void> _validateAlertLimit() async {
    // 1. Obtener plan del usuario
    final userDoc = await _db.collection('users').doc(_userId).get();
    final userData = userDoc.data() ?? {};
    String userPlan = userData['plan'] ?? 'free';

    // Verificar si el plan premium expiró
    if (userPlan == 'premium' && userData['planExpiresAt'] != null) {
      final expiresAt = (userData['planExpiresAt'] as Timestamp).toDate();
      if (expiresAt.isBefore(DateTime.now())) {
        userPlan = 'free';
      }
    }

    // 2. Obtener configuración global desde appConfig/system
    final configDoc = await _db.collection('appConfig').doc('system').get();
    final configData = configDoc.data() ?? {};
    
    final freePlan = configData['freePlan'] ?? {'maxAlerts': 2, 'name': 'Gratis'};
    final premiumPlan = configData['premiumPlan'] ?? {'maxAlerts': 12, 'name': 'Premium'};

    final planConfig = userPlan == 'premium' ? premiumPlan : freePlan;
    final int maxAlerts = planConfig['maxAlerts'] ?? 2;
    final String planName = planConfig['name'] ?? 'Gratis';

    // 3. Contar TODAS las alertas del usuario (activas e inactivas)
    final snapshot = await _db
        .collection('flightAlerts')
        .where('userId', isEqualTo: _userId)
        .count()
        .get();

    final int currentCount = snapshot.count ?? 0;

    // 4. Validar
    if (currentCount >= maxAlerts) {
      throw Exception('Llegaste al límite de $maxAlerts alertas de tu plan $planName. Eliminá una o actualizá tu plan.');
    }
  }

  /// Configura los permisos y tokens para las notificaciones push (FCM)
  Future<void> setupNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();
    
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return;
    }

    final token = await messaging.getToken(
      vapidKey: 'BMtfOU3U44zywoRAZFQDTW8sTl5l3S7FvqNbh4A9lGYgs8tdqrTeNAkRlRPARjIHIzWJDkSGaeScCvcLhFfwHHk',
    );
    if (token == null) return;

    await _db.collection('users').doc(user.uid).set(
      {
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    messaging.onTokenRefresh.listen((newToken) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _db.collection('users').doc(currentUser.uid).set(
          {
            'fcmToken': newToken,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    });
  }

  Future<void> requestTestNotification() async {
    await setupNotifications();
    await _db.collection('users').doc(_userId).set({
      'testNotificationRequested': true,
      'testNotificationRequestedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Guarda una alerta nueva con validaciones actualizadas
  Future<String> saveAlert({
    required String originCityId,
    required String destinationCityId,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool flexibleDates = false,
    double? maxPrice,
    double? initialPrice,
    int passengers = 1,
    double alertThresholdPercent = 15.0, // ✅ CORREGIDO: ahora es double
  }) async {
    if (!_isEmailVerified) {
      throw Exception('Debés verificar tu email antes de crear alertas. Revisá tu correo.');
    }

    // Validar límite usando la nueva lógica de appConfig
    await _validateAlertLimit();

    if (maxPrice != null && maxPrice < 20) {
      throw Exception('El precio mínimo para una alerta es de USD 20. Poné un precio realista.');
    }

    final alert = FlightAlert(
      id: '',
      userId: _userId,
      originCityId: originCityId,
      destinationCityId: destinationCityId,
      dateFrom: dateFrom,
      dateTo: dateTo,
      flexibleDates: flexibleDates,
      maxPrice: maxPrice,
      alertThresholdPercent: alertThresholdPercent,
      createdAt: DateTime.now(),
      lastKnownPrice: initialPrice,
      passengers: passengers,
    );

    final docRef = await _db.collection('flightAlerts').add(alert.toFirestore());
    return docRef.id;
  }

  Stream<List<FlightAlert>> watchMyAlerts() {
    return _db
        .collection('flightAlerts')
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
          final alerts = snapshot.docs
              .map((doc) => FlightAlert.fromFirestore(doc.id, doc.data()))
              .toList();
          alerts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return alerts;
        });
  }

  Future<void> deleteAlert(String alertId) {
    return _db.collection('flightAlerts').doc(alertId).delete();
  }

  Future<void> setActive(String alertId, bool isActive) {
    return _db.collection('flightAlerts').doc(alertId).update({'isActive': isActive});
  }

  Stream<List<FlightNotification>> watchMyNotifications({int limit = 30}) {
    return _db
        .collection('flightNotifications')
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map((doc) => FlightNotification.fromFirestore(doc.id, doc.data()))
              .toList();
          return notifications.take(limit).toList();
        });
  }

  Future<void> markNotificationRead(String notificationId) {
    return _db.collection('flightNotifications').doc(notificationId).update({
      'read': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteNotification(String notificationId) {
    return _db.collection('flightNotifications').doc(notificationId).delete();
  }
}