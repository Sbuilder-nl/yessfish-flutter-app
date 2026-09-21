import 'package:flutter/material.dart';
import '../core/config.dart';
import '../screens/handleiding_screen.dart';

/// Het vraagteken in de balk: uitleg over het scherm waar je nú bent.
///
/// Op de site zat dit al (Richard 21-09-2026: de vraagteken moet ook in de app he). Het opent
/// de handleiding meteen bij het bijbehorende hoofdstuk, dus met de schermafbeeldingen erbij —
/// niet de rondleiding die je door de echte app sleept.
class HulpKnop extends StatelessWidget {
  const HulpKnop({super.key, required this.hoofdstuk});

  /// Id van het hoofdstuk in de handleiding, bv. 'feed' of 'vangst'.
  final String hoofdstuk;

  static const _tip = {
    'nl': 'Uitleg over dit scherm', 'en': 'Help for this screen', 'de': 'Hilfe zu diesem Bildschirm',
    'fr': 'Aide pour cet écran', 'es': 'Ayuda de esta pantalla', 'pl': 'Pomoc do tego ekranu',
  };

  @override
  Widget build(BuildContext context) {
    final taal = Localizations.localeOf(context).languageCode;
    return IconButton(
      tooltip: _tip[taal] ?? _tip['en']!,
      icon: const Icon(Icons.help_outline, color: AppColors.mint),
      onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => HandleidingScreen(startHoofdstuk: hoofdstuk))),
    );
  }
}
