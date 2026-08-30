import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/api.dart';
import '../core/config.dart';

/// Dieptekaart als eigen scherm (zelfde opzet als web, 31-08): alléén dit water,
/// vooraf gerenderde dieptekaart (RWS + community), je eigen stekken erop,
/// tik = diepte op die plek. Alleen bereikbaar als de laag ontgrendeld is.
class DieptekaartScreen extends StatefulWidget {
  final dynamic waterId;
  const DieptekaartScreen({super.key, required this.waterId});
  @override
  State<DieptekaartScreen> createState() => _DieptekaartScreenState();
}

class _DieptekaartScreenState extends State<DieptekaartScreen> {
  // API levert coördinaten soms als tekst (Laravel-decimals) — beide aankunnen.
  static double? _num(dynamic v) => v is num ? v.toDouble() : double.tryParse("$v");
  Uint8List? _png;
  LatLngBounds? _bounds;
  double _min = 0, _max = 0;
  String _naam = '';
  String _fout = '';
  final List<Map> _stekken = [];
  LatLng? _tik;
  double? _tikDiepte;
  bool _tikBezig = false;

  String get _lang => Localizations.localeOf(context).languageCode;
  String _t(Map<String, String> m) => m[_lang] ?? m['en'] ?? m['nl'] ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await Api.get('/waters/${widget.waterId}/depth-map');
      if (r is! Map || r['png'] == null) throw Exception('geen kaart');
      final b64 = (r['png'] as String).split(',').last;
      final b = r['bounds'];
      final bounds = LatLngBounds(
        LatLng((b[0][0] as num).toDouble(), (b[0][1] as num).toDouble()),
        LatLng((b[1][0] as num).toDouble(), (b[1][1] as num).toDouble()),
      );
      if (!mounted) return;
      setState(() {
        _png = base64Decode(b64);
        _bounds = bounds;
        _min = (r['min_depth'] as num).toDouble();
        _max = (r['max_depth'] as num).toDouble();
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _fout = e.message);
    } catch (_) {
      if (mounted) setState(() => _fout = _t(_geenKaart));
    }
    // naam + eigen stekken (alleen die binnen het kaartbeeld vallen)
    try {
      final w = await Api.get('/waters/${widget.waterId}');
      if (mounted && w is Map && w['name'] != null) setState(() => _naam = '${w['name']}');
    } catch (_) {}
    try {
      final s = await Api.get('/spots');
      final list = s is List ? s : (s['data'] ?? []);
      if (mounted && _bounds != null) {
        setState(() => _stekken.addAll(List<Map>.from((list as List).whereType<Map>().where((sp) {
          final la = _num(sp['latitude']), lo = _num(sp['longitude']);
          return la != null && lo != null && _bounds!.contains(LatLng(la, lo));
        }))));
      }
    } catch (_) {}
  }

  Future<void> _tikOp(LatLng p) async {
    setState(() { _tik = p; _tikDiepte = null; _tikBezig = true; });
    const c = 0.0012;
    try {
      final r = await Api.get('/depth/grid?minLat=${p.latitude - c}&minLng=${p.longitude - c}&maxLat=${p.latitude + c}&maxLng=${p.longitude + c}');
      final cells = (r is Map ? r['data'] : null) as List? ?? [];
      Map? best; double bd = 1e9;
      for (final x in cells.whereType<Map>()) {
        final dla = (x['lat'] as num).toDouble() - p.latitude;
        final dlo = (x['lng'] as num).toDouble() - p.longitude;
        final d2 = dla * dla + dlo * dlo;
        if (d2 < bd) { bd = d2; best = x; }
      }
      if (mounted) setState(() { _tikDiepte = best == null ? null : (best['depth'] as num).toDouble(); _tikBezig = false; });
    } catch (_) {
      if (mounted) setState(() { _tik = null; _tikBezig = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628), foregroundColor: Colors.white,
        title: Text('🌊 ${_naam.isEmpty ? _t(_titel) : _naam}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        actions: [if (_png != null) Padding(padding: const EdgeInsets.only(right: 12), child: Center(child: Text('${_min.toStringAsFixed(1)}–${_max.toStringAsFixed(1)} m', style: const TextStyle(fontSize: 13, color: Colors.white70))))],
      ),
      body: _fout.isNotEmpty
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_fout, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center)))
          : _png == null || _bounds == null
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Stack(children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCameraFit: CameraFit.bounds(bounds: _bounds!, padding: const EdgeInsets.all(36)),
                      maxZoom: 19,
                      onTap: (_, p) => _tikOp(p),
                    ),
                    children: [
                      TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'nl.sbuilder.yessfish'),
                      // omgeving dimmen zodat alleen het water eruit springt
                      PolygonLayer(polygons: [Polygon(points: [const LatLng(-85, -180), const LatLng(-85, 180), const LatLng(85, 180), const LatLng(85, -180)], color: const Color(0x730B1220))]),
                      OverlayImageLayer(overlayImages: [OverlayImage(bounds: _bounds!, imageProvider: MemoryImage(_png!))]),
                      MarkerLayer(markers: [
                        for (final sp in _stekken)
                          Marker(point: LatLng(_num(sp['latitude'])!, _num(sp['longitude'])!), width: 120, height: 58, alignment: Alignment.topCenter,
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                                child: Text('${sp['name']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.navy))),
                              const Icon(Icons.location_on, color: Color(0xFF1F8A70), size: 26),
                            ])),
                        if (_tik != null)
                          Marker(point: _tik!, width: 90, height: 54, alignment: Alignment.topCenter,
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(8)),
                                child: Text(_tikBezig ? '…' : (_tikDiepte == null ? '—' : '${_tikDiepte!.toStringAsFixed(1)} m'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white))),
                              Container(width: 12, height: 12, decoration: BoxDecoration(color: AppColors.navy, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
                            ])),
                      ]),
                    ],
                  ),
                  Positioned(left: 0, right: 0, bottom: 14, child: Center(child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .95), borderRadius: BorderRadius.circular(12)),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(_t(_tikHint), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black54)),
                      const SizedBox(height: 4),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('${_min.toStringAsFixed(1)} m', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                        Container(margin: const EdgeInsets.symmetric(horizontal: 8), width: 140, height: 10,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), gradient: const LinearGradient(colors: [Color(0xFFBAE6FD), Color(0xFF60A5FA), Color(0xFF2563EB), Color(0xFF1E40AF), Color(0xFF0F1946)]))),
                        Text('${_max.toStringAsFixed(1)} m', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                      ]),
                    ]),
                  ))),
                ]),
    );
  }
}

const _titel = {'nl': 'Dieptekaart', 'en': 'Depth map', 'de': 'Tiefenkarte', 'fr': 'Carte de profondeur', 'es': 'Mapa de profundidad', 'pl': 'Mapa głębokości'};
const _tikHint = {'nl': 'Tik op het water voor de diepte', 'en': 'Tap the water for the depth', 'de': 'Tippe aufs Wasser für die Tiefe', 'fr': 'Touche l’eau pour la profondeur', 'es': 'Toca el agua para la profundidad', 'pl': 'Dotknij wody, aby zobaczyć głębokość'};
const _geenKaart = {'nl': 'Nog geen dieptekaart voor dit water.', 'en': 'No depth map yet for this water.', 'de': 'Noch keine Tiefenkarte für dieses Gewässer.', 'fr': 'Pas encore de carte pour cette eau.', 'es': 'Aún no hay mapa para esta agua.', 'pl': 'Brak mapy głębokości dla tej wody.'};
