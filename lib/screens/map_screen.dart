import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import '../core/api.dart';
import '../core/units.dart';
import '../core/analytics.dart';
import '../core/auth.dart';
import '../core/config.dart';
import '../core/location.dart' as loc;
import '../core/i18n.dart';
import '../core/map_l10n.dart';
import 'catch_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/photo_viewer.dart';
import '../widgets/fish_rating.dart';

class MapScreen extends StatefulWidget {
  final double? focusLat;
  final double? focusLng;
  final int? focusWaterId; // moderator: open direct dit water (intekenen-aanvraag)
  const MapScreen({super.key, this.focusLat, this.focusLng, this.focusWaterId});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const double _kMinZoom = 8.0; // harde uitzoom-grens (één bron: MapOptions + de muur in onPositionChanged)
  final _map = MapController();
  LatLng _center = const LatLng(52.78, 6.12);
  LatLng? _userPos; // "hier ben jij" — alleen bij een echte GPS-fix
  String? _placing; // null | 'water' | 'spot' — plaats-modus (richtkruis verschijnt alleen dan)
  List _spots = [];
  List _catches = [];
  List _busy = [];
  List _waters = [];
  List _permitRegions = []; // vergunning-zones (gekleurd per vergunning)
  List _activeSpots = []; // stekken van het aangetikte water — als pins op de kaart
  dynamic _activeWaterId; // welk water nu open/getikt is — om pins te herberekenen bij filterwissel
  String _spotFilter = 'all'; // all | public | friends
  // Watervorm (omtrek) tonen + intekenen/bewerken (moderator).
  List<LatLng> _selWaterPoly = []; // opgeslagen vorm van het geselecteerde water
  dynamic _shapeWaterId;           // water waarvan we de vorm tonen/bewerken
  bool _editShape = false;
  List<LatLng> _draftPts = [];     // punten tijdens intekenen
  String _shapeMsg = '';
  double _zoom = 14;
  bool _checkedIn = false;
  bool _autoOn = true;
  bool _declined = false; // deze sessie "nee" gezegd → niet meer vragen
  bool _loading = true;
  Timer? _timer;
  Timer? _moveDebounce;

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

  // App-landnaam (NL) -> DB-landnaam (EN) voor de vergunning-regio's.
  static const Map<String,String> _countryEn = {
    'Nederland':'Netherlands','België':'Belgium','Duitsland':'Germany','Frankrijk':'France',
    'Spanje':'Spain','Polen':'Poland','Verenigd Koninkrijk':'United Kingdom','Ierland':'Ireland',
    'Italië':'Italy','Portugal':'Portugal','Oostenrijk':'Austria','Zwitserland':'Switzerland',
  };

  @override
  void initState() { super.initState(); _init(); }

  @override
  void dispose() { _timer?.cancel(); _moveDebounce?.cancel(); super.dispose(); }

  Future<void> _init() async {
    final p = await loc.currentLocation();
    _center = LatLng(p.lat, p.lng);
    if (p.isReal) _userPos = LatLng(p.lat, p.lng);
    try { final st = await Api.get('/profile/settings'); _autoOn = !(st is Map && st['auto_checkin'] == false); } catch (_) {}
    await _load();
    setState(() => _loading = false);
    if (widget.focusWaterId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openWaterById(widget.focusWaterId!));
    } else if (widget.focusLat != null && widget.focusLng != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) { try { _map.move(LatLng(widget.focusLat!, widget.focusLng!), 15); } catch (_) {} });
    } else { _maybeShowHelpOnce(); }
    _maybeAskCheckin();
    _timer = Timer.periodic(const Duration(seconds: 150), (_) async { await _load(); _maybeAskCheckin(); });
  }

  // Plaats zoeken (heel Europa) — autocomplete via /geocode, met voorkeur voor de huidige kaartlocatie.
  Future<void> _openPlaceSearch() async {
    final loc8 = Provider.of<I18n>(context, listen: false).locale;
    await showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        final ctrl = TextEditingController();
        List results = [];
        bool loading = false;
        Timer? deb;
        return StatefulBuilder(builder: (ctx, setS) {
          void run(String q) {
            deb?.cancel();
            if (q.trim().length < 2) { setS(() { results = []; loading = false; }); return; }
            setS(() => loading = true);
            deb = Timer(const Duration(milliseconds: 350), () async {
              try {
                final c = _map.camera.center;
                final r = await Api.get('/geocode?q=${Uri.encodeQueryComponent(q.trim())}&lang=$loc8&lat=${c.latitude}&lon=${c.longitude}');
                if (!ctx.mounted) return;
                setS(() { results = r is List ? r : []; loading = false; });
              } catch (_) { if (ctx.mounted) setS(() => loading = false); }
            });
          }
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 12, left: 12, right: 12, top: 12),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                autofocus: true, controller: ctrl, textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: mui(ctx, 'search_place'),
                  border: const OutlineInputBorder(),
                  suffixIcon: loading
                    ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                    : null,
                ),
                onChanged: run,
              ),
              const SizedBox(height: 8),
              Flexible(child: ListView(shrinkWrap: true, children: [
                for (final p in results)
                  ListTile(
                    leading: const Icon(Icons.place_outlined, color: AppColors.teal),
                    title: Text('${p['name']}'),
                    subtitle: p['label'] != null ? Text('${p['label']}', maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                    onTap: () {
                      final la = double.tryParse('${p['lat']}'); final lo = double.tryParse('${p['lng']}');
                      Navigator.pop(ctx);
                      if (la != null && lo != null) { _map.move(LatLng(la, lo), 12); _loadWaters(); }
                    },
                  ),
              ])),
            ]),
          );
        });
      },
    );
  }

  // "Terug naar mijn locatie" — verse GPS-fix, kaart erheen + waters herladen.
  Future<void> _centerOnUser() async {
    final p = await loc.currentLocation();
    if (!mounted) return;
    if (p.isReal) {
      setState(() => _userPos = LatLng(p.lat, p.lng));
      _map.move(LatLng(p.lat, p.lng), 14);
      _loadWaters();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mui(context, 'locate_no_gps'))));
    }
  }

  // Detecteert of je ECHT bij water bent en vraagt dan of je vist — pas bij
  // "Ja" tel je (anoniem) mee. Voorkomt vals inchecken als je thuis bij water woont.
  Future<void> _maybeAskCheckin() async {
    if (!_autoOn || _checkedIn || _declined) return;
    try {
      final p = await loc.currentLocation();
      // Geen betrouwbare GPS-fix (bv. wifi/zendmast i.p.v. GPS) → niet (vals) inchecken.
      if (!p.isReal || (p.accuracy ?? 9999) > 75) return;
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
        await Api.post('/checkin', {'latitude': p.lat, 'longitude': p.lng, 'accuracy': p.accuracy});
        Analytics.log('checkin');
        _checkedIn = true;
        await _load();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mui(context, 'checked_in'))));
      } else {
        _declined = true; // niet meer vragen deze sessie
      }
    } on ApiException catch (e) {
      // bv. niet bij water / te onnauwkeurig → meertalige melding van de server tonen.
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {}
  }

  Future<void> _load() async {
    try { final s = await Api.get('/spots'); _spots = s is List ? s : (s['data'] ?? []); } catch (_) {}
    try { final c = await Api.get('/catches/map'); _catches = c is List ? c : (c['data'] ?? []); } catch (_) {}
    try { final b = await Api.get('/map/busyness'); _busy = b is Map ? (b['data'] ?? []) : (b is List ? b : []); } catch (_) {}
    try { final ci = await Api.get('/checkin'); _checkedIn = ci is Map && ci['active'] == true; } catch (_) {}
    if (mounted) setState(() {});
  }

  // Waters voor het zichtbare gebied (bbox) in de ingestelde taal.
  Future<void> _loadWaters() async {
    // Heel ver uit (zoom < 5): niet herladen — clustering houdt de laatst geladen waters
    // overzichtelijk; we WISSEN ze niet meer (anders verdwenen ze en kwamen niet terug).
    if (_zoom < 5) return;
    try {
      final loc8 = Provider.of<I18n>(context, listen: false).locale;
      final b = _map.camera.visibleBounds;
      final w = await Api.get('/waters?lang=$loc8&cluster=1&minLat=${b.south}&minLng=${b.west}&maxLat=${b.north}&maxLng=${b.east}');
      _waters = w is List ? w : (w['data'] ?? []);
      if (mounted) setState(() {});
    } catch (_) {}
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

  Future<void> _requestShape(dynamic id) async {
    final messenger = ScaffoldMessenger.of(context);
    final okMsg = mui(context, 'shape_requested_ok');
    final failMsg = mui(context, 'gps_fail');
    try { await Api.post('/waters/$id/request-shape', {}); messenger.showSnackBar(SnackBar(content: Text(okMsg))); }
    catch (e) { messenger.showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : failMsg))); }
  }

  // Plaats-modus afronden: water/stek op het kaartmidden (of GPS) → opent het invul-venster.
  Future<void> _confirmPlacement(bool useGps) async {
    final mode = _placing;
    if (mode == null) return;
    LatLng target;
    if (useGps) {
      final messenger = ScaffoldMessenger.of(context);
      final failMsg = mui(context, 'gps_fail');
      final p = await loc.currentLocation();
      if (!p.isReal || (p.accuracy ?? 9999) > 75) { messenger.showSnackBar(SnackBar(content: Text(failMsg))); return; }
      target = LatLng(p.lat, p.lng);
    } else {
      target = _map.camera.center;
    }
    if (!mounted) return;
    setState(() => _placing = null);
    if (mode == 'water') { _addWater(target); } else { _addSpot(target); }
  }

  // Moderator: bestaand water bewerken (naam, type, betaalwater + boekingslink).
  void _editWater(Map w) {
    final nameC = TextEditingController(text: '${w['name'] ?? ''}');
    final bookC = TextEditingController(text: '${w['booking_url'] ?? ''}');
    const types = ['meer', 'rivier', 'kanaal', 'zee', 'vijver', 'overig'];
    String type = types.contains('${w['type']}') ? '${w['type']}' : 'overig';
    bool paid = w['is_paid'] == true;
    const permits = ['onbekend','landelijk','club','vrij','betaald','verboden','fiskfergunning','nho','onduidelijk'];
    String permit = permits.contains('${w['permit_type']}') ? '${w['permit_type']}' : 'onbekend';
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (sheetCtx) => StatefulBuilder(builder: (sheetCtx, setS) => Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 16),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(mui(sheetCtx, 'water_edit'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        TextField(controller: nameC, decoration: InputDecoration(labelText: mui(sheetCtx, 'water_name'), border: const OutlineInputBorder())),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: type,
          decoration: InputDecoration(labelText: mui(sheetCtx, 'water_type'), border: const OutlineInputBorder()),
          items: [for (final t in types) DropdownMenuItem(value: t, child: Text(mui(sheetCtx, 'type_$t')))],
          onChanged: (v) => setS(() => type = v ?? type)),
        const SizedBox(height: 4),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: permit,
          decoration: InputDecoration(labelText: mui(sheetCtx, 'permit_pick'), border: const OutlineInputBorder()),
          items: [for (final pt in permits) DropdownMenuItem(value: pt, child: Text(mui(sheetCtx, 'permit_$pt')))],
          onChanged: (v) => setS(() => permit = v ?? permit)),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(mui(sheetCtx, 'water_is_paid')), value: paid, onChanged: (v) => setS(() => paid = v)),
        if (paid) TextField(controller: bookC, keyboardType: TextInputType.url,
          decoration: InputDecoration(labelText: mui(sheetCtx, 'water_booking_url'), hintText: 'https://...', border: const OutlineInputBorder())),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(sheetCtx), child: Text(context.tr('map.cancel')))),
          const SizedBox(width: 10),
          Expanded(child: FilledButton(onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            final okMsg = mui(sheetCtx, 'water_saved'), failMsg = mui(sheetCtx, 'save_failed');
            if (nameC.text.trim().isEmpty) return;
            try {
              await Api.put('/admin/waters/${w['id']}', {
                'name': nameC.text.trim(),
                'type': type,
                'is_paid': paid,
                'booking_url': paid ? bookC.text.trim() : null,
                'permit_type': permit,
              });
              if (sheetCtx.mounted) Navigator.pop(sheetCtx);
              await _load();
              messenger.showSnackBar(SnackBar(content: Text(okMsg)));
            } catch (e) {
              messenger.showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : failMsg)));
            }
          }, child: Text(context.tr('map.save')))),
        ]),
      ])),
    )));
  }

  bool _inNL(Map w) {
    final la = double.tryParse('${w['latitude']}') ?? 0, lo = double.tryParse('${w['longitude']}') ?? 0;
    return la > 50.7 && la < 53.6 && lo > 3.2 && lo < 7.3;
  }

  // Open een water op id (deeplink/moderatie): kaart erheen + info-venster + zones van dat land.
  Future<void> _openWaterById(int id) async {
    try {
      final full = await Api.get('/waters/$id');
      if (full is! Map) return;
      final la = (full['latitude'] is num) ? (full['latitude'] as num).toDouble() : double.tryParse('${full['latitude']}');
      final lo = (full['longitude'] is num) ? (full['longitude'] as num).toDouble() : double.tryParse('${full['longitude']}');
      if (la != null && lo != null) { try { _map.move(LatLng(la, lo), 15); } catch (_) {} }
      if (full['country'] != null) _loadRegions('${full['country']}');
      await _loadWaters();
      if (mounted) _showWater(Map<String, dynamic>.from(full));
    } catch (_) {}
  }

  void _showWater(Map w) {
    final level = '${w['busyness']?['level'] ?? 'none'}';
    final count = w['busyness']?['count'] ?? 0;
    final species = (w['species'] is List) ? (w['species'] as List) : [];
    final sub = [w['region'], w['country']].where((x) => x != null && '$x'.isNotEmpty).join(' · ');
    // Stek-pins van dit water tonen + METEEN het info-venster openen (niet wachten op netwerk).
    final near = _spotsForWater(w['id']);
    setState(() { _activeWaterId = w['id']; _activeSpots = near; _shapeWaterId = w['id']; _selWaterPoly = []; _editShape = false; });
    // Vorm + aanvraag-info laden ná het openen; werkt de knoppen bij via 'meta'.
    final meta = ValueNotifier<Map<String, dynamic>?>(w['polygon'] != null ? {'has_shape': true, 'count': 0} : null);
    () async {
      try {
        final full = await Api.get('/waters/${w['id']}');
        if (full is Map) {
          final ring = _ringFromGeo(full['polygon']);
          if (mounted && _shapeWaterId == w['id']) setState(() => _selWaterPoly = ring);
          meta.value = {'has_shape': full['has_shape'] == true || ring.isNotEmpty, 'count': (full['shape_request_count'] is num) ? (full['shape_request_count'] as num).toInt() : 0, 'rating': full['rating']};
        }
      } catch (_) {}
    }();

    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => DraggableScrollableSheet(
      expand: false, initialChildSize: 0.5, minChildSize: 0.3, maxChildSize: 0.9,
      builder: (_, scroll) => ListView(controller: scroll, padding: const EdgeInsets.all(20), children: [
        Row(children: [Icon(w['is_paid'] == true ? Icons.euro : Icons.water, color: w['is_paid'] == true ? const Color(0xFFD4A017) : _waterColor(level)), const SizedBox(width: 8), Expanded(child: Text(w['name'] ?? '', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)))]),
        if (sub.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(sub, style: const TextStyle(color: Colors.black54))),
        if (w['type'] != null) Padding(padding: const EdgeInsets.only(top: 6), child: Row(children: [
          const Icon(Icons.category_outlined, size: 15, color: Colors.black45), const SizedBox(width: 6),
          Text(mui(context, 'type_${w['type']}'), style: const TextStyle(color: Colors.black54, fontSize: 13)),
        ])),
        // Betaalwater: prominente boek-kaart met info + "Boek nu".
        if (w['is_paid'] == true) Container(
          margin: const EdgeInsets.only(top: 10), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFFFF7E0), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE7C66B))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Icon(Icons.euro, size: 16, color: Color(0xFFB8860B)), const SizedBox(width: 6),
              Text(mui(context, 'paid_badge'), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8A6D00)))]),
            if (w['paid_info'] != null && '${w['paid_info']}'.trim().isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 6), child: Text('${w['paid_info']}', style: const TextStyle(color: Colors.black87, height: 1.3))),
            if (w['booking_url'] != null && '${w['booking_url']}'.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 10), child: SizedBox(width: double.infinity, child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD4A017)),
                onPressed: () => launchUrl(Uri.parse('${w['booking_url']}'), mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.event_available, size: 18),
                label: Text(mui(context, 'paid_book'))))),
          ]),
        ),
        const SizedBox(height: 10),
        Row(children: [Icon(Icons.local_fire_department, size: 16, color: _waterColor(level)), const SizedBox(width: 6),
          Text('${mui(context, 'busy')}: ${level == 'none' ? mui(context, 'busy_none') : busyLevelLabel(context, level)}${count > 0 ? ' ($count)' : ''}', style: const TextStyle(color: Colors.black87))]),
        // Visjes-beoordeling van dit water (gemiddelde + jouw score).
        ValueListenableBuilder<Map<String, dynamic>?>(valueListenable: meta, builder: (_, m, __) {
          final rating = m?['rating'] as Map?;
          final avg = (rating?['avg'] as num?)?.toDouble() ?? 0;
          final rc = (rating?['count'] as num?)?.toInt() ?? 0;
          final mine = (rating?['mine'] as num?)?.toInt();
          return Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(mui(context, 'rate_title'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black54)),
                rc > 0 ? Row(children: [FishRating(value: avg, size: 16), const SizedBox(width: 6), Text('${avg.toStringAsFixed(1)} ($rc)', style: const TextStyle(fontSize: 12, color: Colors.black45))])
                       : Text(mui(context, 'rate_none'), style: const TextStyle(fontSize: 11, color: Colors.black38)),
              ]),
              const SizedBox(height: 8),
              Row(children: [Text('${mui(context, 'rate_ask')} ', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                FishRating(size: 26, mine: mine, onRate: (score) async {
                  try {
                    final r = await Api.post('/waters/${w['id']}/rate', {'score': score});
                    if (r is Map) meta.value = {...?meta.value, 'rating': r};
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mui(context, 'rate_thanks'))));
                  } catch (_) {}
                }),
              ]),
            ]),
          );
        }),
        // Vorm-knoppen werken bij zodra de info geladen is (venster zelf opent meteen).
        ValueListenableBuilder<Map<String, dynamic>?>(valueListenable: meta, builder: (_, m, __) {
          final hasShape = m?['has_shape'] == true;
          final reqCount = (m?['count'] ?? 0) as int;
          return Column(mainAxisSize: MainAxisSize.min, children: [
            // Moderator: watervorm intekenen/bewerken (op de kaart, met pen/vinger).
            if (_canMod) Padding(padding: const EdgeInsets.only(top: 10), child: SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: () { Navigator.pop(context); _startEditShape(); },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text('${mui(context, 'shape_edit')}${!hasShape && reqCount > 0 ? ' • $reqCount ${mui(context, 'shape_requested_badge')}' : ''}')))),
            // Moderator: water-gegevens bewerken (naam, type, betaalwater + boeking).
            if (_canMod) Padding(padding: const EdgeInsets.only(top: 10), child: SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: () { Navigator.pop(context); _editWater(w); },
              icon: const Icon(Icons.tune, size: 18),
              label: Text(mui(context, 'water_edit'))))),
            // Gewoon lid + nog geen vorm: intekening aanvragen → moderator krijgt een seintje.
            if (!_canMod && m != null && !hasShape) Padding(padding: const EdgeInsets.only(top: 10), child: SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: () { Navigator.pop(context); _requestShape(w['id']); },
              icon: const Icon(Icons.draw_outlined, size: 18),
              label: Text(mui(context, 'shape_request'))))),
          ]);
        }),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: () => _showRules(w),
          icon: const Icon(Icons.gavel, size: 18),
          label: Text(mui(context, 'rules_view')),
        )),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: () => _showMedia(w),
          icon: const Icon(Icons.photo_library_outlined, size: 18),
          label: Text(mui(context, 'media_view')),
        )),
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
            onTap: () { Navigator.pop(context); _flyToSpot(s as Map); },
          )),
      ]),
    ));
  }

  // Gelokaliseerd label voor een regel-waarde (yes/no/varies/allowed/...).
  String _ruleVal(BuildContext c, String v) => mui(c, 'val_$v');

  // Kleur: groen = mag/vrij, rood = niet/verboden, oranje = beperkt/wisselt, grijs = onbekend.
  Color _ruleColor(String v, bool license) {
    switch (v) {
      case 'no': case 'allowed': return const Color(0xFF16A34A);
      case 'yes': return license ? const Color(0xFFEA580C) : const Color(0xFFDC2626);
      case 'forbidden': return const Color(0xFFDC2626);
      case 'restricted': case 'varies': return const Color(0xFFEA580C);
      default: return Colors.grey;
    }
  }

  // Visregels-paneel: haalt /waters/{id}/rules op in de app-taal (land <- regio <- water).
  void _showRules(Map w) {
    final locc = Provider.of<I18n>(context, listen: false).locale;
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => DraggableScrollableSheet(
      expand: false, initialChildSize: 0.62, minChildSize: 0.3, maxChildSize: 0.95,
      builder: (_, scroll) => FutureBuilder(
        future: Api.get('/waters/${w['id']}/rules?lang=$locc'),
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
          }
          final r = snap.data;
          if (r is! Map) {
            return Padding(padding: const EdgeInsets.all(24), child: Text(mui(context, 'rules_none')));
          }
          Widget statusRow(IconData ic, String label, String v, bool lic) {
            final col = _ruleColor(v, lic);
            return Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
              Icon(ic, size: 20, color: col), const SizedBox(width: 10),
              Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: col.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(_ruleVal(context, v), style: TextStyle(color: col, fontWeight: FontWeight.w700, fontSize: 13))),
            ]));
          }
          Widget section(String title, dynamic body) {
            if (body == null || '$body'.trim().isEmpty) return const SizedBox.shrink();
            return Padding(padding: const EdgeInsets.only(top: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (title.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 4),
                child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.teal))),
              Text('$body', style: const TextStyle(color: Colors.black87, height: 1.35)),
            ]));
          }
          return ListView(controller: scroll, padding: const EdgeInsets.all(20), children: [
            Row(children: [const Icon(Icons.gavel, color: AppColors.teal), const SizedBox(width: 8),
              Expanded(child: Text('${mui(context, 'rules_title')}${w['country'] != null ? ' — ${w['country']}' : ''}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))]),
            const SizedBox(height: 14),
            statusRow(Icons.badge_outlined, mui(context, 'rules_license'), '${r['license_required'] ?? 'unknown'}', true),
            statusRow(Icons.nightlight_round, mui(context, 'rules_night'), '${r['night_fishing'] ?? 'unknown'}', false),
            statusRow(Icons.event_busy, mui(context, 'rules_season'), '${r['closed_season'] ?? 'unknown'}', false),
            if (w['permit_type'] == null || '${w['permit_type']}' == 'onbekend') Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF2F4F6), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFD6DDE2))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(mui(context, 'permit_label'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black54)),
                  const SizedBox(height: 2),
                  Text(mui(context, 'permit_onbekend_lang'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (mapCountryLicence(context, w['country'] as String?).isNotEmpty) Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(mapCountryLicence(context, w['country'] as String?), style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.35))),
                  // Regio-regels & seizoenen van de vergunning-zone waarin dit water ligt.
                  ...(() {
                    final reg = _regionForWater(w);
                    final rules = reg == null ? '' : _regLoc(reg['rules'] is Map ? Map<String,dynamic>.from(reg['rules']) : null);
                    final label = reg == null ? '' : _regLoc(reg['permit_label'] is Map ? Map<String,dynamic>.from(reg['permit_label']) : null);
                    if (reg == null || (rules.isEmpty && label.isEmpty)) return <Widget>[];
                    return <Widget>[
                      Padding(padding: const EdgeInsets.only(top: 8),
                        child: Row(children: [
                          Container(width: 10, height: 10, decoration: BoxDecoration(color: _hexColor('${reg['color'] ?? '#94a3b8'}'), shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Expanded(child: Text('${reg['name'] ?? ''}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87))),
                        ])),
                      if (rules.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4),
                        child: Text('⚠️ ' + rules, style: const TextStyle(fontSize: 12, color: Color(0xFF8A5A00), height: 1.3))),
                    ];
                  })(),
                  if (_inNL(w)) ...[
                    Padding(padding: const EdgeInsets.only(top: 6),
                      child: InkWell(onTap: () => launchUrl(Uri.parse('https://www.visplanner.nl/'), mode: LaunchMode.externalApplication),
                        child: Text(mui(context, 'permit_visplanner'), style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600)))),
                    const SizedBox(height: 8),
                    Text(mui(context, 'permit_claim_hint'), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: Text(mui(context, 'permit_claim_btn')),
                      onPressed: () async {
                        final m = ScaffoldMessenger.of(context);
                        try {
                          final r = await Api.post('/waters/${w['id']}/permit-report', {'claim': 'vispas'});
                          m.showSnackBar(SnackBar(content: Text(r is Map ? '${r['message']}' : 'OK')));
                          if (r is Map && r['applied'] == true) { w['permit_type'] = 'landelijk'; _loadWaters(); }
                        } catch (e) { m.showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : '$e'))); }
                      },
                    ),
                  ],
                ]))),
            if (w['permit_type'] != null && '${w['permit_type']}' != 'onbekend') Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF0F7F5), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFCADFDA))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(mui(context, 'permit_label'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black54)),
                  const SizedBox(height: 2),
                  Text(mui(context, 'permit_${w['permit_type']}'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (w['permit_url'] != null && '${w['permit_url']}'.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4),
                    child: InkWell(onTap: () => launchUrl(Uri.parse('${w['permit_url']}'), mode: LaunchMode.externalApplication),
                      child: Text(mui(context, 'permit_arrange'), style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600)))),
                ]))),
            section('', r['summary']),
            section(mui(context, 'rules_license'), r['license_info']),
            section(mui(context, 'rules_night'), r['night_info']),
            section(mui(context, 'rules_season'), r['season_info']),
            if (r['official_url'] != null && '${r['official_url']}'.isNotEmpty) ...[
              const SizedBox(height: 18),
              SizedBox(width: double.infinity, child: FilledButton.icon(
                onPressed: () => launchUrl(Uri.parse('${r['official_url']}'), mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(mui(context, 'rules_official')))),
            ],
            if (r['updated_at'] != null || r['verified_at'] != null) Padding(padding: const EdgeInsets.only(top: 12),
              child: Text([
                if (r['updated_at'] != null) '${mui(context, 'rules_changed')}: ${r['updated_at']}',
                if (r['verified_at'] != null) '${mui(context, 'rules_checked')}: ${r['verified_at']}',
              ].join('  ·  '), style: const TextStyle(fontSize: 11, color: Colors.black38))),
            const SizedBox(height: 16),
            Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFFF7E6), borderRadius: BorderRadius.circular(8)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.info_outline, size: 16, color: Color(0xFFB26A00)), const SizedBox(width: 8),
                Expanded(child: Text('${r['disclaimer'] ?? ''}', style: const TextStyle(fontSize: 12, color: Color(0xFF8A5A00)))),
              ])),
            const SizedBox(height: 8),
          ]);
        },
      ),
    ));
  }

  // Media (foto's + video-links) bij een water: goedgekeurd zichtbaar, leden voegen toe (→ moderatie).
  void _showMedia(Map w) {
    final wid = w['id'];
    List? items;
    List? catches;
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => DraggableScrollableSheet(
      expand: false, initialChildSize: 0.6, minChildSize: 0.3, maxChildSize: 0.95,
      builder: (_, scroll) => StatefulBuilder(builder: (ctx, setS) {
        Future<void> reload() async {
          try { final r = await Api.get('/waters/$wid/media'); items = r is List ? r : []; } catch (_) { items = []; }
          try { final rc = await Api.get('/waters/$wid/catches'); catches = rc is List ? rc : []; } catch (_) { catches = []; }
          if (ctx.mounted) setS(() {});
        }
        if (items == null) { items = []; reload(); }

        Future<void> addPhoto() async {
          try {
            final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
            if (x == null) return;
            final up = await Api.uploadImage(x.path);
            await Api.post('/waters/$wid/media', {'type': 'photo', 'path': up['path']});
            if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(mui(ctx, 'media_submitted'))));
          } catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'Er ging iets mis'))); }
        }
        Future<void> addVideo() async {
          final ctrl = TextEditingController();
          final ok = await showDialog<bool>(context: context, builder: (dctx) => AlertDialog(
            title: Text(mui(context, 'media_video_title')),
            content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'https://youtube.com/...'), keyboardType: TextInputType.url),
            actions: [TextButton(onPressed: () => Navigator.pop(dctx, false), child: Text(context.tr('map.cancel'))),
              FilledButton(onPressed: () => Navigator.pop(dctx, true), child: Text(context.tr('map.save')))],
          ));
          if (ok != true || ctrl.text.trim().isEmpty) return;
          try {
            await Api.post('/waters/$wid/media', {'type': 'video', 'url': ctrl.text.trim()});
            if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(mui(ctx, 'media_submitted'))));
          } catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'Er ging iets mis'))); }
        }
        void addSheet() => showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.add_a_photo_outlined), title: Text(mui(context, 'media_add_photo')), onTap: () { Navigator.pop(context); addPhoto(); }),
          ListTile(leading: const Icon(Icons.video_library_outlined), title: Text(mui(context, 'media_add_video')), onTap: () { Navigator.pop(context); addVideo(); }),
        ])));

        return ListView(controller: scroll, padding: const EdgeInsets.all(16), children: [
          Row(children: [const Icon(Icons.photo_library_outlined, color: AppColors.teal), const SizedBox(width: 8),
            Expanded(child: Text('${mui(context, 'media_title')} — ${w['name'] ?? ''}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)))]),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
            onPressed: addSheet, icon: const Icon(Icons.add_photo_alternate_outlined, size: 18), label: Text(mui(context, 'media_add')))),
          const SizedBox(height: 6),
          Text(mui(context, 'media_moderated'), style: const TextStyle(fontSize: 11, color: Colors.black45)),
          const SizedBox(height: 12),
          if ((catches ?? []).isNotEmpty) ...[
            Row(children: [const Icon(Icons.set_meal, size: 18, color: AppColors.teal), const SizedBox(width: 6),
              Text(mui(context, 'catches_here'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy))]),
            const SizedBox(height: 8),
            GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 8, crossAxisSpacing: 8, children: catches!.map<Widget>((cc) {
              return GestureDetector(
                onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => CatchDetailScreen(catchId: cc['id'] as int))); },
                child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Stack(fit: StackFit.expand, children: [
                  Image.network('${cc['photo']}', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.black12, child: const Icon(Icons.broken_image, color: Colors.black26))),
                  Positioned(left: 0, right: 0, bottom: 0, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black87, Colors.transparent])),
                    child: Text([if (cc['species'] != null) '${cc['species']}', if (cc['weight_kg'] != null) Units.weight(cc['weight_kg'])].join(' \u00b7 '),
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)))),
                ])),
              );
            }).toList()),
            const Divider(height: 26),
            Text(mui(context, 'media_title'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black54)),
            const SizedBox(height: 8),
          ],
          if ((items ?? []).isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Center(child: Text(mui(context, 'media_empty'), style: const TextStyle(color: Colors.black45))))
          else
            GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 8, crossAxisSpacing: 8, children: items!.map<Widget>((m) {
              final isVideo = m['type'] == 'video';
              final thumb = isVideo ? m['thumb'] : m['url'];
              return GestureDetector(
                onTap: () {
                  if (isVideo && m['url'] != null) { launchUrl(Uri.parse('${m['url']}'), mode: LaunchMode.externalApplication); return; }
                  final ph = items!.where((x) => (x as Map)['type'] != 'video' && x['url'] != null).map((x) => (x as Map)['url'].toString()).toList();
                  if (m['url'] != null) PhotoViewer.open(context, ph, ph.indexOf(m['url'].toString()));
                },
                child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Stack(fit: StackFit.expand, children: [
                  if (thumb != null) Image.network('$thumb', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.black12, child: const Icon(Icons.broken_image, color: Colors.black26)))
                  else Container(color: Colors.black87, child: const Icon(Icons.play_circle_outline, color: Colors.white70, size: 40)),
                  if (isVideo) const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 44)),
                ])),
              );
            }).toList()),
        ]);
      }),
    ));
  }

  // Eerste keer dat iemand de kaart opent → toon het uitleg-boekje automatisch (daarna niet meer).
  Future<void> _maybeShowHelpOnce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('map_help_seen') ?? false) return;
      await prefs.setBool('map_help_seen', true);
      if (mounted) _showHelp();
    } catch (_) {}
  }

  // Uitleg voor gebruikers: swipebaar boekje met één scherm per functie van de kaart.
  void _showHelp() {
    const pages = [
      [Icons.search, 'help_t_search', 'help_body_search'],
      [Icons.water, 'help_t_waters', 'help_body_waters'],
      [Icons.place, 'help_t_spot', 'help_body_spot'],
      [Icons.gps_fixed, 'help_t_place', 'help_body_place'],
      [Icons.lock_outline, 'help_t_privacy', 'help_body_privacy'],
      [Icons.groups, 'help_t_busy', 'help_body_busy'],
      [Icons.add_location_alt, 'help_t_water', 'help_body_water'],
      [Icons.euro, 'help_t_paid', 'help_body_paid'],
      [Icons.edit_location_alt, 'help_t_shape', 'help_body_shape'],
      [Icons.public, 'help_t_country', 'help_body_country'],
    ];
    final pc = PageController();
    int idx = 0;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      content: SizedBox(width: 320, height: 320, child: Column(children: [
        Expanded(child: PageView.builder(
          controller: pc, itemCount: pages.length,
          onPageChanged: (i) => setS(() => idx = i),
          itemBuilder: (_, i) {
            final p = pages[i];
            return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: CircleAvatar(radius: 28, backgroundColor: AppColors.teal.withValues(alpha: 0.12),
                child: Icon(p[0] as IconData, color: AppColors.teal, size: 30))),
              const SizedBox(height: 14),
              Text(mui(ctx, p[1] as String), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(mui(ctx, p[2] as String), style: const TextStyle(fontSize: 13.5, height: 1.45)),
            ]));
          },
        )),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (int i = 0; i < pages.length; i++)
            Container(width: 7, height: 7, margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(shape: BoxShape.circle, color: i == idx ? AppColors.teal : Colors.black26)),
        ]),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(mui(ctx, 'help_close'))),
        if (idx < pages.length - 1)
          FilledButton(onPressed: () => pc.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut), child: Text(mui(ctx, 'help_next'))),
      ],
    )));
  }

  void _showLegend() {
    Widget row(Widget icon, String text) => Padding(padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 30, child: Center(child: icon)), const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ]));
    Widget pin(Widget w) => SizedBox(width: 30, height: 42, child: FittedBox(fit: BoxFit.contain, child: w));
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(mui(ctx, 'legend_title')),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        row(pin(_clusterBubble(5)), mui(ctx, 'legend_cluster')),
        row(pin(_waterPin('none')), mui(ctx, 'legend_water')),
        row(pin(_paidPin('none')), mui(ctx, 'legend_paid')),
        row(Container(width: 22, height: 16, decoration: BoxDecoration(
          color: const Color(0xFF2563EB).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(3),
          border: Border.all(color: const Color(0xFF2563EB), width: 2))), mui(ctx, 'legend_shape')),
        row(Row(mainAxisSize: MainAxisSize.min, children: const [
          Icon(Icons.circle, color: Color(0xFF22C55E), size: 10), SizedBox(width: 2),
          Icon(Icons.circle, color: Color(0xFFF59E0B), size: 10), SizedBox(width: 2),
          Icon(Icons.circle, color: Color(0xFFEF4444), size: 10),
        ]), mui(ctx, 'legend_busy')),
        row(const Icon(Icons.place, color: AppColors.teal, size: 22), mui(ctx, 'legend_spot')),
        row(const Icon(Icons.set_meal, color: Colors.orange, size: 20), mui(ctx, 'legend_catch')),
        row(Container(width: 16, height: 16, decoration: BoxDecoration(
          color: const Color(0xFF2563EB), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 3)])), mui(ctx, 'legend_me')),
        const Divider(height: 18),
        row(const Icon(Icons.lightbulb_outline, size: 18, color: Colors.black45), mui(ctx, 'legend_tip')),
      ])),
      actions: [
        TextButton(onPressed: () { Navigator.pop(ctx); _showHelp(); }, child: Text(mui(ctx, 'help_button'))),
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
      ],
    ));
  }

  // Lid voegt een (nog niet bekend) viswater toe → tac voor iedereen.
  Future<void> _addWater(LatLng pos) async {
    final name = TextEditingController();
    final booking = TextEditingController();
    String type = 'meer';
    bool isPaid = false;
    final canMod = _canMod;
    const types = ['meer', 'rivier', 'kanaal', 'zee', 'vijver', 'overig'];
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      title: Text(mui(ctx, 'add_water')),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: InputDecoration(labelText: mui(ctx, 'water_name'))),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(initialValue: type, decoration: InputDecoration(labelText: mui(ctx, 'water_type')),
          items: types.map((t) => DropdownMenuItem(value: t, child: Text(mui(ctx, 'type_$t')))).toList(),
          onChanged: (v) => setS(() => type = v!)),
        // Betaalwater-keuze — alleen voor moderator/admin.
        if (canMod) ...[
          SwitchListTile(contentPadding: EdgeInsets.zero, activeThumbColor: const Color(0xFFD4A017),
            title: Text(mui(ctx, 'water_is_paid')),
            value: isPaid, onChanged: (v) => setS(() => isPaid = v)),
          if (isPaid) TextField(controller: booking, keyboardType: TextInputType.url,
            decoration: InputDecoration(labelText: mui(ctx, 'water_booking_url'), hintText: 'https://...')),
        ],
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('map.cancel'))), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('map.save')))],
    )));
    if (ok != true || name.text.trim().isEmpty) return;
    try {
      final created = await Api.post('/waters', {
        'name': name.text.trim(), 'type': type, 'latitude': pos.latitude, 'longitude': pos.longitude,
        if (canMod && isPaid) 'is_paid': true,
        if (canMod && isPaid && booking.text.trim().isNotEmpty) 'booking_url': booking.text.trim(),
      });
      Analytics.log('water_created');
      // Waters-laag verversen (zat er niet in → nieuw water verscheen pas na slepen/zoomen)
      // en het verse water meteen openen zodat duidelijk is dat het gelukt is.
      await _loadWaters();
      await _load();
      if (mounted && created is Map && created['id'] != null) {
        // Laravel geeft decimalen als strings terug → altijd via tryParse.
        final la = double.tryParse('${created['latitude']}');
        final lo = double.tryParse('${created['longitude']}');
        if (la != null && lo != null) _map.move(LatLng(la, lo), 15);
        final fresh = _waters.firstWhere((x) => x is Map && x['id'] == created['id'], orElse: () => created);
        _showWater(Map<String, dynamic>.from(fresh is Map ? fresh : created));
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mui(context, 'water_added'))));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : mui(context, 'no_water_here'))));
    }
  }

  Future<void> _addSpot(LatLng pos) async {
    final name = TextEditingController();
    final notes = TextEditingController();
    String privacy = 'private';
    LatLng target = pos;     // standaard: het aangetikte punt / kaartmidden
    bool gps = false;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      title: Text(context.tr('map.add_spot')),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: InputDecoration(labelText: context.tr('map.spot_name'))),
        const SizedBox(height: 10),
        TextField(controller: notes, maxLines: 3, decoration: InputDecoration(labelText: mui(ctx, 'spot_info'), hintText: mui(ctx, 'spot_info_hint'), alignLabelWithHint: true)),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(initialValue: privacy, decoration: InputDecoration(labelText: context.tr('map.visibility')),
          items: [
            DropdownMenuItem(value: 'private', child: Text(context.tr('map.private_only_me'))),
            DropdownMenuItem(value: 'friends', child: Text(context.tr('map.friends'))),
            DropdownMenuItem(value: 'public', child: Text(context.tr('map.public'))),
          ],
          onChanged: (v) => setS(() => privacy = v!)),
        const SizedBox(height: 10),
        // Stek op je eigen GPS-locatie zetten (i.p.v. het kaartpunt).
        Align(alignment: Alignment.centerLeft, child: OutlinedButton.icon(
          onPressed: () async {
            final p = await loc.currentLocation();
            final ok = p.isReal && (p.accuracy ?? 9999) <= 75;
            if (ok) { setS(() { target = LatLng(p.lat, p.lng); gps = true; }); }
            else if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mui(context, 'gps_fail')))); }
          },
          icon: const Icon(Icons.my_location, size: 18),
          label: Text(mui(context, 'use_gps')))),
        if (gps) Padding(padding: const EdgeInsets.only(top: 4),
          child: Text(mui(context, 'gps_set'), style: const TextStyle(fontSize: 12, color: AppColors.teal, fontWeight: FontWeight.w600))),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('map.cancel'))), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('map.save')))],
    )));
    if (ok != true || name.text.trim().isEmpty) return;
    try {
      final created = await Api.post('/spots', {'name': name.text.trim(), 'latitude': target.latitude, 'longitude': target.longitude, 'privacy': privacy, if (notes.text.trim().isNotEmpty) 'notes': notes.text.trim()});
      Analytics.log('spot_created');
      await _load();
      // Direct het verse stek-detail openen zodat de maker meteen foto's/video's kan toevoegen.
      if (mounted && created is Map && created['id'] != null) {
        final fresh = _spots.firstWhere((x) => x['id'] == created['id'], orElse: () => created);
        _showSpot(fresh is Map ? fresh : created);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : context.tr('map.place_on_water'))));
    }
  }

  String _privacyLabel(String? p) => p == 'public' ? context.tr('map.public') : p == 'friends' ? context.tr('map.friends') : context.tr('map.private');

  // Aantal zichtbare stekken (filter-respecterend) binnen ~2 km van een water — voor het telbadge op de dobber.
  // Stekken die ECHT bij dit water horen (op water_id, niet op afstand) — filter-respecterend.
  Map<dynamic, int> _spotCountByWater = {}; // vooraf berekend in build() — telbadge per dobber zonder dure her-filtering

  // Per land een passend zoomniveau zodat je het HELE land ziet (niet een klein stukje).
  double _countryZoom(String c) {
    const big = {'Frankrijk', 'Spanje', 'Zweden', 'Noorwegen', 'Finland', 'Duitsland', 'Polen', 'Verenigd Koninkrijk', 'Italië', 'Roemenië'};
    const small = {'Nederland', 'België', 'Zwitserland', 'Denemarken', 'Ierland'};
    if (big.contains(c)) return 8;     // ≥ minZoom 8 (groot land: regio, sleep voor de rest)
    if (small.contains(c)) return 9;
    return 8.5;
  }

  List _spotsForWater(dynamic waterId) =>
      _spots.where((s) => s['water_id'] != null && s['water_id'] == waterId && _spotPasses(s as Map)).toList();

  // Dobber-marker met optioneel telbadge (aantal stekken bij dit water).
  Widget _waterMarkerChild(Map w) {
    final pin = w['is_paid'] == true ? _paidPin('${w['busyness']?['level'] ?? 'none'}') : _waterPin('${w['busyness']?['level'] ?? 'none'}');
    final n = _spotCountByWater[w['id']] ?? 0;
    if (n == 0) return pin;
    return Stack(clipBehavior: Clip.none, children: [
      pin,
      Positioned(right: -2, top: -2, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white, width: 1.5)),
        child: Text('$n', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      )),
    ]);
  }

  // Vlieg op de kaart naar een stek en toon de info.
  void _flyToSpot(Map s) {
    final la = double.tryParse('${s['latitude']}'); final lo = double.tryParse('${s['longitude']}');
    if (la != null && lo != null) _map.move(LatLng(la, lo), _zoom < 14 ? 15 : _zoom);
    _showSpot(s);
  }

  Future<void> _showSpot(Map s) async {
    Map details = {};
    try { final d = await Api.get('/spots/${s['id']}/details'); if (d is Map) details = d; } catch (_) {}
    if (!mounted) return;
    final mine = s['is_mine'] == true;
    final owner = s['user'] is Map ? s['user']['username'] : null;
    final waterName = s['water'] is Map ? s['water']['name'] : s['water'];
    final photo = details['photo'];
    final species = (details['species'] is List) ? details['species'] as List : [];
    final List media = (s['media'] is List) ? List.from(s['media']) : [];

    final messenger = ScaffoldMessenger.of(context);
    final failMsg = mui(context, 'gps_fail');
    Future<void> addPhoto(StateSetter setSheet) async {
      try {
        final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
        if (x == null) return;
        final up = await Api.uploadImage(x.path);
        final r = await Api.post('/spots/${s['id']}/media', {'type': 'photo', 'path': up['path']});
        if (r is Map && r['media'] != null) { media.add(r['media']); setSheet(() {}); _load(); }
      } catch (e) { messenger.showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : failMsg))); }
    }
    Future<void> addVideo(StateSetter setSheet) async {
      final ctrl = TextEditingController();
      final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
        title: Text(mui(c, 'spot_add_video')),
        content: TextField(controller: ctrl, decoration: InputDecoration(hintText: mui(c, 'spot_video_prompt'))),
        actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: Text(context.tr('map.cancel'))), FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(context.tr('map.save')))],
      ));
      if (ok != true || ctrl.text.trim().isEmpty) return;
      try {
        final r = await Api.post('/spots/${s['id']}/media', {'type': 'video', 'url': ctrl.text.trim()});
        if (r is Map && r['media'] != null) { media.add(r['media']); setSheet(() {}); _load(); }
      } catch (e) { messenger.showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : failMsg))); }
    }
    Future<void> delMedia(Map mItem, StateSetter setSheet) async {
      try { await Api.delete('/spots/${s['id']}/media/${mItem['id']}'); media.removeWhere((x) => x['id'] == mItem['id']); setSheet(() {}); _load(); } catch (_) {}
    }

    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => StatefulBuilder(builder: (ctx, setSheet) => Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.place, color: mine ? AppColors.teal : AppColors.shared), const SizedBox(width: 8), Expanded(child: Text(s['name'] ?? context.tr('map.spot'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))]),
        const SizedBox(height: 6),
        if (!mine && owner != null) Text('${context.tr('map.shared_by')} @$owner', style: const TextStyle(color: Colors.black54)),
        if (waterName != null) Text('${context.tr('map.water')}: $waterName', style: const TextStyle(color: Colors.black54)),
        if (s['notes'] != null && '${s['notes']}'.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('${s['notes']}')),
        if (media.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(height: 96, child: ListView.separated(
            scrollDirection: Axis.horizontal, itemCount: media.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final m = media[i] as Map; final isVideo = m['type'] == 'video';
              final thumb = isVideo ? m['thumb'] : m['url'];
              return GestureDetector(
                onTap: () {
                  if (isVideo && m['url'] != null) { launchUrl(Uri.parse('${m['url']}'), mode: LaunchMode.externalApplication); return; }
                  final ph = media.where((x) => (x as Map)['type'] != 'video' && x['url'] != null).map((x) => (x as Map)['url'].toString()).toList();
                  if (m['url'] != null) PhotoViewer.open(context, ph, ph.indexOf(m['url'].toString()));
                },
                onLongPress: mine ? () => delMedia(m, setSheet) : null,
                child: Stack(alignment: Alignment.center, children: [
                  ClipRRect(borderRadius: BorderRadius.circular(10), child: thumb != null
                    ? Image.network('$thumb', width: 120, height: 96, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 120, height: 96, color: Colors.black12, child: const Icon(Icons.link)))
                    : Container(width: 120, height: 96, color: Colors.black12, child: const Icon(Icons.ondemand_video))),
                  if (isVideo) const Icon(Icons.play_circle_fill, color: Colors.white, size: 34),
                ]),
              );
            })),
          if (mine) Padding(padding: const EdgeInsets.only(top: 2), child: Text(mui(ctx, 'spot_media_longpress'), style: const TextStyle(fontSize: 11, color: Colors.black38))),
        ],
        if (photo != null) Padding(padding: const EdgeInsets.only(top: 10), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network('$photo', height: 150, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()))),
        if (species.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(mui(context, 'species_here'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: species.map((sp) => Chip(label: Text('$sp'), visualDensity: VisualDensity.compact, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)).toList()),
        ],
        const SizedBox(height: 8),
        Row(children: [const Icon(Icons.visibility, size: 14, color: Colors.black45), const SizedBox(width: 4), Text(_privacyLabel(s['privacy']), style: const TextStyle(color: Colors.black45, fontSize: 12))]),
        if (mine) ...[
          const Divider(height: 24),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () => addPhoto(setSheet), icon: const Icon(Icons.add_a_photo, size: 18), label: Text(mui(ctx, 'spot_add_photo')))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(onPressed: () => addVideo(setSheet), icon: const Icon(Icons.video_call, size: 18), label: Text(mui(ctx, 'spot_add_video')))),
          ]),
        ],
      ])),
    )));
  }

  void _showCatch(Map c) {
    showModalBottomSheet(context: context, builder: (_) => Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.set_meal, color: Colors.orange), const SizedBox(width: 8), Expanded(child: Text(c['species'] ?? c['species_text'] ?? context.tr('map.catch'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))]),
      const SizedBox(height: 6),
      if (c['weight_kg'] != null) Text('${context.tr('map.weight')}: ${Units.weight(c['weight_kg'])}', style: const TextStyle(color: Colors.black54)),
      if (c['length_cm'] != null) Text('${context.tr('map.length')}: ${c['length_cm']} cm', style: const TextStyle(color: Colors.black54)),
    ])));
  }

  Widget _busyBadge(String level, dynamic count) => Container(
    decoration: BoxDecoration(color: _busyColor(level).withValues(alpha: 0.88), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]),
    alignment: Alignment.center,
    child: Text('$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
  );

  // Duidelijk tikbare water-pin: gevulde druppel-vorm met witte rand + schaduw,
  // zodat het herkenbaar is als aan te tikken marker (i.p.v. een plat icoontje).
  Widget _waterPin(String level) {
    // Achtergrond verkleurt met de drukte: rustig = wit, druk = groen/oranje/rood.
    final busy = level != 'none';
    final c = _busyColor(level);
    final bg = busy ? c : Colors.white;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 36, height: 36,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: busy ? Colors.white : const Color(0xFFCBD5E1), width: 2.5),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Image.asset('assets/marker_dobber.png', fit: BoxFit.contain),
      ),
      // Klein puntje eronder → leest als kaart-speld die ergens naar wijst.
      Transform.translate(offset: const Offset(0, -4), child: Icon(Icons.arrow_drop_down, color: busy ? c : const Color(0xFF94A3B8), size: 18)),
    ]);
  }

  // Betaalwater = goud-omrande dobber (zelfde dobber-thema) met €-badge en,
  // net als gratis water, een drukte-gekleurde achtergrond.
  Widget _paidPin(String level) {
    const gold = Color(0xFFD4A017);
    final busy = level != 'none';
    final c = _busyColor(level);
    final bg = busy ? c : Colors.white;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Stack(clipBehavior: Clip.none, children: [
        Container(
          width: 36, height: 36,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: gold, width: 3), // gouden rand = betaalwater
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Image.asset('assets/marker_dobber.png', fit: BoxFit.contain),
        ),
        Positioned(right: -3, bottom: -3, child: Container(
          width: 16, height: 16,
          decoration: BoxDecoration(color: gold, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
          alignment: Alignment.center,
          child: const Icon(Icons.euro, color: Colors.white, size: 10),
        )),
      ]),
      Transform.translate(offset: const Offset(0, -4), child: Icon(Icons.arrow_drop_down, color: busy ? c : gold, size: 18)),
    ]);
  }

  bool _spotPasses(Map s) {
    if (_spotFilter == 'public') return s['privacy'] == 'public';
    if (_spotFilter == 'friends') return s['privacy'] == 'friends';
    return true;
  }

  bool get _canMod => context.read<AuthState>().user?.canModerate ?? false;

  // GeoJSON Polygon ([lng,lat]) → ring van LatLng.
  // '#rrggbb' -> Color.
  Color _hexColor(String h) {
    final s = h.replaceAll('#', '');
    if (s.length == 6) { final v = int.tryParse(s, radix: 16); if (v != null) return Color(0xFF000000 | v); }
    return const Color(0xFF94A3B8);
  }
  // GeoJSON Polygon/MultiPolygon -> lijst ringen (buitenring per deel).
  List<List<LatLng>> _geoRings(dynamic g) {
    if (g is! Map) return [];
    List<LatLng> toRing(dynamic ring) {
      final out = <LatLng>[];
      if (ring is List) for (final p in ring) {
        if (p is List && p.length >= 2 && p[0] is num && p[1] is num) {
          final lat = (p[1] as num).toDouble(), lng = (p[0] as num).toDouble();
          if (lat.abs() <= 90 && lng.abs() <= 180) out.add(LatLng(lat, lng));
        }
      }
      return out;
    }
    final t = g['type'], c = g['coordinates'];
    if (t == 'Polygon' && c is List && c.isNotEmpty) return [toRing(c.first)];
    if (t == 'MultiPolygon' && c is List) {
      return [for (final poly in c) if (poly is List && poly.isNotEmpty) toRing(poly.first)].where((r) => r.length >= 3).toList();
    }
    return [];
  }
  // Vergunning-regio waarin dit water valt (voor de regels/seizoenen in het paneel).
  Map? _regionForWater(Map w) {
    final la = (w['latitude'] is num) ? (w['latitude'] as num).toDouble() : double.tryParse('${w['latitude']}');
    final lo = (w['longitude'] is num) ? (w['longitude'] as num).toDouble() : double.tryParse('${w['longitude']}');
    if (la == null || lo == null) return null;
    for (final reg in _permitRegions) {
      if (reg is! Map) continue;
      for (final ring in _geoRings(reg['polygon'])) {
        if (ring.length >= 3 && _pointInRing(LatLng(la, lo), ring)) return reg;
      }
    }
    return null;
  }
  String _regLoc(Map? m) {
    if (m == null) return '';
    final lang = Localizations.localeOf(context).languageCode;
    return (m[lang] ?? m['en'] ?? '').toString();
  }
  // Vergunning-regio's van alle landen ophalen (klein; app tekent wat in beeld is).
  // Vergunning-regio's van EEN land (per land laden i.p.v. alles — payload klein houden).
  Future<void> _loadRegions(String? country) async {
    final en = country == null ? null : (_countryEn[country] ?? country);
    if (en == null) { if (mounted) setState(() => _permitRegions = []); return; }
    try {
      final r = await Api.get('/permit-regions?country=' + Uri.encodeComponent(en));
      final list = r is Map ? r['regions'] : null;
      if (mounted) setState(() => _permitRegions = list is List ? list : []);
    } catch (_) {}
  }

  List<LatLng> _ringFromGeo(dynamic g) {
    if (g is Map && g['type'] == 'Polygon' && g['coordinates'] is List && (g['coordinates'] as List).isNotEmpty) {
      final ring = (g['coordinates'] as List).first;
      if (ring is List) {
        final out = <LatLng>[];
        for (final p in ring) {
          if (p is! List || p.length < 2 || p[0] is! num || p[1] is! num) continue;
          final lat = (p[1] as num).toDouble(), lng = (p[0] as num).toDouble();
          // Ongeldige/rotte punten (buiten bereik of pal op 0,0) overslaan → geen rare vorm-lijn.
          if (lat.abs() > 90 || lng.abs() > 180 || (lat.abs() < 0.01 && lng.abs() < 0.01)) continue;
          out.add(LatLng(lat, lng));
        }
        return out.length >= 3 ? out : [];
      }
    }
    return [];
  }

  // Inkleur-kleur per watertype (vorm-vulling). Dobber blijft de drukte-kleur.
  Color _typeColor(String? t) {
    switch (t) {
      case 'meer': return const Color(0xFF2563EB);   // blauw
      case 'rivier': return const Color(0xFF0EA5E9);  // hemelsblauw
      case 'kanaal': return const Color(0xFF6366F1);  // indigo
      case 'zee': return const Color(0xFF1E3A8A);     // donkerblauw
      case 'vijver': return const Color(0xFF14B8A6);  // turquoise
      default: return const Color(0xFF64748B);        // grijs
    }
  }


  // EIGEN clustering (geen library): ingezoomd (≥12) losse dobbers; uitgezoomd
  // groepeer ik per grid-cel (~80px) tot één bolletje op het gemiddelde van die groep.
  // Geen animatie → niets zakt weg; bolletjes blijven netjes boven hun eigen gebied.
  // Ruwe, betrouwbare coördinaat (NOOIT centroïde — die kan door rotte vormdata naar 0,0 trekken).
  LatLng? _waterCoord(Map w) {
    final la = double.tryParse('${w['latitude']}');
    final lo = double.tryParse('${w['longitude']}');
    if (la == null || lo == null || la.abs() > 90 || lo.abs() > 180) return null;
    return LatLng(la, lo);
  }

  // De server bepaalt de clustering (grid-aggregatie): uitgezoomd komen er cluster-cellen
  // terug met een 'count', ingezoomd losse waters. Wij tekenen puur wat de server stuurt —
  // geen client-side rekenwerk meer dat kon "wegzakken".
  List<Marker> _clusterWaterMarkers() {
    final z = _zoom;
    final out = <Marker>[];
    for (final w in _waters) {
      if (w is! Map) continue;
      final p = _waterCoord(w); if (p == null) continue;
      final cnt = (w['count'] is num) ? (w['count'] as num).toInt() : 1;
      if (w['cluster'] == true) {
        // Uitgezoomd: ELKE cel een uniform bolletje (ook "1") → geen losse dobbers ertussen.
        out.add(Marker(point: p, width: 46, height: 46, alignment: Alignment.center,
          child: GestureDetector(
            // Eén tik springt direct voorbij de closeup-grens (≥13) → meteen losse dobbers,
            // niet eerst nóg een laag bolletjes. Gecentreerd op het cluster.
            onTap: () => _map.move(p, (z + 3.0).clamp(13.0, 18.0)),
            child: _clusterBubble(cnt))));
      } else {
        out.add(Marker(point: p, width: 44, height: 48, alignment: Alignment.center,
          child: GestureDetector(behavior: HitTestBehavior.opaque,
            onTap: () => _showWater(w), child: _waterMarkerChild(w))));
      }
    }
    return out;
  }

  Widget _clusterBubble(int n) => Container(
    decoration: BoxDecoration(color: AppColors.teal, shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2.5),
      boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)]),
    alignment: Alignment.center,
    child: Text('$n', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
  );

  // Ligt een tikpunt binnen een ingetekende watervorm? → dan dat water (klikbaar net als de dobber).
  bool _pointInRing(LatLng pt, List<LatLng> ring) {
    bool inside = false; final n = ring.length;
    for (int i = 0, j = n - 1; i < n; j = i++) {
      final yi = ring[i].latitude, xi = ring[i].longitude, yj = ring[j].latitude, xj = ring[j].longitude;
      final denom = (yj - yi) == 0 ? 1e-12 : (yj - yi);
      if (((yi > pt.latitude) != (yj > pt.latitude)) && (pt.longitude < (xj - xi) * (pt.latitude - yi) / denom + xi)) inside = !inside;
    }
    return inside;
  }

  Map? _waterAtPoint(LatLng pt) {
    for (final w in _waters) {
      if (w is! Map || w['polygon'] == null) continue;
      final ring = _ringFromGeo(w['polygon']);
      if (ring.length >= 3 && _pointInRing(pt, ring)) return w;
    }
    return null;
  }

  void _startEditShape() {
    setState(() { _draftPts = List.from(_selWaterPoly); _editShape = true; _shapeMsg = mui(context, 'shape_hint'); });
  }

  void _shapeHelp() {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: Text(mui(c, 'shape_help_title')),
      content: SingleChildScrollView(child: Text(mui(c, 'shape_help_body'), style: const TextStyle(height: 1.4))),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(MaterialLocalizations.of(c).closeButtonLabel))],
    ));
  }

  Future<void> _fetchOsmShape() async {
    if (_shapeWaterId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final noneMsg = mui(context, 'shape_osm_none');
    final failMsg = mui(context, 'gps_fail');
    setState(() => _shapeMsg = '…');
    try {
      final r = await Api.put('/admin/waters/$_shapeWaterId/shape', {'refetch': true});
      final ring = _ringFromGeo(r is Map ? r['polygon'] : null);
      setState(() { _draftPts = ring; _shapeMsg = ring.isEmpty ? noneMsg : ''; });
    } catch (e) { messenger.showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : failMsg))); }
  }

  Future<void> _saveShape() async {
    if (_shapeWaterId == null) return;
    if (_draftPts.length < 3) { setState(() => _shapeMsg = mui(context, 'shape_need3')); return; }
    final messenger = ScaffoldMessenger.of(context);
    final savedMsg = mui(context, 'shape_saved');
    final failMsg = mui(context, 'gps_fail');
    final coords = [
      for (final p in _draftPts) [p.longitude, p.latitude],
      [_draftPts.first.longitude, _draftPts.first.latitude],
    ];
    try {
      final r = await Api.put('/admin/waters/$_shapeWaterId/shape', {'polygon': {'type': 'Polygon', 'coordinates': [coords]}});
      setState(() { _selWaterPoly = _ringFromGeo(r is Map ? r['polygon'] : null); _editShape = false; _shapeMsg = ''; });
      messenger.showSnackBar(SnackBar(content: Text(savedMsg)));
    } catch (e) { messenger.showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : failMsg))); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final detail = _zoom >= 12.5; // losse stek-/vangstpinnen pas bij ver inzoomen (anti-wirwar; stekken vind je via de dobber)
    // Stek-aantallen per water in ÉÉN keer berekenen (i.p.v. per dobber → veel sneller bij slepen).
    _spotCountByWater = {};
    for (final s in _spots) {
      if (s is Map && s['water_id'] != null && _spotPasses(s)) {
        _spotCountByWater[s['water_id']] = (_spotCountByWater[s['water_id']] ?? 0) + 1;
      }
    }

    // Drukte-kleurzones over de kaart.
    final circles = _busy.where((b) => b['lat'] != null).map((b) {
      final level = '${b['level'] ?? 'low'}';
      final r = level == 'high' ? 1500.0 : level == 'medium' ? 1000.0 : 600.0;
      return CircleMarker(point: LatLng(double.parse('${b['lat']}'), double.parse('${b['lng']}')),
        radius: r, useRadiusInMeter: true, color: _busyColor(level).withValues(alpha: 0.22), borderColor: _busyColor(level).withValues(alpha: 0.6), borderStrokeWidth: 1.5);
    }).toList();

    final markers = <Marker>[
      // (alle water-dobbers staan in de CLUSTER-laag, zie hieronder)
      // Drukte-badges met aantal.
      ..._busy.where((b) => b['lat'] != null).map((b) => Marker(
        point: LatLng(double.parse('${b['lat']}'), double.parse('${b['lng']}')),
        width: 44, height: 44,
        child: GestureDetector(onTap: () => _showBusy(b as Map), child: _busyBadge('${b['level'] ?? 'low'}', b['count'] ?? 0)))),
      // Stekken verschijnen pas als pins zodra je een dobber tikt (= het aangetikte water).
      ..._activeSpots.where((s) => s['latitude'] != null).map((s) => Marker(
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
        IconButton(icon: const Icon(Icons.search), tooltip: mui(context, 'search_place'), onPressed: _openPlaceSearch),
        IconButton(icon: const Icon(Icons.info_outline), tooltip: mui(context, 'legend_title'), onPressed: _showLegend),
        PopupMenuButton<String>(
          icon: const Icon(Icons.public),
          tooltip: mui(context, 'country'),
          onSelected: (c) { _map.move(_countries[c]!, _countryZoom(c)); _loadWaters(); _loadRegions(c); }, // naar het land + meteen waters laden
          itemBuilder: (_) => _countries.keys.map((c) => PopupMenuItem(value: c, child: Text(c))).toList(),
        ),
        TextButton.icon(
          onPressed: _toggleAuto,
          icon: Icon(_autoOn ? Icons.location_on : Icons.location_off, size: 18, color: _checkedIn ? AppColors.mint : Colors.white),
          label: Text(mui(context, _autoOn ? 'auto_on_label' : 'auto_off_label'), style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ]),
      // Knoppen alleen tonen als je niet in plaats-/teken-modus zit.
      floatingActionButton: (_placing != null || _editShape) ? null : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
        FloatingActionButton.small(
          heroTag: 'locateme', backgroundColor: Colors.white,
          onPressed: _centerOnUser,
          tooltip: mui(context, 'locate_me'),
          child: const Icon(Icons.my_location, color: AppColors.teal),
        ),
        const SizedBox(height: 10),
        FloatingActionButton.small(
          heroTag: 'addwater', backgroundColor: AppColors.shared,
          onPressed: () => setState(() => _placing = 'water'),
          tooltip: mui(context, 'add_water'),
          child: const Icon(Icons.water, color: Colors.white),
        ),
        const SizedBox(height: 10),
        FloatingActionButton.extended(
          heroTag: 'addspot', backgroundColor: AppColors.teal,
          onPressed: () => setState(() => _placing = 'spot'),
          icon: const Icon(Icons.add_location_alt, color: Colors.white),
          label: Text(context.tr('map.spot_here'), style: const TextStyle(color: Colors.white)),
        ),
      ]),
      body: Column(children: [
        // Filter voor stekken.
        SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(children: [
            for (final f in const ['all', 'public', 'friends'])
              Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(
                label: Text(mui(context, 'filter_$f')),
                selected: _spotFilter == f,
                onSelected: (_) => setState(() {
                  _spotFilter = f;
                  // Pins van het open water meteen opnieuw filteren (anders blijven oude pins staan).
                  if (_activeWaterId != null) _activeSpots = _spotsForWater(_activeWaterId);
                }),
                visualDensity: VisualDensity.compact,
              )),
          ])),
        // Stekken verschijnen pas zodra je voldoende inzoomt (tegen wirwar) — duidelijke hint op een
        // eigen regel zodat hij niet afkapt. Verdwijnt zodra je ingezoomd bent.
        if (!detail) Container(width: double.infinity, color: const Color(0xFFEFF4F3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Row(children: [
            const Icon(Icons.zoom_in, size: 15, color: Colors.black45),
            const SizedBox(width: 5),
            Expanded(child: Text(mui(context, 'spots_zoom_hint'), style: const TextStyle(fontSize: 12, color: Colors.black54))),
          ])),
        Expanded(child: Stack(children: [
          FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: _center, initialZoom: 14, // bij openen ingezoomd op de locatie van de gebruiker
            minZoom: _kMinZoom, maxZoom: 18, // niet verder uitzoomen dan ~regio-niveau (anti-hapering + niet wegglijden naar ander land)
            // Begrens de kaart tot Europa → je kunt niet meer "over de rand" de lege ruimte in sliden/uitzoomen.
            cameraConstraint: CameraConstraint.contain(
              bounds: LatLngBounds(const LatLng(34.0, -15.0), const LatLng(71.5, 42.0)),
            ),
            onMapReady: _loadWaters,
            onTap: (_, latlng) {
              if (_editShape) { setState(() => _draftPts = [..._draftPts, latlng]); return; } // intekenen: punt toevoegen
              if (_placing != null) return; // in plaats-modus richt je met het kruis; tik doet niets
              final w = _waterAtPoint(latlng);
              if (w != null) { // tik in de ingekleurde vorm → de STEKKEN van dat water tonen (dobber = info)
                setState(() { _activeWaterId = w['id']; _activeSpots = _spotsForWater(w['id']); });
                return;
              }
              if (_activeSpots.isNotEmpty) setState(() { _activeSpots = []; _activeWaterId = null; }); // lege kaart = stek-pins verbergen
            },
            onPositionChanged: (pos, _) {
              final z = pos.zoom;
              // Harde uitzoom-muur: geen terugveer. Zou de knijp-beweging onder 9 duwen, dan zet ik de
              // kaart meteen vast op 9 i.p.v. eerst verder uit te laten zoomen en terug te laten springen.
              if (z < _kMinZoom) { _zoom = _kMinZoom; _map.move(pos.center, _kMinZoom); return; }
              // Herteken meteen zodra je een marker-grens kruist (7 = waters, 12,5 = vangsten),
              // anders lopen de markers achter op je zoom.
              final crossed = (z >= 12.5) != (_zoom >= 12.5) || (z >= 12) != (_zoom >= 12) || (z >= 11) != (_zoom >= 11);
              _zoom = z;
              if (crossed && mounted) setState(() {});
              _moveDebounce?.cancel();
              _moveDebounce = Timer(const Duration(milliseconds: 600), _loadWaters);
            },
          ),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'nl.sbuilder.yessfish',
              tileProvider: CancellableNetworkTileProvider()), // annuleert off-screen tegels tijdens slepen = vloeiender
            CircleLayer(circles: circles),
            // Vergunning-regio's: gekleurde zones (elke zone = eigen vergunning), onder de wateren.
            if (!_editShape)
              PolygonLayer(polygons: [
                for (final reg in _permitRegions)
                  for (final ring in _geoRings(reg is Map ? reg['polygon'] : null))
                    if (ring.length >= 3)
                      Polygon(points: ring, color: _hexColor('${reg['color'] ?? '#94a3b8'}').withValues(alpha: 0.13),
                        borderColor: _hexColor('${reg['color'] ?? '#94a3b8'}'), borderStrokeWidth: 2),
              ]),
            // Alle ingetekende waters altijd opgelicht (vanaf zoom 11), ingekleurd per watertype.
            if (!_editShape && _zoom >= 11)
              PolygonLayer(polygons: [
                for (final w in _waters)
                  if (w['polygon'] != null)
                    () { final ring = _ringFromGeo(w['polygon']); final c = _typeColor('${w['type']}');
                      return Polygon(points: ring, color: c.withValues(alpha: 0.50), borderColor: c, borderStrokeWidth: 2.5); }(),
              ].where((p) => p.points.length >= 3).toList()),
            // Concept-vorm tijdens intekenen (oranje).
            if (_editShape && _draftPts.length >= 2)
              PolygonLayer(polygons: [Polygon(points: _draftPts, color: AppColors.accent.withValues(alpha: 0.10), borderColor: AppColors.accent, borderStrokeWidth: 2)]),
            // Eigen, simpele clustering (geen lib, geen animatie → geen wegzakken): ingezoomd (≥12) losse dobbers,
            // uitgezoomd nette bolletjes per gebied die op hun eigen plek blijven staan.
            MarkerLayer(markers: _clusterWaterMarkers()),
            MarkerLayer(markers: markers),
            // "Hier ben jij" — blauwe stip op de eigen GPS-locatie.
            if (_userPos != null)
              MarkerLayer(markers: [Marker(point: _userPos!, width: 24, height: 24, child: Container(
                decoration: BoxDecoration(color: const Color(0xFF2563EB), shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)]),
              ))]),
            // Hoekpunten tijdens intekenen — tik om te verwijderen.
            if (_editShape)
              MarkerLayer(markers: [
                for (final e in _draftPts.asMap().entries)
                  Marker(point: e.value, width: 30, height: 30, child: GestureDetector(
                    onTap: () => setState(() { final l = [..._draftPts]; l.removeAt(e.key); _draftPts = l; }),
                    child: Container(decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 3)]),
                      margin: const EdgeInsets.all(8)),
                  )),
              ]),
          ],
          ),
          // Midden-richtkruis: ALLEEN in plaats-modus (water/stek toevoegen). Schuif de kaart om te mikken.
          if (_placing != null) IgnorePointer(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Stack(alignment: Alignment.center, children: const [
              Icon(Icons.gps_fixed, size: 44, color: Colors.white),
              Icon(Icons.gps_fixed, size: 36, color: AppColors.accent),
            ]),
            Container(margin: const EdgeInsets.only(top: 2), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(6)),
              child: Text(mui(context, 'center_hint'), style: const TextStyle(fontSize: 10, color: AppColors.accent, fontWeight: FontWeight.w600))),
          ]))),
          // Plaats-modus bevestig-balk: schuif de kaart → Bevestig (of Mijn GPS / Annuleer).
          if (_placing != null) Positioned(left: 8, right: 8, bottom: 8, child: Card(
            child: Padding(padding: const EdgeInsets.all(12), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_placing == 'water' ? mui(context, 'place_water_hint') : mui(context, 'place_spot_hint'), style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: FilledButton.icon(onPressed: () => _confirmPlacement(false), icon: const Icon(Icons.check, size: 18), label: Text(mui(context, 'place_confirm')))),
                const SizedBox(width: 8),
                OutlinedButton.icon(onPressed: () => _confirmPlacement(true), icon: const Icon(Icons.my_location, size: 16), label: Text(mui(context, 'place_gps'))),
                const SizedBox(width: 4),
                TextButton(onPressed: () => setState(() => _placing = null), child: Text(mui(context, 'shape_cancel'))),
              ]),
            ])),
          )),
          // Teken-/bewerk-werkbalk (moderator) — tik op de kaart om punten te zetten, tik op een punt om 'm te wissen.
          if (_editShape) Positioned(left: 8, right: 8, bottom: 8, child: Card(
            child: Padding(padding: const EdgeInsets.all(10), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_shapeMsg.isNotEmpty ? _shapeMsg : mui(context, 'shape_hint'), style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: [
                OutlinedButton.icon(onPressed: _shapeHelp, icon: const Icon(Icons.help_outline, size: 16), label: Text(mui(context, 'shape_help'))),
                OutlinedButton.icon(onPressed: _fetchOsmShape, icon: const Icon(Icons.cloud_download_outlined, size: 16), label: Text(mui(context, 'shape_from_osm'))),
                OutlinedButton(onPressed: _draftPts.isEmpty ? null : () => setState(() => _draftPts = _draftPts.sublist(0, _draftPts.length - 1)), child: Text(mui(context, 'shape_undo'))),
                OutlinedButton(onPressed: _draftPts.isEmpty ? null : () => setState(() => _draftPts = []), child: Text(mui(context, 'shape_clear'))),
                FilledButton(onPressed: _saveShape, child: Text('${mui(context, 'shape_save')} (${_draftPts.length})')),
                TextButton(onPressed: () => setState(() { _editShape = false; _draftPts = []; _shapeMsg = ''; }), child: Text(mui(context, 'shape_cancel'))),
              ]),
            ])),
          )),
        ])),
      ]),
    );
  }
}
