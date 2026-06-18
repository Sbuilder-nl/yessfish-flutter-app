import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../core/api.dart';
import '../core/auth.dart';
import '../core/config.dart';
import '../core/i18n.dart';
import '../widgets/avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _first = TextEditingController();
  final _bio = TextEditingController();
  String? _avatar;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthState>().user;
    _first.text = u?.firstName ?? '';
    _avatar = u?.avatarPath;
  }

  Future<void> _pickAvatar() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
    if (x == null) return;
    try { final r = await Api.uploadImage(x.path); setState(() => _avatar = r['url']); _avatarPath = r['path']; } catch (_) {}
  }
  String? _avatarPath;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final nav = Navigator.of(context);
      final auth = context.read<AuthState>();
      await Api.put('/profile', {'first_name': _first.text.trim(), if (_bio.text.isNotEmpty) 'bio': _bio.text.trim(), if (_avatarPath != null) 'avatar_path': _avatarPath});
      await auth.refresh();
      if (mounted) nav.pop();
    } catch (_) {} finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final u = context.read<AuthState>().user;
    return Scaffold(appBar: AppBar(title: Text(context.tr('editprofile.title'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(child: GestureDetector(onTap: _pickAvatar, child: Stack(children: [
          Avatar(name: u?.username, src: _avatar, size: 90),
          const Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 14, backgroundColor: AppColors.teal, child: Icon(Icons.camera_alt, size: 15, color: Colors.white))),
        ]))),
        const SizedBox(height: 20),
        TextField(controller: _first, decoration: InputDecoration(labelText: context.tr('editprofile.first_name'))),
        const SizedBox(height: 12),
        TextField(controller: _bio, maxLines: 3, decoration: InputDecoration(labelText: context.tr('editprofile.bio'))),
        const SizedBox(height: 20),
        FilledButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(context.tr('editprofile.save'))),
      ]));
  }
}
