import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/location.dart';

class BiteScreen extends StatefulWidget {
  const BiteScreen({super.key});
  @override
  State<BiteScreen> createState() => _BiteScreenState();
}

class _BiteScreenState extends State<BiteScreen> {
  Map? _data;
  bool _loading = true;
  String? _err;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _err = null; });
    try {
      final loc = await currentLocation();
      final r = await Api.get('/bite-forecast?lat=${loc.lat}&lng=${loc.lng}');
      setState(() { _data = r; _loading = false; });
    } catch (e) {
      setState(() { _err = 'Kon bijtkans niet laden'; _loading = false; });
    }
  }

  Color _labelColor(String? l) {
    switch (l) {
      case 'top': return const Color(0xFF16A34A);
      case 'good': return const Color(0xFF65A30D);
      case 'ok': return const Color(0xFFCA8A04);
      default: return const Color(0xFF9CA3AF);
    }
  }

  String _labelNl(String? l) => {'top': 'Topdag', 'good': 'Goede dag', 'ok': 'Redelijk', 'poor': 'Matig'}[l] ?? '';
  String _factorNl(String k) => {'solunar': 'Maanstand', 'pressure': 'Luchtdruk', 'wind': 'Wind', 'clouds': 'Bewolking', 'history': 'Jouw historie', 'community': 'In de buurt'}[k] ?? k;

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_err != null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_err!), TextButton(onPressed: _load, child: const Text('Opnieuw'))]));
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
          const Text('Bijtkans vandaag', style: TextStyle(color: Colors.black54)),
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
            child: Text('${weather['pressure_hpa']} hPa · ${(weather['wind_speed_ms'] as num?)?.round()} m/s · ${weather['clouds_pct']}% bewolking', style: const TextStyle(color: Colors.black45, fontSize: 12))),
        ]))),
        const SizedBox(height: 14),
        const Text('Factoren', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
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
          const Text('Bijtperiodes vandaag', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 8),
          ...windows.map((w) => Card(child: ListTile(
            dense: true,
            leading: Icon(w['type'] == 'major' ? Icons.star : Icons.star_border, color: AppColors.teal),
            title: Text('${w['start']} – ${w['end']}'),
            subtitle: Text(w['type'] == 'major' ? 'Topperiode' : 'Bijtperiode'),
          ))),
        ],
        if (species.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Kansrijk vandaag', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: species.map<Widget>((s) => Chip(label: Text('$s'), backgroundColor: Colors.white)).toList()),
        ],
        const SizedBox(height: 16),
        const Text('Op basis van maanstand, weer, jouw historie en vangsten in de buurt — indicatief.',
          style: TextStyle(color: Colors.black38, fontSize: 12)),
      ]),
    );
  }
}
