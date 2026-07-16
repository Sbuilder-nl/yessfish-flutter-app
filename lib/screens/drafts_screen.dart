import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/api.dart';
import '../core/config.dart';
import 'quick_catch_screen.dart';

/// Concept-vangsten (snelvangst) die nog afgemaakt moeten worden.
class DraftsScreen extends StatefulWidget {
  const DraftsScreen({super.key});
  @override
  State<DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends State<DraftsScreen> {
  List _drafts = [];
  bool _loading = true;

  String get _lang => Localizations.localeOf(context).languageCode;
  String _t(Map<String, String> m) => m[_lang] ?? m['en'] ?? m['nl'] ?? '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await Api.get('/catches?drafts=1');
      _drafts = r is Map && r['data'] is List ? r['data'] as List : (r is List ? r : []);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _open(Map d) async {
    final done = await Navigator.push(context, MaterialPageRoute(builder: (_) => QuickCatchScreen(draftId: d['id'] as int?)));
    if (done == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_t(_title))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _drafts.isEmpty
              ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(_t(_empty), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey))))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _drafts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final d = _drafts[i] as Map;
                      final photos = (d['photos'] is List) ? d['photos'] as List : [];
                      final img = photos.isNotEmpty ? '${photos.first['url']}' : (d['photo_path']?.toString());
                      return Card(
                        child: ListTile(
                          leading: img != null
                              ? ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: img, width: 52, height: 52, fit: BoxFit.cover))
                              : Container(width: 52, height: 52, decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.bolt, color: AppColors.teal)),
                          title: Text(_t(_draftLabel)),
                          subtitle: Text('${photos.length} ${_t(_photos)} · ${(d['caught_at'] ?? '').toString().split('T').first}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _open(d),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

const _title = {'nl': 'Concepten', 'en': 'Drafts', 'de': 'Entwürfe', 'fr': 'Brouillons', 'es': 'Borradores', 'pl': 'Szkice'};
const _empty = {'nl': 'Geen concept-vangsten. Maak er een via Snelvangst.', 'en': 'No draft catches. Create one via Quick catch.', 'de': 'Keine Entwürfe. Erstelle einen über Schnellfang.', 'fr': 'Aucun brouillon. Créez-en un via Prise rapide.', 'es': 'Sin borradores. Crea uno con Captura rápida.', 'pl': 'Brak szkiców. Utwórz przez Szybki połów.'};
const _draftLabel = {'nl': 'Concept-vangst', 'en': 'Draft catch', 'de': 'Entwurf-Fang', 'fr': 'Prise brouillon', 'es': 'Captura borrador', 'pl': 'Szkic połowu'};
const _photos = {'nl': "foto's", 'en': 'photos', 'de': 'Fotos', 'fr': 'photos', 'es': 'fotos', 'pl': 'zdjęć'};
