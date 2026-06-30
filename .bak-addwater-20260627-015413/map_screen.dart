import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  List _waters = [];
  String _spotFilter = 'all'; // all | public | friends
  double _zoom = 12;
  bool _checkedIn = false;
  bool _autoOn = true;
  bool _declined = false; // deze sessie "nee" gezegd → niet meer vragen
  bool _loading = true;
  Timer? _timer;

  // Snel naar een Europees land springen.
  static const Map<String, LatLng> _countries = {
    'Nederland': LatLng(52.2, 5.3), 'België': LatLng(50.6, 4.6), 'Duitsland': LatLng(51.2, 10.4),
    'Frankrijk': LatLng(46.6, 2.4), 'Spanje': LatLng(40.4, -3.7), 'Italië': LatLng(42.8, 12.5),
    'Portugal': LatLng(39.5, -8.0), 'Polen': LatLng(52.1, 19.4), 'Oostenrijk': LatLng(47.6, 14.1),
    'Zwitserland': LatLng(46.8, 8.2), 'Tsjechië': LatLng(49.8, 15.5), 'Hongarije': LatLng(47.2, 19.5),
    'Kroatië': LatLng(45.1, 15.5), 'Roemenië': LatLng(45.9, 25.0), 'Servië': LatLng(44.0, 21.0),
    'Verenigd Koninkrijk': LatLng(53.0, -1.5), 'Ierland': LatLng(53.4, -8.0),
    'Zweden': LatLng(62.0, 15.0), 'Noorwegen': LatLng(62.0, 9.0), 'Finland': LatLng(63.0, 26.0),
    'Denemarken': LatLng(56.0, 10.0),
  };

  @override
  void initState() { super.initState(); _init(); }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _init() async {
    final p = await loc.currentLocation();
    _center = LatLng(p.lat, p.lng);
    try { final st = await Api.get('/profile/settings'); _autoOn = !(st is Map && st['auto_checkin'] == false); } catch (_) {}
    await _load();
    setState(() => _loading = false);
    _maybeAskCheckin();
    _timer = Timer.periodic(const Duration(seconds: 150), (_) async { await _load(); _maybeAskCheckin(); });
  }

  // Detecteert of je ECHT bij water bent en vraagt dan of je vist — pas bij
  // "Ja" tel je (anoniem) mee. Voorkomt vals inchecken als je thuis bij water woont.
  Future<void> _maybeAskCheckin() async {
    if (!_autoOn || _checkedIn || _declined) return;
    try {
      final p = await loc.currentLocation();
      final w = await Api.get('/spots/check-water?lat=${p.lat}&lng=${p.lng}');
      final atWater = w is Map && w['water'] == true;
      if (!atWater || !mounted) return;
      final yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        title: Text(mui(ctx, 'checkin_here')),
        content: Text(mui(ctx, 'ask_fishing')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(mui(ctx, 'no'))),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.teal), onPressed: () => Navigator.pop(ctx, true), child: Text(mui(ctx, 'yes'))),
        ],
      ));
      if (yes == true) {
        await Api.post('/checkin', {'latitude': p.lat, 'longitude': p.lng});
        _checkedIn = true;
        await _load();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mui(context, 'checked_in'))));
      } else {
        _declined = true; // niet meer vragen deze sessie
      }
    } catch (_) {}
  }

  Future<void> _load() async {
    final lang = '?lang=${Provider.of<I18n>(context, listen: false).locale}';
    try { final s = await Api.get('/spots'); _spots = s is List ? s : (s['data'] ?? []); } catch (_) {}
    try { final c = await Api.get('/catches/map'); _catches = c is List ? c : (c['data'] ?? []); } catch (_) {}
    try { final b = await Api.get('/map/busyness'); _busy = b is Map ? (b['data'] ?? []) : (b is List ? b : []); } catch (_) {}
    try { final w = await Api.get('/waters$lang'); _waters = w is List ? w : (w['data'] ?? []); } catch (_) {}
    try { final ci = await Api.get('/checkin'); _checkedIn = ci is Map && ci['active'] == true; } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _toggleAuto() async {
    final newVal = !_autoOn;
    setState(() => _autoOn = newVal);
    try {
      await Api.put('/profile/settings', {'auto_checkin': newVal});
      if (newVal) { _declined = false; await _maybeAskCheckin(); } else { await Api.delete('/checkin'); _checkedIn = false; }
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mui(context, newVal ? 'auto_on_msg' : 'auto_off_msg'))));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : '$e')));
    }
  }

  Color _busyColor(String level) => level == 'high'
      ? const Color(0xFFEF4444)
      : level == 'medium' ? const Color(0xFFF59E0B) : const Color(0xFF22C55E);
  Color _waterColor(String level) => level == 'none' ? AppColors.shared : _busyColor(level);

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

  void _showWater(Map w) {
    final level = '${w['busyness']?['level'] ?? 'none'}';
    final count = w['busyness']?['count'] ?? 0;
    final species = (w['species'] is List) ? (w['species'] as List) : [];
    final sub = [w['region'], w['country']].where((x) => x != null && '$x'.isNotEmpty).join(' · ');
    final wlat = double.tryParse('${w['latitude']}') ?? 0, wlng = double.tryParse('${w['longitude']}') ?? 0;
    // Zichtbare stekken bij dit water (binnen ~3 km), filter-respecterend.
    final near = _spots.where((s) {
      final la = double.tryParse('${s['latitude']}'); final lo = double.tryParse('${s['longitude']}');
      return la != null && lo != null && (la - wlat).abs() < 0.03 && (lo - wlng).abs() < 0.03 && _spotPasses(s as Map);
    }).toList();

    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => DraggableScrollableSheet(
      expand: false, initialChildSize: 0.5, minChildSize: 0.3, maxChildSize: 0.9,
      builder: (_, scroll) => ListView(controller: scroll, padding: const EdgeInsets.all(20), children: [
        Row(children: [Icon(Icons.water, color: _waterColor(level)), const SizedBox(width: 8), Expanded(child: Text(w['name'] ?? '', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)))]),
        if (sub.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(sub, style: const TextStyle(color: Colors.black54))),
        const SizedBox(height: 10),
        Row(children: [Icon(Icons.local_fire_department, size: 16, color: _waterColor(level)), const SizedBox(width: 6),
          Text('${mui(context, 'busy')}: ${level == 'none' ? mui(context, 'busy_none') : busyLevelLabel(context, level)}${count > 0 ? ' ($count)' : ''}', style: const TextStyle(color: Colors.black87))]),
        if (species.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(mui(context, 'species_here'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: species.map((s) => Chip(label: Text('$s'), visualDensity: VisualDensity.compact, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)).toList()),
        ],
        const Divider(height: 24),
        Text('${mui(context, 'spots_at_water')} (${near.length})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
        if (near.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(mui(context, 'no_spots_here'), style: const TextStyle(color: Colors.black45, fontSize: 13)))
        else
          ...near.map((s) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.place, color: s['is_mine'] == true ? AppColors.teal : AppColors.shared),
            title: Text('${s['name'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(_privacyLabel(s['privacy']), style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () { Navigator.pop(context); _showSpot(s as Map); },
          )),
      ]),
    ));
  }

  void _showLegend() {
    Widget row(Widget icon, String text) => Padding(padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 30, child: Center(child: icon)), const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ]));
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(mui(ctx, 'legend_title')),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        row(const Icon(Icons.water, color: AppColors.shared, size: 22), mui(ctx, 'legend_water')),
        row(Row(mainAxisSize: MainAxisSize.min, children: const [
          Icon(Icons.circle, color: Color(0xFF22C55E), size: 10), Icon(Icons.circle, color: Color(0xFFF59E0B), size: 10), Icon(Icons.circle, color: Color(0xFFEF4444), size: 10),
        ]), mui(ctx, 'legend_busy')),
        row(const Icon(Icons.place, color: AppColors.teal, size: 22), mui(ctx, 'legend_spot')),
        row(const Icon(Icons.set_meal, color: Colors.orange, size: 20), mui(ctx, 'legend_catch')),
        const Divider(height: 18),
        row(const Icon(Icons.lightbulb_outline, size: 18, color: Colors.black45), mui(ctx, 'legend_tip')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
    ));
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

  Future<void> _showSpot(Map s) async {
    Map details = {};
    try { final d = await Api.get('/spots/${s['id']}/details'); if (d is Map) details = d; } catch (_) {}
    if (!mounted) return;
    final mine = s['is_mine'] == true;
    final owner = s['user'] is Map ? s['user']['username'] : null;
    final waterName = s['water'] is Map ? s['water']['name'] : s['water'];
    final photo = details['photo'];
    final species = (details['species'] is List) ? details['species'] as List : [];
    showModalBottomSheet(context: context, builder: (_) => Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(Icons.place, color: mine ? AppColors.teal : AppColors.shared), const SizedBox(width: 8), Expanded(child: Text(s['name'] ?? context.tr('map.spot'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))]),
      const SizedBox(height: 6),
      if (!mine && owner != null) Text('${context.tr('map.shared_by')} @$owner', style: const TextStyle(color: Colors.black54)),
      if (waterName != null) Text('${context.tr('map.water')}: $waterName', style: const TextStyle(color: Colors.black54)),
      if (s['notes'] != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text('${s['notes']}')),
      if (photo != null) Padding(padding: const EdgeInsets.only(top: 10), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network('$photo', height: 150, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()))),
      if (species.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(mui(context, 'species_here'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: species.map((sp) => Chip(label: Text('$sp'), visualDensity: VisualDensity.compact, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)).toList()),
      ],
      const SizedBox(height: 8),
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
    decoration: BoxDecoration(color: _busyColor(level).withValues(alpha: 0.88), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]),
    alignment: Alignment.center,
    child: Text('$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
  );

  bool _spotPasses(Map s) {
    if (_spotFilter == 'public') return s['privacy'] == 'public';
    if (_spotFilter == 'friends') return s['privacy'] == 'friends';
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final detail = _zoom >= 9.5; // stekken/vangsten pas tonen bij inzoomen (anti-wirwar)

    // Drukte-kleurzones over de kaart.
    final circles = _busy.where((b) => b['lat'] != null).map((b) {
      final level = '${b['level'] ?? 'low'}';
      final r = level == 'high' ? 1500.0 : level == 'medium' ? 1000.0 : 600.0;
      return CircleMarker(point: LatLng(double.parse('${b['lat']}'), double.parse('${b['lng']}')),
        radius: r, useRadiusInMeter: true, color: _busyColor(level).withValues(alpha: 0.22), borderColor: _busyColor(level).withValues(alpha: 0.6), borderStrokeWidth: 1.5);
    }).toList();

    final markers = <Marker>[
      // Bekende waters — kleur naar drukte.
      ..._waters.where((w) => w['latitude'] != null).map((w) => Marker(
        point: LatLng(double.parse('${w['latitude']}'), double.parse('${w['longitude']}')),
        width: 34, height: 34,
        child: GestureDetector(onTap: () => _showWater(w as Map), child: Icon(Icons.water, color: _waterColor('${w['busyness']?['level'] ?? 'none'}'), size: 28)))),
      // Drukte-badges met aantal.
      ..._busy.where((b) => b['lat'] != null).map((b) => Marker(
        point: LatLng(double.parse('${b['lat']}'), double.parse('${b['lng']}')),
        width: 44, height: 44,
        child: GestureDetector(onTap: () => _showBusy(b as Map), child: _busyBadge('${b['level'] ?? 'low'}', b['count'] ?? 0)))),
      // Stekken (gefilterd + alleen bij inzoomen).
      if (detail) ..._spots.where((s) => s['latitude'] != null && _spotPasses(s as Map)).map((s) => Marker(
        point: LatLng(double.parse('${s['latitude']}'), double.parse('${s['longitude']}')),
        width: 40, height: 40,
        child: GestureDetector(onTap: () => _showSpot(s as Map), child: Icon(Icons.place, color: s['is_mine'] == true ? AppColors.teal : AppColors.shared, size: 38)))),
      // Vangsten (alleen bij inzoomen).
      if (detail) ..._catches.where((c) => c['latitude'] != null).map((c) => Marker(
        point: LatLng(double.parse('${c['latitude']}'), double.parse('${c['longitude']}')),
        width: 30, height: 30,
        child: GestureDetector(onTap: () => _showCatch(c as Map), child: const Icon(Icons.set_meal, color: Colors.orange, size: 26)))),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('map.title')), actions: [
        IconButton(icon: const Icon(Icons.info_outline), tooltip: mui(context, 'legend_title'), onPressed: _showLegend),
        PopupMenuButton<String>(
          icon: const Icon(Icons.public),
          tooltip: mui(context, 'country'),
          onSelected: (c) => _map.move(_countries[c]!, 8),
          itemBuilder: (_) => _countries.keys.map((c) => PopupMenuItem(value: c, child: Text(c))).toList(),
        ),
        TextButton.icon(
          onPressed: _toggleAuto,
          icon: Icon(_autoOn ? Icons.location_on : Icons.location_off, size: 18, color: _checkedIn ? AppColors.mint : Colors.white),
          label: Text(mui(context, _autoOn ? 'auto_on_label' : 'auto_off_label'), style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.teal,
        onPressed: () => _addSpot(_map.camera.center),
        icon: const Icon(Icons.add_location_alt, color: Colors.white),
        label: Text(context.tr('map.spot_here'), style: const TextStyle(color: Colors.white)),
      ),
      body: Column(children: [
        // Filter voor stekken.
        SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(children: [
            for (final f in const ['all', 'public', 'friends'])
              Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(
                label: Text(mui(context, 'filter_$f')),
                selected: _spotFilter == f,
                onSelected: (_) => setState(() => _spotFilter = f),
                visualDensity: VisualDensity.compact,
              )),
            if (!detail) Padding(padding: const EdgeInsets.only(left: 4), child: Text(mui(context, 'spots_zoom_hint'), style: const TextStyle(fontSize: 11, color: Colors.black45))),
          ])),
        Expanded(child: FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: _center, initialZoom: 12,
            onTap: (_, pos) => _addSpot(pos),
            onPositionChanged: (pos, _) {
              final z = pos.zoom;
              final was = _zoom >= 9.5;
              _zoom = z;
              if ((z >= 9.5) != was) setState(() {});
            },
          ),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'nl.sbuilder.yessfish'),
            CircleLayer(circles: circles),
            MarkerLayer(markers: markers),
          ],
        )),
      ]),
    );
  }
}
