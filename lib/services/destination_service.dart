import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/destination.dart';

class DestinationService {
  final _db = FirebaseFirestore.instance;

  Stream<List<Destination>> watchDestinations() {
    return _db.collection('destinations').snapshots().map(
      (s) => s.docs.map((d) => Destination.fromFirestore(d.id, d.data())).toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName)),
    );
  }

  Future<void> saveDestination(Destination dest) async {
    await _db.collection('destinations').doc(dest.id).set(dest.toFirestore());
  }

  Future<void> deleteDestination(String id) async {
    await _db.collection('destinations').doc(id).delete();
  }
}
