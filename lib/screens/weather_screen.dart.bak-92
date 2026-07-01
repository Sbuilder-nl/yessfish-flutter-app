import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/location.dart';
import '../core/i18n.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});
  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  Map? _w;
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final loc = await currentLocation(); final r = await Api.get('/weather?lat=${loc.lat}&lng=${loc.lng}'); setState(() { _w = r; _loading = false; }); }
    catch (_) { setState(() => _loading = false); }
  }
  Widget _tile(IconData ic, String label, String val) => Card(child: Padding(padding: const EdgeInsets.all(14),
    child: Column(children: [Icon(ic, color: AppColors.teal), const SizedBox(height: 6), Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(fontSize: 11, color: Colors.black45))])));
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(context.tr('weather.title'))),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _w == null ? Center(child: Text(context.tr('weather.no_data'))) : ListView(padding: const EdgeInsets.all(16), children: [
        Center(child: Text(_w!['location'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy))),
        Center(child: Text('${(_w!['temperature_c'] as num?)?.round()}°C — ${_w!['description'] ?? ''}', style: const TextStyle(fontSize: 16, color: Colors.black54))),
        const SizedBox(height: 16),
        GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.6, crossAxisSpacing: 10, mainAxisSpacing: 10, children: [
          _tile(Icons.speed, context.tr('weather.pressure'), '${_w!['pressure_hpa']} hPa'),
          _tile(Icons.air, context.tr('weather.wind'), '${(_w!['wind_speed_ms'] as num?)?.round()} m/s'),
          _tile(Icons.cloud, context.tr('weather.clouds'), '${_w!['clouds_pct']}%'),
          _tile(Icons.water_drop, context.tr('weather.humidity'), '${_w!['humidity']}%'),
        ]),
      ]));
  }
}
