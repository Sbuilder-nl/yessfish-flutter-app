import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/location.dart' as loc;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _map = MapController();
  LatLng _center = const LatLng(52.78, 6.12);
  List _spots = [];
  List _catches = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _init(); }

  Future<void> _init() async {
    final p = await loc.currentLocation();
    _center = LatLng(p.lat, p.lng);
    await _load();
    setState(() => _loading = false);
  }

  Future<void> _load() async {
    try { final s = await Api.get('/spots'); _spots = s is List ? s : (s['data'] ?? []); } catch (_) {}
    try { final c = await Api.get('/catches/map'); _catches = c is List ? c : (c['data'] ?? []); } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _addSpot(LatLng pos) async {
    final name = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Stek toevoegen'),
      content: TextField(controller: name, decoration: const InputDecoration(labelText: 'Naam van de stek')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuleren')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Opslaan'))],
    ));
    if (ok != true || name.text.trim().isEmpty) return;
    try {
      await Api.post('/spots', {'name': name.text.trim(), 'latitude': pos.latitude, 'longitude': pos.longitude, 'privacy': 'private'});
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plaats je stek op of langs het water.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final markers = <Marker>[
      ..._spots.where((s) => s['latitude'] != null).map((s) => Marker(
        point: LatLng(double.parse('${s['latitude']}'), double.parse('${s['longitude']}')),
        width: 40, height: 40,
        child: const Icon(Icons.place, color: AppColors.teal, size: 38))),
      ..._catches.where((c) => c['latitude'] != null).map((c) => Marker(
        point: LatLng(double.parse('${c['latitude']}'), double.parse('${c['longitude']}')),
        width: 30, height: 30,
        child: const Icon(Icons.set_meal, color: Colors.orange, size: 26))),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Stekkenkaart')),
      body: Column(children: [
        const Padding(padding: EdgeInsets.all(8), child: Text('Tik op het water om een stek toe te voegen. Groen = jouw stekken, oranje = vangsten.', style: TextStyle(fontSize: 12, color: Colors.black45))),
        Expanded(child: FlutterMap(
          mapController: _map,
          options: MapOptions(initialCenter: _center, initialZoom: 12, onTap: (_, pos) => _addSpot(pos)),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'nl.sbuilder.yessfish'),
            MarkerLayer(markers: markers),
          ],
        )),
      ]),
    );
  }
}
