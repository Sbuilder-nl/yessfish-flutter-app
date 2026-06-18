import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/location.dart';
import '../core/i18n.dart';

class BiteScreen extends StatefulWidget {
  const BiteScreen({super.key});
  @override
  State<BiteScreen> createState() => _BiteScreenState();
}

class _BiteScreenState extends State<BiteScreen> {
  Map? _data;
  Map? _sol;
  bool _loading = true;
  String? _err;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _err = null; });
    try {
      final loc = await currentLocation();
      final r = await Api.get('/bite-forecast?lat=${loc.lat}&lng=${loc.lng}');
      Map? sol;
      try { sol = await Api.get('/solunar?lat=${loc.lat}&lng=${loc.lng}') as Map?; } catch (_) {}
      setState(() { _data = r; _sol = sol; _loading = false; });
    } catch (e) {
      setState(() { _err = 'error'; _loading = false; });
    }
  }

  static const _moonKeys = {
    'new': 'bite.moon_new', 'waxing_crescent': 'bite.moon_waxing_crescent', 'first_quarter': 'bite.moon_first_quarter',
    'waxing_gibbous': 'bite.moon_waxing_gibbous', 'full': 'bite.moon_full', 'waning_gibbous': 'bite.moon_waning_gibbous',
    'last_quarter': 'bite.moon_last_quarter', 'waning_crescent': 'bite.moon_waning_crescent',
  };
  String _moonName(String? phase) { final k = _moonKeys[phase]; return k != null ? context.tr(k) : context.tr('bite.moon'); }

  Color _labelColor(String? l) {
    switch (l) {
      case 'top': return const Color(0xFF16A34A);
      case 'good': return const Color(0xFF65A30D);
      case 'ok': return const Color(0xFFCA8A04);
      default: return const Color(0xFF9CA3AF);
    }
  }

  Widget _solItem(IconData ic, String label, String value) => Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(ic, color: AppColors.teal, size: 22), const SizedBox(height: 4),
    Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.black45), textAlign: TextAlign.center),
  ]);

  String _labelNl(String? l) { final k = {'top': 'bite.label_top', 'good': 'bite.label_good', 'ok': 'bite.label_ok', 'poor': 'bite.label_poor'}[l]; return k != null ? context.tr(k) : ''; }
  String _factorNl(String k) { final key = {'solunar': 'bite.factor_solunar', 'pressure': 'bite.factor_pressure', 'wind': 'bite.factor_wind', 'clouds': 'bite.factor_clouds', 'history': 'bite.factor_history', 'community': 'bite.factor_community'}[k]; return key != null ? context.tr(key) : k; }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_err != null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(context.tr('bite.load_error')), TextButton(onPressed: _load, child: Text(context.tr('bite.retry')))]));
    final d = _data!;
    final score = d['score'] ?? 0;
    final color = _labelColor(d['label']);
    final factors = (d['factors'] ?? []) as List;
    final windows = (d['best_windows'] ?? []) as List;
    final species = (d['species'] ?? []) as List;
    final weather = d['weather'] as Map?;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          Text(context.tr('bite.today'), style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          Container(width: 120, height: 120,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.12), border: Border.all(color: color, width: 4)),
            alignment: Alignment.center,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('$score', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: color)),
              const Text('/100', style: TextStyle(color: Colors.black45)),
            ])),
          const SizedBox(height: 10),
          Text(_labelNl(d['label']), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          if (weather != null) Padding(padding: const EdgeInsets.only(top: 8),
            child: Text('${weather['pressure_hpa']} hPa · ${(weather['wind_speed_ms'] as num?)?.round()} m/s · ${weather['clouds_pct']}% ${context.tr('bite.clouds')}', style: const TextStyle(color: Colors.black45, fontSize: 12))),
        ]))),
        if (_sol != null && (_sol!['sun'] != null || _sol!['moon'] != null)) ...[
          const SizedBox(height: 14),
          Text(context.tr('bite.sun_moon'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 8),
          Card(child: Padding(padding: const EdgeInsets.all(14), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _solItem(Icons.wb_sunny_outlined, context.tr('bite.sunrise'), _sol!['sun']?['rise']?.toString() ?? '—'),
            _solItem(Icons.nightlight_outlined, context.tr('bite.sunset'), _sol!['sun']?['set']?.toString() ?? '—'),
            _solItem(Icons.brightness_3, _moonName(_sol!['moon']?['phase']), _sol!['moon']?['illumination'] != null ? '${((_sol!['moon']['illumination'] as num) * (((_sol!['moon']['illumination'] as num) <= 1) ? 100 : 1)).round()}%' : '—'),
          ]))),
        ],
        const SizedBox(height: 14),
        Text(context.tr('bite.factors'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
        const SizedBox(height: 8),
        ...factors.map((f) {
          final s = (f['score'] ?? 0) as int;
          return Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
            SizedBox(width: 96, child: Text(_factorNl(f['key']), style: const TextStyle(fontSize: 13))),
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: s / 100, minHeight: 10, backgroundColor: const Color(0xFFE5E7EB), color: AppColors.teal))),
            SizedBox(width: 64, child: Text(' ${f['detail'] ?? ''}', style: const TextStyle(fontSize: 11, color: Colors.black45), overflow: TextOverflow.ellipsis)),
          ]));
        }),
        const SizedBox(height: 16),
        if (windows.isNotEmpty) ...[
          Text(context.tr('bite.windows'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 8),
          ...windows.map((w) => Card(child: ListTile(
            dense: true,
            leading: Icon(w['type'] == 'major' ? Icons.star : Icons.star_border, color: AppColors.teal),
            title: Text('${w['start']} – ${w['end']}'),
            subtitle: Text(w['type'] == 'major' ? context.tr('bite.window_major') : context.tr('bite.window_minor')),
          ))),
        ],
        if (species.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(context.tr('bite.likely_species'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: species.map<Widget>((s) => Chip(label: Text('$s'), backgroundColor: Colors.white)).toList()),
        ],
        const SizedBox(height: 16),
        Text(context.tr('bite.disclaimer'),
          style: const TextStyle(color: Colors.black38, fontSize: 12)),
      ]),
    );
  }
}
