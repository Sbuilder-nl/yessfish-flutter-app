import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/api.dart';
import '../core/units.dart';
import '../core/config.dart';
import '../core/i18n.dart';
import 'new_catch_screen.dart';
import 'catch_detail_screen.dart';

class CatchesScreen extends StatefulWidget {
  const CatchesScreen({super.key});
  @override
  State<CatchesScreen> createState() => _CatchesScreenState();
}

class _CatchesScreenState extends State<CatchesScreen> {
  List _catches = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await Api.get('/catches');
      setState(() { _catches = r['data'] ?? []; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.teal,
        onPressed: () async {
          final added = await Navigator.push(context, MaterialPageRoute(builder: (_) => const NewCatchScreen()));
          if (added == true) _load();
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(context.tr('catches.fab'), style: const TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _catches.isEmpty
              ? Center(child: Text(context.tr('catches.empty'), style: const TextStyle(color: Colors.black45)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _catches.length,
                    itemBuilder: (_, i) {
                      final c = _catches[i] as Map;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: c['photo_path'] != null
                              ? ClipRRect(borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(imageUrl: c['photo_path'], width: 52, height: 52, fit: BoxFit.cover))
                              : const CircleAvatar(backgroundColor: AppColors.bg, child: Icon(Icons.set_meal, color: AppColors.teal)),
                          title: Text(c['species'] ?? context.tr('catches.fish'), style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text([
                            if (c['weight_kg'] != null) Units.weight(c['weight_kg']),
                            if (c['length_cm'] != null) '${c['length_cm']} cm',
                            if (c['bait'] != null) c['bait'],
                          ].join(' · ')),
                          trailing: c['moon_phase'] != null ? const Icon(Icons.nightlight_round, size: 16, color: Colors.black26) : const Icon(Icons.chevron_right, color: Colors.black26),
                          onTap: () async { final ch = await Navigator.push(context, MaterialPageRoute(builder: (_) => CatchDetailScreen(catchId: c['id']))); if (ch == true) _load(); },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
