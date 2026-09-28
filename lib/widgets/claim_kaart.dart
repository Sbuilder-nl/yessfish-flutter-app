import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';

/// "Dit is mijn winkel / Dit is onze vereniging": een pagina die YessFish beheert, kan de eigenaar zelf
/// overnemen. Het lid vult kort in wie hij is; een admin keurt eerst goed (Richard 25-09 + 28-09-2026:
/// "knop voor beide houden"). Zelfde teksten en velden als op het web (ClaimBox.tsx).
class ClaimKaart extends StatefulWidget {
  final String slug;
  final String type;
  final VoidCallback onDone;
  const ClaimKaart({super.key, required this.slug, required this.type, required this.onDone});
  @override
  State<ClaimKaart> createState() => _ClaimKaartState();
}

const Map<String, Map<String, String>> _t = {
  'claim_btn': {'nl': 'Dit is mijn winkel — beheer deze pagina zelf', 'en': 'This is my shop — manage this page yourself', 'de': 'Das ist mein Laden — diese Seite selbst verwalten', 'fr': 'C’est mon magasin — gérer cette page moi-même', 'es': 'Esta es mi tienda — gestionar esta página yo mismo', 'pl': 'To mój sklep — zarządzaj tą stroną sam'},
  'claim_btn_club': {'nl': 'Dit is onze vereniging — beheer deze pagina zelf', 'en': 'This is our club — manage this page yourself', 'de': 'Das ist unser Verein — diese Seite selbst verwalten', 'fr': 'C’est notre association — gérer cette page nous-mêmes', 'es': 'Este es nuestro club — gestionar esta página nosotros', 'pl': 'To nasz klub — zarządzajcie tą stroną sami'},
  'claim_title': {'nl': 'Deze pagina zelf beheren', 'en': 'Manage this page yourself', 'de': 'Diese Seite selbst verwalten', 'fr': 'Gérer cette page vous-même', 'es': 'Gestionar esta página tú mismo', 'pl': 'Zarządzaj tą stroną sam'},
  'claim_intro': {'nl': 'Vertel ons wie je bent. We controleren het kort en maken je daarna eigenaar van de pagina: dan pas je zelf gegevens, openingstijden en aanbiedingen aan.', 'en': 'Tell us who you are. We check it briefly and then make you owner of the page, so you can update details, opening hours and offers yourself.', 'de': 'Sag uns, wer du bist. Wir prüfen das kurz und machen dich dann zum Inhaber der Seite, damit du Angaben, Öffnungszeiten und Angebote selbst pflegen kannst.', 'fr': 'Dites-nous qui vous êtes. Nous vérifions rapidement puis vous devenez propriétaire de la page : vous gérez alors vous-même les coordonnées, horaires et offres.', 'es': 'Cuéntanos quién eres. Lo comprobamos brevemente y te hacemos propietario de la página, para que actualices tú mismo los datos, el horario y las ofertas.', 'pl': 'Powiedz nam, kim jesteś. Krótko to sprawdzimy i uczynimy cię właścicielem strony — wtedy sam aktualizujesz dane, godziny otwarcia i oferty.'},
  'claim_role': {'nl': 'Jouw rol', 'en': 'Your role', 'de': 'Deine Rolle', 'fr': 'Votre rôle', 'es': 'Tu función', 'pl': 'Twoja rola'},
  'claim_role_ph': {'nl': 'Bijvoorbeeld eigenaar of bedrijfsleider', 'en': 'For example owner or manager', 'de': 'Zum Beispiel Inhaber oder Filialleiter', 'fr': 'Par exemple propriétaire ou gérant', 'es': 'Por ejemplo propietario o encargado', 'pl': 'Na przykład właściciel lub kierownik'},
  'claim_phone': {'nl': 'Telefoon (voor een korte controle, niet verplicht)', 'en': 'Phone (for a quick check, optional)', 'de': 'Telefon (für eine kurze Prüfung, optional)', 'fr': 'Téléphone (pour une vérification rapide, facultatif)', 'es': 'Teléfono (para una comprobación rápida, opcional)', 'pl': 'Telefon (do krótkiej weryfikacji, opcjonalnie)'},
  'claim_note': {'nl': 'Toelichting (niet verplicht)', 'en': 'Note (optional)', 'de': 'Anmerkung (optional)', 'fr': 'Remarque (facultatif)', 'es': 'Comentario (opcional)', 'pl': 'Uwagi (opcjonalnie)'},
  'claim_send': {'nl': 'Aanvraag versturen', 'en': 'Send request', 'de': 'Anfrage senden', 'fr': 'Envoyer la demande', 'es': 'Enviar solicitud', 'pl': 'Wyślij prośbę'},
  'annuleer': {'nl': 'Annuleren', 'en': 'Cancel', 'de': 'Abbrechen', 'fr': 'Annuler', 'es': 'Cancelar', 'pl': 'Anuluj'},
};

class _ClaimKaartState extends State<ClaimKaart> {
  bool _open = false, _bezig = false;
  String? _fout;
  final _rol = TextEditingController(), _tel = TextEditingController(), _noot = TextEditingController();

  @override
  void dispose() { _rol.dispose(); _tel.dispose(); _noot.dispose(); super.dispose(); }

  String t(String k) { final loc = Provider.of<I18n>(context, listen: false).locale; return _t[k]?[loc] ?? _t[k]?['en'] ?? k; }

  Future<void> _stuur() async {
    if (_rol.text.trim().isEmpty) return;
    setState(() { _bezig = true; _fout = null; });
    try {
      await Api.post('/partners/${widget.slug}/claim', {
        'role': _rol.text.trim(),
        'phone': _tel.text.trim().isEmpty ? null : _tel.text.trim(),
        'body': _noot.text.trim().isEmpty ? null : _noot.text.trim(),
      });
      widget.onDone();
    } catch (e) {
      if (mounted) setState(() => _fout = e is ApiException ? e.message : '$e');
    }
    if (mounted) setState(() => _bezig = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_open) {
      return SizedBox(width: double.infinity, child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF075985), side: const BorderSide(color: Color(0xFF7DD3FC))),
        icon: const Icon(Icons.verified_outlined, size: 18),
        label: Text(t(widget.type == 'club' ? 'claim_btn_club' : 'claim_btn'), textAlign: TextAlign.center),
        onPressed: () => setState(() => _open = true),
      ));
    }
    InputDecoration veld(String label, {String? hint}) => InputDecoration(labelText: label, hintText: hint, isDense: true, border: const OutlineInputBorder());
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFF7DD3FC)), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t('claim_title'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
        const SizedBox(height: 4),
        Text(t('claim_intro'), style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.35)),
        const SizedBox(height: 10),
        TextField(controller: _rol, maxLength: 100, decoration: veld(t('claim_role'), hint: t('claim_role_ph')), onChanged: (_) => setState(() {})),
        TextField(controller: _tel, maxLength: 40, keyboardType: TextInputType.phone, decoration: veld(t('claim_phone'))),
        TextField(controller: _noot, maxLength: 2000, maxLines: 3, decoration: veld(t('claim_note'))),
        if (_fout != null) Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(_fout!, style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)))),
        Row(children: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
            onPressed: (_bezig || _rol.text.trim().isEmpty) ? null : _stuur,
            child: _bezig ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(t('claim_send'))),
          const SizedBox(width: 8),
          TextButton(onPressed: _bezig ? null : () => setState(() => _open = false), child: Text(t('annuleer'))),
        ]),
      ]),
    );
  }
}
