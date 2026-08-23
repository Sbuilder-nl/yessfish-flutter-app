import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/pick_image_source.dart';
import '../core/api.dart';
import '../core/auth.dart';
import '../core/config.dart';
import '../core/i18n.dart';
import '../widgets/avatar.dart';

/// Profiel bewerken — uitgebreid (Richard 23-08): naast naam/bio/avatar nu ook
/// achternaam, woonplaats, land, ervaring, profielkleur en omslagfoto.
/// Vertalingen lokaal (zelfde patroon als map_l10n) zodat alle 6 talen kloppen.
const Map<String, Map<String, String>> _epL = {
  'last_name': {'nl': 'Achternaam', 'en': 'Last name', 'de': 'Nachname', 'fr': 'Nom', 'es': 'Apellido', 'pl': 'Nazwisko'},
  'city': {'nl': 'Woonplaats', 'en': 'City', 'de': 'Wohnort', 'fr': 'Ville', 'es': 'Ciudad', 'pl': 'Miejscowość'},
  'country': {'nl': 'Land', 'en': 'Country', 'de': 'Land', 'fr': 'Pays', 'es': 'País', 'pl': 'Kraj'},
  'experience': {'nl': 'Viservaring', 'en': 'Fishing experience', 'de': 'Angel-Erfahrung', 'fr': 'Expérience de pêche', 'es': 'Experiencia de pesca', 'pl': 'Doświadczenie wędkarskie'},
  'exp_beginner': {'nl': 'Beginner', 'en': 'Beginner', 'de': 'Anfänger', 'fr': 'Débutant', 'es': 'Principiante', 'pl': 'Początkujący'},
  'exp_intermediate': {'nl': 'Gevorderd', 'en': 'Intermediate', 'de': 'Fortgeschritten', 'fr': 'Intermédiaire', 'es': 'Intermedio', 'pl': 'Średniozaawansowany'},
  'exp_advanced': {'nl': 'Ervaren', 'en': 'Advanced', 'de': 'Erfahren', 'fr': 'Avancé', 'es': 'Avanzado', 'pl': 'Zaawansowany'},
  'exp_expert': {'nl': 'Expert', 'en': 'Expert', 'de': 'Experte', 'fr': 'Expert', 'es': 'Experto', 'pl': 'Ekspert'},
  'color': {'nl': 'Profielkleur', 'en': 'Profile colour', 'de': 'Profilfarbe', 'fr': 'Couleur du profil', 'es': 'Color del perfil', 'pl': 'Kolor profilu'},
  'cover': {'nl': 'Omslagfoto', 'en': 'Cover photo', 'de': 'Titelbild', 'fr': 'Photo de couverture', 'es': 'Foto de portada', 'pl': 'Zdjęcie w tle'},
  'cover_pick': {'nl': 'Omslagfoto kiezen', 'en': 'Choose cover photo', 'de': 'Titelbild wählen', 'fr': 'Choisir la couverture', 'es': 'Elegir portada', 'pl': 'Wybierz zdjęcie w tle'},
  'more_settings': {'nl': 'Meer instellingen (privacy, taal, meldingen) vind je bij Instellingen.', 'en': 'More options (privacy, language, notifications) are in Settings.', 'de': 'Mehr Optionen (Privatsphäre, Sprache, Mitteilungen) findest du in den Einstellungen.', 'fr': 'Plus d’options (confidentialité, langue, notifications) dans Réglages.', 'es': 'Más opciones (privacidad, idioma, avisos) en Ajustes.', 'pl': 'Więcej opcji (prywatność, język, powiadomienia) w Ustawieniach.'},
};

String _ep(BuildContext c, String k) {
  final l = Localizations.localeOf(c).languageCode;
  return _epL[k]?[l] ?? _epL[k]?['en'] ?? k;
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _bio = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();
  String? _experience;
  String? _profileColor;
  String? _avatar;
  String? _avatarPath;
  String? _coverUrl;
  String? _coverPath;
  bool _saving = false;

  static const _kleuren = ['#0a3d62', '#1f8a70', '#2563eb', '#7c3aed', '#db2777', '#ea580c', '#ca8a04', '#16a34a'];

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthState>().user;
    _first.text = u?.firstName ?? '';
    _avatar = u?.avatarPath;
    _laadProfiel();
  }

  /// Volledige profielgegevens ophalen (het lokale user-model kent niet alle velden).
  Future<void> _laadProfiel() async {
    try {
      final r = await Api.get('/auth/me');
      final u = (r is Map ? (r['data'] ?? r) : {}) as Map;
      if (!mounted) return;
      setState(() {
        _first.text = '${u['first_name'] ?? _first.text}';
        _last.text = '${u['last_name'] ?? ''}';
        _bio.text = '${u['bio'] ?? ''}';
        _city.text = '${u['city'] ?? ''}';
        _country.text = '${u['country'] ?? ''}';
        _experience = u['fishing_experience'];
        _profileColor = u['profile_color'];
        _coverUrl = u['cover_path'] != null ? '${u['cover_path']}' : null;
      });
    } catch (_) {}
  }

  Future<void> _pickAvatar() async {
    final src = await pickImageSource(context); if (src == null) return;
    final x = await ImagePicker().pickImage(source: src, maxWidth: 800, imageQuality: 85);
    if (x == null) return;
    try { final r = await Api.uploadImage(x.path); setState(() => _avatar = r['url']); _avatarPath = r['path']; } catch (_) {}
  }

  Future<void> _pickCover() async {
    final src = await pickImageSource(context); if (src == null) return;
    final x = await ImagePicker().pickImage(source: src, maxWidth: 1600, imageQuality: 85);
    if (x == null) return;
    try { final r = await Api.uploadImage(x.path); setState(() => _coverUrl = r['url']); _coverPath = r['path']; } catch (_) {}
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final nav = Navigator.of(context);
      final auth = context.read<AuthState>();
      await Api.put('/profile', {
        'first_name': _first.text.trim(),
        'last_name': _last.text.trim(),
        if (_bio.text.isNotEmpty) 'bio': _bio.text.trim(),
        'city': _city.text.trim(),
        'country': _country.text.trim(),
        if (_experience != null) 'fishing_experience': _experience,
        if (_profileColor != null) 'profile_color': _profileColor,
        if (_avatarPath != null) 'avatar_path': _avatarPath,
        if (_coverPath != null) 'cover_path': _coverPath,
      });
      await auth.refresh();
      nav.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'Error')));
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AuthState>().user;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('editprofile.title'))),
      body: ListView(padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom + 16), children: [
        // Omslagfoto + avatar erbovenop (zoals het profiel eruitziet)
        SizedBox(height: 150, child: Stack(children: [
          GestureDetector(onTap: _pickCover, child: Container(
            height: 110, width: double.infinity,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color(0xFFE3EDF3)),
            clipBehavior: Clip.antiAlias,
            child: _coverUrl != null
                ? CachedNetworkImage(imageUrl: _coverUrl!, fit: BoxFit.cover)
                : Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.add_photo_alternate_outlined, color: Colors.black38),
                    const SizedBox(width: 6),
                    Text(_ep(context, 'cover_pick'), style: const TextStyle(color: Colors.black45, fontSize: 13)),
                  ])),
          )),
          Positioned(left: 16, bottom: 0, child: GestureDetector(onTap: _pickAvatar, child: Stack(children: [
            Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
              child: Avatar(name: u?.username, src: _avatar, size: 76)),
            const Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 14, backgroundColor: AppColors.teal, child: Icon(Icons.camera_alt, size: 15, color: Colors.white))),
          ]))),
          Positioned(right: 8, bottom: 26, child: TextButton.icon(onPressed: _pickCover,
            icon: const Icon(Icons.image_outlined, size: 16), label: Text(_ep(context, 'cover'), style: const TextStyle(fontSize: 12)))),
        ])),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: TextField(controller: _first, decoration: InputDecoration(labelText: context.tr('editprofile.first_name')))),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: _last, decoration: InputDecoration(labelText: _ep(context, 'last_name')))),
        ]),
        const SizedBox(height: 10),
        TextField(controller: _bio, maxLines: 3, decoration: InputDecoration(labelText: context.tr('editprofile.bio'))),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: _city, decoration: InputDecoration(labelText: _ep(context, 'city')))),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: _country, decoration: InputDecoration(labelText: _ep(context, 'country')))),
        ]),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _experience,
          decoration: InputDecoration(labelText: _ep(context, 'experience')),
          items: [
            for (final e in const ['beginner', 'intermediate', 'advanced', 'expert'])
              DropdownMenuItem(value: e, child: Text(_ep(context, 'exp_$e'))),
          ],
          onChanged: (v) => setState(() => _experience = v),
        ),
        const SizedBox(height: 16),
        Text(_ep(context, 'color'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 8),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final hex in _kleuren)
            GestureDetector(
              onTap: () => setState(() => _profileColor = hex),
              child: Container(width: 36, height: 36, decoration: BoxDecoration(
                color: Color(int.parse('FF${hex.substring(1)}', radix: 16)), shape: BoxShape.circle,
                border: Border.all(color: _profileColor == hex ? AppColors.navy : Colors.transparent, width: 3),
              ), child: _profileColor == hex ? const Icon(Icons.check, color: Colors.white, size: 18) : null),
            ),
        ]),
        const SizedBox(height: 20),
        FilledButton(onPressed: _saving ? null : _save,
          child: Text(_saving ? '…' : context.tr('editprofile.save'))),
        const SizedBox(height: 10),
        Text(_ep(context, 'more_settings'), style: const TextStyle(fontSize: 12, color: Colors.black45), textAlign: TextAlign.center),
      ]),
    );
  }
}
