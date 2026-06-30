import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/location.dart' as loc;
import '../core/i18n.dart';
import '../core/map_l10n.dart';

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
  List _busy = [];
  bool _checkedIn = false;
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
    try { final b = await Api.get('/map/busyness'); _busy = b is Map ? (b['data'] ?? []) : (b is List ? b : []); } catch (_) {}
    try { final ci = await Api.get('/checkin'); _checkedIn = ci is Map && ci['active'] == true; } catch (_) {}
    if (mounted) setState(() {});
  }

  // Anonieme check-in aan/uit ("ik vis hier" / "ik ben weg").
  Future<void> _toggleCheckin() async {
    try {
      if (_checkedIn) {
        await Api.delete('/checkin');
      } else {
        final p = await loc.currentLocation();
        await Api.post('/checkin', {'latitude': p.lat, 'longitude': p.lng});
      }
      await _load();
      if (mounted && _checkedIn) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mui(context, 'checked_in'))));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : '$e')));
    }
  }

  Color _busyColor(String level) => level == 'high'
      ? const Color(0xFFEF4444)
      : level == 'medium' ? const Color(0xFFF59E0B) : const Color(0xFF22C55E);

  void _showBusy(Map cell) {
    final level = '${cell['level'] ?? 'low'}';
    showModalBottomSheet(context: context, builder: (_) => Padding(padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.local_fire_department, color: _busyColor(level)), const SizedBox(width: 8),
          Text('${mui(context, 'busy')}: ${busyLevelLabel(context, level)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
        const SizedBox(height: 8),
        Text('${cell['count'] ?? 0} ${mui(context, 'anglers_here')}', style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.lock_outline, size: 14, color: Colors.black38), const SizedBox(width: 6),
          Expanded(child: Text(mui(context, 'anonymous'), style: const TextStyle(color: Colors.black38, fontSize: 12)))]),
      ])));
  }

  Future<void> _addSpot(LatLng pos) async {
    final name = TextEditingController();
    String privacy = 'private';
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      title: Text(context.tr('map.add_spot')),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: InputDecoration(labelText: context.tr('map.spot_name'))),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(initialValue: privacy, decoration: InputDecoration(labelText: context.tr('map.visibility')),
          items: [
            DropdownMenuItem(value: 'private', child: Text(context.tr('map.private_only_me'))),
            DropdownMenuItem(value: 'friends', child: Text(context.tr('map.friends'))),
            DropdownMenuItem(value: 'public', child: Text(context.tr('map.public'))),
          ],
          onChanged: (v) => setS(() => privacy = v!)),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('map.cancel'))), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('map.save')))],
    )));
    if (ok != true || name.text.trim().isEmpty) return;
    try {
      await Api.post('/spots', {'name': name.text.trim(), 'latitude': pos.latitude, 'longitude': pos.longitude, 'privacy': privacy});
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : context.tr('map.place_on_water'))));
    }
  }

  String _privacyLabel(String? p) => p == 'public' ? context.tr('map.public') : p == 'friends' ? context.tr('map.friends') : context.tr('map.private');

  void _showSpot(Map s) {
    final mine = s['is_mine'] == true;
    final owner = s['user'] is Map ? s['user']['username'] : null;
    final waterName = s['water'] is Map ? s['water']['name'] : s['water'];
    showModalBottomSheet(context: context, builder: (_) => Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(Icons.place, color: mine ? AppColors.teal : AppColors.shared), const SizedBox(width: 8), Expanded(child: Text(s['name'] ?? context.tr('map.spot'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))]),
      const SizedBox(height: 6),
      if (!mine && owner != null) Text('${context.tr('map.shared_by')} @$owner', style: const TextStyle(color: Colors.black54)),
      if (waterName != null) Text('${context.tr('map.water')}: $waterName', style: const TextStyle(color: Colors.black54)),
      if (s['notes'] != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text('${s['notes']}')),
      const SizedBox(height: 6),
      Row(children: [const Icon(Icons.visibility, size: 14, color: Colors.black45), const SizedBox(width: 4), Text(_privacyLabel(s['privacy']), style: const TextStyle(color: Colors.black45, fontSize: 12))]),
    ])));
  }

  void _showCatch(Map c) {
    showModalBottomSheet(context: context, builder: (_) => Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.set_meal, color: Colors.orange), const SizedBox(width: 8), Expanded(child: Text(c['species'] ?? c['species_text'] ?? context.tr('map.catch'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))]),
      const SizedBox(height: 6),
      if (c['weight_kg'] != null) Text('${context.tr('map.weight')}: ${c['weight_kg']} kg', style: const TextStyle(color: Colors.black54)),
      if (c['length_cm'] != null) Text('${context.tr('map.length')}: ${c['length_cm']} cm', style: const TextStyle(color: Colors.black54)),
    ])));
  }

  Widget _busyBadge(String level, dynamic count) => Container(
    decoration: BoxDecoration(
      color: _busyColor(level).withValues(alpha: 0.88),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
    ),
    alignment: Alignment.center,
    child: Text('$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
  );

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final markers = <Marker>[
      ..._busy.where((b) => b['lat'] != null).map((b) => Marker(
        point: LatLng(double.parse('${b['lat']}'), double.parse('${b['lng']}')),
        width: 44, height: 44,
        child: GestureDetector(onTap: () => _showBusy(b as Map), child: _busyBadge('${b['level'] ?? 'low'}', b['count'] ?? 0)))),
      ..._spots.where((s) => s['latitude'] != null).map((s) => Marker(
        point: LatLng(double.parse('${s['latitude']}'), double.parse('${s['longitude']}')),
        width: 40, height: 40,
        child: GestureDetector(onTap: () => _showSpot(s as Map), child: Icon(Icons.place, color: s['is_mine'] == true ? AppColors.teal : AppColors.shared, size: 38)))),
      ..._catches.where((c) => c['latitude'] != null).map((c) => Marker(
        point: LatLng(double.parse('${c['latitude']}'), double.parse('${c['longitude']}')),
        width: 30, height: 30,
        child: GestureDetector(onTap: () => _showCatch(c as Map), child: const Icon(Icons.set_meal, color: Colors.orange, size: 26)))),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('map.title')), actions: [
        TextButton.icon(
          onPressed: _toggleCheckin,
          icon: Icon(_checkedIn ? Icons.where_to_vote : Icons.add_location_alt_outlined, size: 18, color: Colors.white),
          label: Text(_checkedIn ? mui(context, 'leave') : mui(context, 'checkin_here'), style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.teal,
        onPressed: () => _addSpot(_map.camera.center),
        icon: const Icon(Icons.add_location_alt, color: Colors.white),
        label: Text(context.tr('map.spot_here'), style: const TextStyle(color: Colors.white)),
      ),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(8), child: Text(context.tr('map.legend'), style: const TextStyle(fontSize: 12, color: Colors.black45))),
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
