// 07-10-2026 Richard: "wachtwoord wijzigen moet zeker voor iedereen beschikbaar zijn op YessFish die een account heeft".
// Zelfde als de website (Instellingen > Wachtwoord wijzigen): POST /auth/change-password. Wie via Google inlogt en nog
// geen wachtwoord heeft (has_password = false), stelt er hier een in zonder huidig wachtwoord.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';

const Map<String, Map<String, String>> _t = {
  'nl': {'titel': 'Wachtwoord wijzigen', 'titel_nieuw': 'Wachtwoord instellen', 'uitleg_nieuw': 'Je logt nu in met Google. Stel een wachtwoord in om ook met je e-mailadres in te loggen.', 'huidig': 'Huidig wachtwoord', 'nieuw': 'Nieuw wachtwoord', 'herhaal': 'Herhaal nieuw wachtwoord', 'eis': 'Minimaal 8 tekens, met letters en cijfers.', 'knop': 'Opslaan', 'klaar': 'Je wachtwoord is aangepast. Op andere apparaten moet je opnieuw inloggen.', 'ongelijk': 'De twee nieuwe wachtwoorden zijn niet gelijk.', 'kort': 'Minimaal 8 tekens, met letters en cijfers.', 'fout': 'Opslaan is niet gelukt.'},
  'en': {'titel': 'Change password', 'titel_nieuw': 'Set a password', 'uitleg_nieuw': 'You sign in with Google. Set a password to also sign in with your email address.', 'huidig': 'Current password', 'nieuw': 'New password', 'herhaal': 'Repeat new password', 'eis': 'At least 8 characters, with letters and numbers.', 'knop': 'Save', 'klaar': 'Your password has been changed. You will need to sign in again on other devices.', 'ongelijk': 'The two new passwords do not match.', 'kort': 'At least 8 characters, with letters and numbers.', 'fout': 'Saving failed.'},
  'de': {'titel': 'Passwort ändern', 'titel_nieuw': 'Passwort festlegen', 'uitleg_nieuw': 'Du meldest dich mit Google an. Lege ein Passwort fest, um dich auch mit deiner E-Mail-Adresse anzumelden.', 'huidig': 'Aktuelles Passwort', 'nieuw': 'Neues Passwort', 'herhaal': 'Neues Passwort wiederholen', 'eis': 'Mindestens 8 Zeichen, mit Buchstaben und Zahlen.', 'knop': 'Speichern', 'klaar': 'Dein Passwort wurde geändert. Auf anderen Geräten musst du dich neu anmelden.', 'ongelijk': 'Die beiden neuen Passwörter stimmen nicht überein.', 'kort': 'Mindestens 8 Zeichen, mit Buchstaben und Zahlen.', 'fout': 'Speichern fehlgeschlagen.'},
  'fr': {'titel': 'Changer le mot de passe', 'titel_nieuw': 'Définir un mot de passe', 'uitleg_nieuw': 'Vous vous connectez avec Google. Définissez un mot de passe pour vous connecter aussi avec votre adresse e-mail.', 'huidig': 'Mot de passe actuel', 'nieuw': 'Nouveau mot de passe', 'herhaal': 'Répéter le nouveau mot de passe', 'eis': 'Au moins 8 caractères, avec des lettres et des chiffres.', 'knop': 'Enregistrer', 'klaar': 'Votre mot de passe a été modifié. Vous devrez vous reconnecter sur vos autres appareils.', 'ongelijk': 'Les deux nouveaux mots de passe ne correspondent pas.', 'kort': 'Au moins 8 caractères, avec des lettres et des chiffres.', 'fout': 'L’enregistrement a échoué.'},
  'es': {'titel': 'Cambiar contraseña', 'titel_nieuw': 'Establecer contraseña', 'uitleg_nieuw': 'Inicias sesión con Google. Establece una contraseña para entrar también con tu correo electrónico.', 'huidig': 'Contraseña actual', 'nieuw': 'Nueva contraseña', 'herhaal': 'Repite la nueva contraseña', 'eis': 'Mínimo 8 caracteres, con letras y números.', 'knop': 'Guardar', 'klaar': 'Tu contraseña se ha cambiado. En otros dispositivos tendrás que volver a iniciar sesión.', 'ongelijk': 'Las dos contraseñas nuevas no coinciden.', 'kort': 'Mínimo 8 caracteres, con letras y números.', 'fout': 'No se ha podido guardar.'},
  'pl': {'titel': 'Zmień hasło', 'titel_nieuw': 'Ustaw hasło', 'uitleg_nieuw': 'Logujesz się przez Google. Ustaw hasło, aby logować się także adresem e-mail.', 'huidig': 'Obecne hasło', 'nieuw': 'Nowe hasło', 'herhaal': 'Powtórz nowe hasło', 'eis': 'Co najmniej 8 znaków, litery i cyfry.', 'knop': 'Zapisz', 'klaar': 'Hasło zostało zmienione. Na innych urządzeniach musisz zalogować się ponownie.', 'ongelijk': 'Nowe hasła nie są takie same.', 'kort': 'Co najmniej 8 znaków, litery i cyfry.', 'fout': 'Nie udało się zapisać.'},
};

String wwT(BuildContext c, String k) {
  final l = Provider.of<I18n>(c, listen: false).locale;
  return _t[l]?[k] ?? _t['nl']![k] ?? k;
}

class WachtwoordScreen extends StatefulWidget {
  const WachtwoordScreen({super.key});
  @override
  State<WachtwoordScreen> createState() => _WachtwoordScreenState();
}

class _WachtwoordScreenState extends State<WachtwoordScreen> {
  final _huidig = TextEditingController(), _nieuw = TextEditingController(), _herhaal = TextEditingController();
  bool? _heeft;              // null = nog laden
  bool _busy = false, _toon = false;
  String? _fout;

  @override
  void initState() {
    super.initState();
    Api.get('/auth/me').then((r) {
      final d = (r is Map && r['data'] is Map) ? r['data'] : r;
      if (mounted) setState(() => _heeft = (d is Map && d['has_password'] == false) ? false : true);
    }).catchError((_) { if (mounted) setState(() => _heeft = true); });
  }

  @override
  void dispose() { _huidig.dispose(); _nieuw.dispose(); _herhaal.dispose(); super.dispose(); }

  bool _sterk(String s) => s.length >= 8 && RegExp(r'[A-Za-z]').hasMatch(s) && RegExp(r'\d').hasMatch(s);

  Future<void> _opslaan() async {
    setState(() => _fout = null);
    if (!_sterk(_nieuw.text)) { setState(() => _fout = wwT(context, 'kort')); return; }
    if (_nieuw.text != _herhaal.text) { setState(() => _fout = wwT(context, 'ongelijk')); return; }
    setState(() => _busy = true);
    try {
      await Api.post('/auth/change-password', {
        if (_heeft == true) 'current_password': _huidig.text,
        'password': _nieuw.text, 'password_confirmation': _herhaal.text,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(wwT(context, 'klaar'))));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _fout = e is ApiException ? e.message : wwT(context, 'fout'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _dec(String label) => InputDecoration(labelText: label, border: const OutlineInputBorder(),
      suffixIcon: IconButton(icon: Icon(_toon ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _toon = !_toon)));

  @override
  Widget build(BuildContext context) {
    final heeft = _heeft;
    return Scaffold(
      appBar: AppBar(title: Text(wwT(context, heeft == false ? 'titel_nieuw' : 'titel'))),
      body: heeft == null ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.all(16) + EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        children: [
          if (!heeft) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(wwT(context, 'uitleg_nieuw'), style: const TextStyle(color: Colors.black54))),
          if (heeft) ...[
            TextField(key: const Key('ww-huidig'), controller: _huidig, obscureText: !_toon, autofillHints: const [AutofillHints.password], decoration: _dec(wwT(context, 'huidig'))),
            const SizedBox(height: 12),
          ],
          TextField(key: const Key('ww-nieuw'), controller: _nieuw, obscureText: !_toon, autofillHints: const [AutofillHints.newPassword], decoration: _dec(wwT(context, 'nieuw'))),
          const SizedBox(height: 12),
          TextField(key: const Key('ww-herhaal'), controller: _herhaal, obscureText: !_toon, autofillHints: const [AutofillHints.newPassword], decoration: _dec(wwT(context, 'herhaal'))),
          const SizedBox(height: 8),
          Text(wwT(context, 'eis'), style: const TextStyle(fontSize: 12, color: Colors.black45)),
          if (_fout != null) Padding(padding: const EdgeInsets.only(top: 12), child: Container(
            padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
            child: Text(_fout!, style: TextStyle(color: Colors.red.shade800)))),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.teal, padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: _busy ? null : _opslaan,
            child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(wwT(context, 'knop')),
          ),
        ],
      ),
    );
  }
}
