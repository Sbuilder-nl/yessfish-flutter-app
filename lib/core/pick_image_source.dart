import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'i18n.dart';

/// Gedeelde camera/galerij-keuze. Toont een bottom-sheet en geeft de gekozen
/// bron terug (of null bij annuleren). Zo krijgt de gebruiker overal in de app
/// de keuze tussen een foto maken of uit de galerij kiezen.
const _camLbl = {'nl': 'Foto maken', 'en': 'Take photo', 'de': 'Foto aufnehmen', 'fr': 'Prendre une photo', 'es': 'Hacer foto', 'pl': 'Zrób zdjęcie'};
const _galLbl = {'nl': 'Uit galerij kiezen', 'en': 'Choose from gallery', 'de': 'Aus Galerie wählen', 'fr': 'Choisir dans la galerie', 'es': 'Elegir de la galería', 'pl': 'Wybierz z galerii'};

Future<ImageSource?> pickImageSource(BuildContext context) {
  String lang = 'nl';
  try { lang = Provider.of<I18n>(context, listen: false).flutterLocale.languageCode; } catch (_) {}
  String t(Map<String, String> m) => m[lang] ?? m['en'] ?? m['nl']!;
  return showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: const Icon(Icons.camera_alt),
          title: Text(t(_camLbl)),
          onTap: () => Navigator.pop(ctx, ImageSource.camera),
        ),
        ListTile(
          leading: const Icon(Icons.photo_library),
          title: Text(t(_galLbl)),
          onTap: () => Navigator.pop(ctx, ImageSource.gallery),
        ),
      ]),
    ),
  );
}
