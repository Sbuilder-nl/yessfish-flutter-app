import "package:yessfish/widgets/dobber_text.dart";
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../core/api.dart';
import '../core/config.dart';
import 'mijn_data_screen.dart';

/// Dobbers: saldo, kopen (Google Play / App Store in-app) en korte uitleg.
/// De aankoop wordt server-side geverifieerd vóór de dobbers worden bijgeschreven.
const Map<String, Map<String, String>> _stL = {
  'title': {'nl': 'Dobbers', 'en': 'Bobbers', 'de': 'Posen', 'fr': 'Flotteurs', 'es': 'Boyas', 'pl': 'Spławiki'},
  'balance': {'nl': 'Jouw dobbers', 'en': 'Your bobbers', 'de': 'Deine Posen', 'fr': 'Tes flotteurs', 'es': 'Tus boyas', 'pl': 'Twoje spławiki'},
  'buy': {'nl': 'Dobbers kopen', 'en': 'Buy bobbers', 'de': 'Posen kaufen', 'fr': 'Acheter des flotteurs', 'es': 'Comprar boyas', 'pl': 'Kup spławiki'},
  'buy_hint': {'nl': 'Direct meer dobbers? Betaal veilig via de app store.', 'en': 'Need bobbers right away? Pay securely via the app store.', 'de': 'Sofort mehr Posen? Sicher über den App-Store bezahlen.', 'fr': 'Des flotteurs tout de suite ? Paie via le store en toute sécurité.', 'es': '¿Boyas al instante? Paga seguro por la tienda.', 'pl': 'Spławiki od razu? Zapłać bezpiecznie przez sklep.'},
  'buying': {'nl': 'Bezig met kopen…', 'en': 'Purchasing…', 'de': 'Kauf läuft…', 'fr': 'Achat en cours…', 'es': 'Comprando…', 'pl': 'Kupowanie…'},
  'bought': {'nl': 'Gelukt — je dobbers zijn bijgeschreven! ⭐', 'en': 'Done — your bobbers have been added! ⭐', 'de': 'Geschafft — deine Posen sind gutgeschrieben! ⭐', 'fr': 'C’est fait — flotteurs ajoutées ! ⭐', 'es': '¡Listo — boyas añadidas! ⭐', 'pl': 'Gotowe — spławiki dodane! ⭐'},
  'store_na': {'nl': 'De app store is hier niet beschikbaar. Kopen kan ook op yessfish.com bij ⭐ Dobbers.', 'en': 'The app store isn’t available here. You can also buy on yessfish.com under ⭐ Bobbers.', 'de': 'Der App-Store ist hier nicht verfügbar. Kaufen geht auch auf yessfish.com unter ⭐ Posen.', 'fr': 'Le store n’est pas disponible ici. Tu peux aussi acheter sur yessfish.com (⭐).', 'es': 'La tienda no está disponible aquí. También puedes comprar en yessfish.com (⭐).', 'pl': 'Sklep jest tu niedostępny. Możesz też kupić na yessfish.com (⭐).'},
  'verify_fail': {'nl': 'De aankoop kon niet worden gecontroleerd. Neem contact op als je wel betaald hebt.', 'en': 'The purchase could not be verified. Contact us if you were charged.', 'de': 'Der Kauf konnte nicht geprüft werden. Melde dich, falls abgebucht wurde.', 'fr': 'Achat non vérifié. Contacte-nous si tu as été débité.', 'es': 'No se pudo verificar la compra. Contáctanos si se te cobró.', 'pl': 'Nie udało się zweryfikować zakupu. Skontaktuj się z nami.'},
  'don_t': {'nl': 'Dobbers doneren aan YessFish', 'en': 'Donate bobbers to YessFish', 'de': 'Posen an YessFish spenden', 'fr': 'Donner des \u00e9toiles \u00e0 YessFish', 'es': 'Donar boyas a YessFish', 'pl': 'Przeka\u017c spławiki YessFish'},
  'don_hint': {'nl': 'YessFish wat gunnen? Doneer dobbers uit je saldo!', 'en': 'Want to support YessFish? Donate bobbers from your balance!', 'de': 'YessFish unterst\u00fctzen? Spende Posen aus deinem Guthaben!', 'fr': 'Envie de soutenir YessFish ? Donne des \u00e9toiles !', 'es': 'Apoya YessFish: dona boyas de tu saldo.', 'pl': 'Wesprzyj YessFish \u2014 przeka\u017c spławiki!'},
  'don_ok': {'nl': 'Bedankt voor je donatie! \ud83d\udc9a', 'en': 'Thanks for your donation! \ud83d\udc9a', 'de': 'Danke f\u00fcr deine Spende! \ud83d\udc9a', 'fr': 'Merci pour ton don ! \ud83d\udc9a', 'es': '\u00a1Gracias por tu donaci\u00f3n! \ud83d\udc9a', 'pl': 'Dzi\u0119kujemy za wsparcie! \ud83d\udc9a'},
  'don_total': {'nl': 'door de community gedoneerd', 'en': 'donated by the community', 'de': 'von der Community gespendet', 'fr': 'donn\u00e9 par la communaut\u00e9', 'es': 'donado por la comunidad', 'pl': 'przekazane przez spo\u0142eczno\u015b\u0107'},
  'earn_t': {'nl': 'Gratis dobbers verdienen', 'en': 'Earn bobbers for free', 'de': 'Gratis Posen verdienen', 'fr': 'Gagner des flotteurs gratuitement', 'es': 'Gana boyas gratis', 'pl': 'Zdobywaj spławiki za darmo'},
  'earn_hint': {'nl': 'Vangsten openbaar delen, dieptedata doorgeven en compleet loggen levert elke dag dobbers op.', 'en': 'Sharing catches publicly, reporting depth data and complete logs earn bobbers every day.', 'de': 'Öffentliche Fänge, Tiefendaten und vollständige Logs bringen täglich Posen.', 'fr': 'Prises publiques, données de profondeur et logs complets rapportent chaque jour.', 'es': 'Capturas públicas, datos de profundidad y registros completos dan boyas a diario.', 'pl': 'Publiczne połowy, dane głębokości i pełne wpisy dają spławiki codziennie.'},
  'spend_t': {'nl': 'Dit kun je ermee doen', 'en': 'What you can spend them on', 'de': 'Dafür kannst du sie ausgeben', 'fr': 'À quoi les dépenser', 'es': 'En qué gastarlas', 'pl': 'Na co je wydać'},
  'spend_unlock': {'nl': 'Dieptelaag van een water ontgrendelen', 'en': 'Unlock a water’s depth layer', 'de': 'Tiefenkarte freischalten', 'fr': 'Débloquer la profondeur d’une eau', 'es': 'Desbloquear la profundidad', 'pl': 'Odblokuj głębokości wody'},
  'spend_analysis': {'nl': 'AI-wateranalyse', 'en': 'AI water analysis', 'de': 'KI-Gewässeranalyse', 'fr': 'Analyse IA de l’eau', 'es': 'Análisis IA del agua', 'pl': 'Analiza AI wody'},
  'spend_private': {'nl': 'Diepte-import privé houden', 'en': 'Keep a depth import private', 'de': 'Tiefen-Import privat halten', 'fr': 'Garder un import privé', 'es': 'Mantener un import privado', 'pl': 'Prywatny import głębokości'},
  'mydata': {'nl': 'Mijn data (fishfinder-import)', 'en': 'My data (fishfinder import)', 'de': 'Meine Daten (Echolot-Import)', 'fr': 'Mes données (import sondeur)', 'es': 'Mis datos (importar sonda)', 'pl': 'Moje dane (import echosondy)'},
};

String stt(BuildContext c, String k) {
  final l = Localizations.localeOf(c).languageCode;
  return _stL[k]?[l] ?? _stL[k]?['en'] ?? k;
}

class SterrenScreen extends StatefulWidget {
  const SterrenScreen({super.key});
  @override
  State<SterrenScreen> createState() => _SterrenScreenState();
}

class _SterrenScreenState extends State<SterrenScreen> {
  int _saldo = 0;
  int _donTotaal = 0;
  List<dynamic> _bundles = [];
  Map<String, ProductDetails> _producten = {};
  bool _storeOk = false;
  bool _busy = false;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  @override
  void initState() {
    super.initState();
    _load();
    // Aankoop-stream: elke afgeronde aankoop server-side verifiëren en dan pas afronden.
    _sub = InAppPurchase.instance.purchaseStream.listen(_onPurchases, onError: (_) {});
    _initStore();
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  Future<void> _load() async {
    try {
      final r = await Api.get('/store/bundles');
      if (mounted && r is Map) setState(() { _bundles = r['bundles'] ?? []; _saldo = (r['ai_points'] as num?)?.toInt() ?? 0; _donTotaal = (r['donated_total'] as num?)?.toInt() ?? 0; });
    } catch (_) {}
  }

  Future<void> _initStore() async {
    try {
      final ok = await InAppPurchase.instance.isAvailable();
      if (!ok) { if (mounted) setState(() => _storeOk = false); return; }
      final ids = <String>{'yf_stars_15', 'yf_stars_40', 'yf_stars_100'};
      final resp = await InAppPurchase.instance.queryProductDetails(ids);
      if (mounted) setState(() {
        _producten = {for (final p in resp.productDetails) p.id: p};
        _storeOk = _producten.isNotEmpty;
      });
    } catch (_) { if (mounted) setState(() => _storeOk = false); }
  }

  Future<void> _doneer(int n) async {
    try {
      await Api.post('/store/donate', {'stars': n});
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(stt(context, 'don_ok'))));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : '')));
    }
  }

  Future<void> _koop(String productId) async {
    final p = _producten[productId];
    if (p == null) return;
    setState(() => _busy = true);
    try {
      await InAppPurchase.instance.buyConsumable(purchaseParam: PurchaseParam(productDetails: p));
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> aankopen) async {
    for (final a in aankopen) {
      if (a.status == PurchaseStatus.purchased || a.status == PurchaseStatus.restored) {
        try {
          if (Platform.isAndroid) {
            await Api.post('/store/verify/play', {
              'product_id': a.productID,
              'purchase_token': a.verificationData.serverVerificationData,
            });
          } else {
            await Api.post('/store/verify/apple', {
              'receipt': a.verificationData.serverVerificationData,
              'transaction_id': a.purchaseID,
            });
          }
          if (a.pendingCompletePurchase) await InAppPurchase.instance.completePurchase(a);
          await _load();
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: DobberText(stt(context, 'bought'))));
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : stt(context, 'verify_fail'))));
        }
      } else if (a.status == PurchaseStatus.error || a.status == PurchaseStatus.canceled) {
        if (a.pendingCompletePurchase) await InAppPurchase.instance.completePurchase(a);
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: DobberText('⭐ ${stt(context, 'title')}')),
      body: RefreshIndicator(onRefresh: _load, child: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom + 16),
        children: [
          // Saldo
          Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
            Text(stt(context, 'balance'), style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            DobberText('⭐ $_saldo', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Color(0xFF1f8a70))),
          ]))),
          const SizedBox(height: 14),
          // Kopen
          Text('🛒 ${stt(context, 'buy')}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.navy)),
          const SizedBox(height: 4),
          Text(stt(context, 'buy_hint'), style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
          const SizedBox(height: 10),
          if (!_storeOk)
            Card(color: const Color(0xFFFFF7E0), child: Padding(padding: const EdgeInsets.all(14),
              child: DobberText(stt(context, 'store_na'), style: const TextStyle(fontSize: 13)))),
          if (_storeOk) Row(children: [
            for (final b in _bundles) ...[
              Expanded(child: _bundelKaart(b as Map)),
              if (b != _bundles.last) const SizedBox(width: 8),
            ],
          ]),
          if (_busy) const Padding(padding: EdgeInsets.only(top: 10), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))),
          const SizedBox(height: 14),
          // Doneren aan YessFish (Richards idee: het platform wat gunnen)
          Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('\ud83d\udc9a ${stt(context, 'don_t')}', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(stt(context, 'don_hint'), style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final n in const [1, 5, 10, 25])
                ActionChip(label: DobberText('\u2b50 $n'), onPressed: () => _doneer(n)),
            ]),
            const SizedBox(height: 6),
            DobberText('\u2b50 $_donTotaal ${stt(context, 'don_total')}', style: const TextStyle(fontSize: 11, color: Colors.black38)),
          ]))),
          const SizedBox(height: 18),
          // Verdienen + uitgeven (kort)
          Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('🎣 ${stt(context, 'earn_t')}', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(stt(context, 'earn_hint'), style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
            const Divider(height: 20),
            Text(stt(context, 'spend_t'), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            _regel('🗺️', stt(context, 'spend_unlock'), '10 ⭐'),
            _regel('🤖', stt(context, 'spend_analysis'), '5 ⭐'),
            _regel('🔒', stt(context, 'spend_private'), '5 ⭐'),
          ]))),
          const SizedBox(height: 10),
          Card(child: ListTile(
            leading: const Icon(Icons.upload_file_outlined, color: AppColors.teal),
            title: Text(stt(context, 'mydata'), style: const TextStyle(fontSize: 14.5)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MijnDataScreen())),
          )),
        ],
      )),
    );
  }

  Widget _bundelKaart(Map b) {
    final pid = '${b['product_id']}';
    final store = _producten[pid];
    final prijs = store?.price ?? '€ ${((b['amount_cents'] as num) / 100).toStringAsFixed(2).replaceAll('.', ',')}';
    return Card(child: InkWell(
      onTap: _busy ? null : () => _koop(pid),
      borderRadius: BorderRadius.circular(12),
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6), child: Column(children: [
        DobberText('⭐ ${b['bobbers']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1f8a70))),
        const SizedBox(height: 4),
        Text(prijs, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
      ])),
    ));
  }

  Widget _regel(String icoon, String tekst, String prijs) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Text(icoon), const SizedBox(width: 8),
      Expanded(child: Text(tekst, style: const TextStyle(fontSize: 13))),
      DobberText(prijs, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy)),
    ]),
  );
}
