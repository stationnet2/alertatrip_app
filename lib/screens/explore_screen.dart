import 'package:flutter/material.dart';
import '../services/travelpayouts_service.dart';
import '../services/destination_service.dart';
import '../models/destination.dart';
import '../data/city_airports.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explorar')),
      body: StreamBuilder<List<Destination>>(
        stream: DestinationService().watchDestinations(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final dests = snap.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: dests.length,
            itemBuilder: (_, i) {
              final d = dests[i];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (d.imageUrl != null)
                      Image.network(d.imageUrl!, height: 140, width: double.infinity, fit: BoxFit.cover),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(d.country, style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            children: d.airports.map((a) => Chip(label: Text(a.code), visualDensity: VisualDensity.compact)).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
