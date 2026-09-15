import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';
import '../core/gids_i18n.dart';

/// Pagina op de website openen in de app-browser (profiel van vereniging/winkel/jachthaven, partner worden, adverteren).
Future<void> openWebPagina(String pad) async {
  final lang = I18n.instance?.locale ?? 'nl';
  final url = Uri.parse('${Config.webOrigin}$pad${pad.contains('?') ? '&' : '?'}lang=$lang');
  try { await launchUrl(url, mode: LaunchMode.inAppBrowserView); } catch (_) { await launchUrl(url, mode: LaunchMode.externalApplication); }
}

/// Gids: verenigingen, winkels en jachthavens per land (zelfde gegevens als /verenigingen, /winkels, /jachthavens op de website).
class GidsScreen extends StatefulWidget {
  final int startTab;
  const GidsScreen({super.key, this.startTab = 0});
  @override
  State<GidsScreen> createState() => _GidsScreenState();
}

class _GidsScreenState extends State<GidsScreen> with SingleTickerProviderStateMixin {
  static const _types = ['clubs', 'shops', 'marinas'];
  late final TabController _tab = TabController(length: 3, vsync: this, initialIndex: widget.startTab);
  String _land = 'NL';
  final _q = TextEditingController();

  @override
  void initState() {
    super.initState();
    const perTaal = {'nl': 'NL', 'de': 'DE', 'fr': 'FR', 'es': 'ES', 'pl': 'PL', 'en': 'GB'};
    _land = perTaal[I18n.instance?.locale] ?? 'NL';
    _tab.addListener(() { if (!_tab.indexIsChanging) setState(() {}); });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<I18n>();
    return Scaffold(
      appBar: AppBar(
        title: Text(gt(context, 'title')),
        bottom: TabBar(controller: _tab, labelColor: Colors.white, unselectedLabelColor: Colors.white70, indicatorColor: AppColors.mint, tabs: [
          Tab(icon: const Icon(Icons.anchor, size: 18), text: gt(context, 'clubs')),
          Tab(icon: const Icon(Icons.storefront_outlined, size: 18), text: gt(context, 'shops')),
          Tab(icon: const Icon(Icons.sailing_outlined, size: 18), text: gt(context, 'marinas')),
        ]),
      ),
      body: TabBarView(controller: _tab, children: [for (final t in _types) _Lijst(key: ValueKey('$t-$_land'), type: t, land: _land, q: _q, onLand: (l) => setState(() => _land = l))]),
    );
  }
}

class _Lijst extends StatefulWidget {
  final String type; final String land; final TextEditingController q; final ValueChanged<String> onLand;
  const _Lijst({super.key, required this.type, required this.land, required this.q, required this.onLand});
  @override
  State<_Lijst> createState() => _LijstState();
}

class _LijstState extends State<_Lijst> with AutomaticKeepAliveClientMixin {
  List<dynamic>? _items; List<dynamic> _landen = []; bool _fout = false; String _zoek = '';
  @override bool get wantKeepAlive => true;

  @override
  void initState() { super.initState(); _laad(); }

  Future<void> _laad() async {
    setState(() { _fout = false; _items = null; });
    try {
      final r = await Future.wait([Api.get('/directory/${widget.type}/countries'), Api.get('/directory/${widget.type}?country=${widget.land}')]);
      if (!mounted) return;
      setState(() { _landen = (r[0] is Map ? r[0]['data'] : []) ?? []; _items = (r[1] is Map ? r[1]['data'] : []) ?? []; });
    } catch (_) { if (mounted) setState(() => _fout = true); }
  }

  String _landNaam(String code) {
    const n = {'NL': '🇳🇱 Nederland', 'BE': '🇧🇪 België', 'DE': '🇩🇪 Deutschland', 'FR': '🇫🇷 France', 'GB': '🇬🇧 United Kingdom', 'IE': '🇮🇪 Ireland', 'ES': '🇪🇸 España', 'PL': '🇵🇱 Polska', 'AT': '🇦🇹 Österreich', 'CH': '🇨🇭 Schweiz', 'CZ': '🇨🇿 Česko', 'IT': '🇮🇹 Italia', 'DK': '🇩🇰 Danmark', 'LU': '🇱🇺 Luxembourg', 'SE': '🇸🇪 Sverige', 'NO': '🇳🇴 Norge', 'FI': '🇫🇮 Suomi', 'PT': '🇵🇹 Portugal'};
    return n[code] ?? code;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final items = (_items ?? []).where((i) => _zoek.isEmpty || '${i['name']} ${i['region'] ?? ''}'.toLowerCase().contains(_zoek.toLowerCase())).toList();
    final landen = [..._landen];
    if (!landen.any((l) => l['code'] == widget.land)) landen.add({'code': widget.land, 'count': 0});
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 4), child: Row(children: [
        DropdownButton<String>(
          value: widget.land, underline: const SizedBox.shrink(),
          items: [for (final l in landen) DropdownMenuItem(value: '${l['code']}', child: Text('${_landNaam('${l['code']}')} (${l['count']})'))],
          onChanged: (v) { if (v != null) widget.onLand(v); },
        ),
        const SizedBox(width: 10),
        Expanded(child: TextField(
          controller: widget.q, onChanged: (v) => setState(() => _zoek = v.trim()),
          decoration: InputDecoration(isDense: true, prefixIcon: const Icon(Icons.search, size: 18), hintText: gt(context, 'search'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
        )),
      ])),
      Expanded(child: _fout
          ? Center(child: TextButton(onPressed: _laad, child: Text(gt(context, 'error'))))
          : _items == null
              ? Center(child: Text(gt(context, 'loading')))
              : items.isEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(gt(context, 'empty'), textAlign: TextAlign.center)))
                  : RefreshIndicator(onRefresh: _laad, child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final it = items[i];
                        final zelf = it['managed_by'] == 'self';
                        final n = (it['waters_count'] as num?)?.toInt() ?? 0;
                        final icoon = widget.type == 'clubs' ? (it['kind'] == 'club' ? Icons.groups_outlined : Icons.account_balance_outlined) : widget.type == 'shops' ? Icons.storefront_outlined : Icons.sailing_outlined;
                        return ListTile(
                          leading: CircleAvatar(backgroundColor: AppColors.teal.withValues(alpha: 0.1), child: it['logo'] != null ? ClipOval(child: Image.network('${it['logo']}', width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(icoon, color: AppColors.teal))) : Icon(icoon, color: AppColors.teal)),
                          title: Text('${it['name']}', maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text([if ((it['region'] ?? '').toString().isNotEmpty) '${it['region']}', if (n > 0) gt(context, 'waters', {'n': '$n'}), zelf ? gt(context, 'managed_self') : gt(context, 'managed_yf')].join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: it['href'] != null ? () => openWebPagina('${it['href']}') : null,
                        );
                      },
                    ))),
    ]);
  }
}
