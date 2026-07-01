/// Gewicht wordt ALTIJD in kg opgeslagen; deze helper toont/rekent om naar de
/// voorkeurseenheid van het lid (kg of lb). Voorkeur wordt bij het opstarten
/// geladen uit /profile/settings en bijgewerkt als het lid het wijzigt.
class Units {
  static String unit = 'kg'; // 'kg' | 'lb'
  static bool get isLb => unit == 'lb';
  static String get label => isLb ? 'lb' : 'kg';

  static const double _kgToLb = 2.20462;

  /// Een in kg opgeslagen gewicht tonen in de voorkeurseenheid (bv. "6,4 kg" / "14.1 lb").
  static String weight(dynamic kg) {
    final v = kg is num ? kg.toDouble() : double.tryParse('$kg');
    if (v == null) return '';
    final out = isLb ? v * _kgToLb : v;
    final s = out % 1 == 0 ? out.toStringAsFixed(0) : out.toStringAsFixed(1);
    return '$s $label';
  }

  /// Een ingevoerde waarde (in de voorkeurseenheid) omzetten naar kg voor opslag.
  static double? toKg(String input) {
    final v = double.tryParse(input.replaceAll(',', '.'));
    if (v == null) return null;
    return isLb ? v / _kgToLb : v;
  }
}
