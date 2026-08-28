import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/flight_alert.dart';
import '../models/flight_notification.dart';

class AlertService {
  final _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> setupNotifications() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) return;

    final token = await messaging.getToken(vapidKey: 'BMtfOU3U44zywoRAZFQDTW8sTl5l3S7FvqNbh4A9lGYgs8tdqrTeNAkRlRPARjIHIzWJDkSGaeScCvcLhFfwHHk');
    if (token == null) return;

    await _db.collection('users').doc(_uid).set({'fcmToken': token}, SetOptions(merge: true));
    messaging.onTokenRefresh.listen((newToken) {
      _db.collection('users').doc(_uid).set({'fcmToken': newToken}, SetOptions(merge: true));
    });
  }

  Future<String> saveAlert(FlightAlert alert) async {
    final doc = await _db.collection('flightAlerts').add(alert.toFirestore());
    return doc.id;
  }

  Stream<List<FlightAlert>> watchAlerts() {
    return _db.collection('flightAlerts')
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .map((s) => s.docs.map((d) => FlightAlert.fromFirestore(d.id, d.data())).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  Stream<List<FlightNotification>> watchNotifications() {
    return _db.collection('flightNotifications')
        .where('userId', isEqualTo: _uid)
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map((d) => FlightNotification.fromFirestore(d.id, d.data())).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  Future<void> deleteAlert(String id) => _db.collection('flightAlerts').doc(id).delete();
  Future<void> setActive(String id, bool active) => _db.collection('flightAlerts').doc(id).update({'isActive': active});
  Future<void> markRead(String id) => _db.collection('flightNotifications').doc(id).update({'read': true});
  Future<void> deleteNotification(String id) => _db.collection('flightNotifications').doc(id).delete();
}
