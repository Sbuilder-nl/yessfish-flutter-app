// "Bedoel je …@gmail.com?" — typfout in het domein van een e-mailadres herkennen (07-10-2026).
// ZELFDE lijst en logica als de website: web/src/lib/email-typo.ts — houd ze gelijk. Alleen een suggestie.
const List<String> _bekend = ['gmail.com', 'googlemail.com', 'hotmail.com', 'hotmail.nl', 'hotmail.de', 'hotmail.fr', 'hotmail.be', 'hotmail.co.uk', 'outlook.com', 'outlook.nl', 'outlook.de', 'outlook.fr', 'outlook.be', 'live.nl', 'live.com', 'live.be', 'live.de', 'live.fr', 'yahoo.com', 'yahoo.de', 'yahoo.fr', 'yahoo.co.uk', 'icloud.com', 'me.com', 'mac.com', 'msn.com', 'aol.com', 'ziggo.nl', 'kpnmail.nl', 'kpnplanet.nl', 'planet.nl', 'home.nl', 'xs4all.nl', 'hetnet.nl', 'chello.nl', 'upcmail.nl', 'telfort.nl', 'tele2.nl', 'online.nl', 'quicknet.nl', 'zeelandnet.nl', 'telenet.be', 'skynet.be', 'proximus.be', 'gmx.de', 'gmx.net', 'gmx.at', 'web.de', 't-online.de', 'freenet.de', 'arcor.de', 'orange.fr', 'free.fr', 'wanadoo.fr', 'laposte.net', 'sfr.fr', 'wp.pl', 'o2.pl', 'onet.pl', 'interia.pl', 'op.pl', 'gazeta.pl', 'protonmail.com', 'proton.me', 'yessfish.com'];
const Map<String, String> _vast = {'gmail.nl': 'gmail.com', 'gmail.de': 'gmail.com', 'gmail.be': 'gmail.com', 'gmail.fr': 'gmail.com', 'gmail.co': 'gmail.com', 'gmal.com': 'gmail.com', 'gmai.com': 'gmail.com', 'gmial.com': 'gmail.com', 'gamil.com': 'gmail.com', 'gnail.com': 'gmail.com', 'gmaill.com': 'gmail.com', 'gmali.com': 'gmail.com', 'g-mail.com': 'gmail.com', 'gmail.cm': 'gmail.com', 'hotmai.com': 'hotmail.com', 'hotmal.com': 'hotmail.com', 'hotmil.com': 'hotmail.com', 'homail.com': 'hotmail.com', 'hotnail.com': 'hotmail.com', 'hotmail.con': 'hotmail.com', 'hotmal.nl': 'hotmail.nl', 'hotmai.nl': 'hotmail.nl', 'homail.nl': 'hotmail.nl', 'hotnail.nl': 'hotmail.nl', 'outlok.com': 'outlook.com', 'outloo.com': 'outlook.com', 'outlook.con': 'outlook.com', 'iclod.com': 'icloud.com', 'icoud.com': 'icloud.com', 'icloud.nl': 'icloud.com', 'iclould.com': 'icloud.com', 'yaho.com': 'yahoo.com', 'yahoo.nl': 'yahoo.com', 'zigo.nl': 'ziggo.nl', 'ziggo.com': 'ziggo.nl', 'kpnmail.com': 'kpnmail.nl', 'kpmail.nl': 'kpnmail.nl', 'kpnmai.nl': 'kpnmail.nl', 'xs4al.nl': 'xs4all.nl', 'tonline.de': 't-online.de', 't-online.com': 't-online.de'};
const int _kort = 7;

int _afstand(String a, String b) {
  final d = List.generate(a.length + 1, (i) => List<int>.generate(b.length + 1, (j) => i == 0 ? j : (j == 0 ? i : 0)));
  for (var i = 1; i <= a.length; i++) {
    for (var j = 1; j <= b.length; j++) {
      final k = a[i - 1] == b[j - 1] ? 0 : 1;
      var m = d[i - 1][j] + 1;
      if (d[i][j - 1] + 1 < m) m = d[i][j - 1] + 1;
      if (d[i - 1][j - 1] + k < m) m = d[i - 1][j - 1] + k;
      if (i > 1 && j > 1 && a[i - 1] == b[j - 2] && a[i - 2] == b[j - 1] && d[i - 2][j - 2] + 1 < m) m = d[i - 2][j - 2] + 1;
      d[i][j] = m;
    }
  }
  return d[a.length][b.length];
}

/// Verbeterd adres, of null als er niets lijkt mis te zijn.
String? emailSuggestie(String invoer) {
  final e = invoer.trim();
  final at = e.lastIndexOf('@');
  if (at < 1 || at == e.length - 1) return null;
  final lokaal = e.substring(0, at);
  var dom = e.substring(at + 1).toLowerCase().replaceAll(RegExp(r'\.+$'), '').replaceAll(RegExp(r'\.{2,}'), '.');
  if (!dom.contains('.') || _bekend.contains(dom)) return null;
  final uitgang = dom.replaceAll(RegExp(r'\.(con|cmo|ocm|comm|vom|xom|cpm|om)$'), '.com').replaceAll(RegExp(r'\.(nll|nk|bl)$'), '.nl');
  if (_bekend.contains(uitgang)) return '$lokaal@$uitgang';
  if (_vast.containsKey(dom)) return '$lokaal@${_vast[dom]}';
  if (_vast.containsKey(uitgang)) return '$lokaal@${_vast[uitgang]}';
  String? beste; var besteD = 99;
  for (final b in _bekend) {
    if (b.length < _kort) continue;
    final dd = _afstand(uitgang, b);
    if (dd < besteD) { besteD = dd; beste = b; }
  }
  final max = uitgang.length >= 10 ? 2 : 1;
  return (beste != null && besteD > 0 && besteD <= max) ? '$lokaal@$beste' : null;
}

const Map<String, List<String>> _tekst = {
  'nl': ['Bedoel je', 'Ja, aanpassen'], 'en': ['Did you mean', 'Yes, fix it'], 'de': ['Meintest du', 'Ja, ändern'],
  'fr': ['Vouliez-vous dire', 'Oui, corriger'], 'es': ['¿Quisiste decir', 'Sí, corregir'], 'pl': ['Czy chodziło o', 'Tak, popraw'],
};
List<String> emailSuggestieTekst(String locale) => _tekst[locale] ?? _tekst['en']!;
