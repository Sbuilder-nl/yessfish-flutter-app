import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/disciplines_i18n.dart';

/// Visstijlen kiezen (meervoudig). Pan-Europees: stijlen via stabiele `key`,
/// labels in de huidige taal. Slaat op via PUT /profile/disciplines.
class DisciplinesScreen extends StatefulWidget {
  const DisciplinesScreen({super.key});
  @override
  State<DisciplinesScreen> createState() => _DisciplinesScreenState();
}

class _DisciplinesScreenState extends State<DisciplinesScreen> {
  List<Map<String, dynamic>> _all = [];
  final Set<int> _sel = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final all = await Api.get('/disciplines') as List<dynamic>;
      final mine = await Api.get('/profile/disciplines') as Map<String, dynamic>;
      _all = all.map((e) => Map<String, dynamic>.from(e)).toList();
      _sel..clear()..addAll(((mine['disciplines'] as List?) ?? []).map((e) => e as int));
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _loading = false; _error = dui(context, 'err'); });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await Api.put('/profile/disciplines', {'disciplines': _sel.toList()});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dui(context, 'saved'))));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : dui(context, 'err'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(dui(context, 'title'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _load, child: Text(dui(context, 'retry'))),
                ]))
              : Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(dui(context, 'choose'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
                      const SizedBox(height: 4),
                      Text(dui(context, 'hint'), style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    ]),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _all.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (c, i) {
                        final d = _all[i];
                        final id = d['id'] as int;
                        final on = _sel.contains(id);
                        return InkWell(
                          onTap: () => setState(() => on ? _sel.remove(id) : _sel.add(id)),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                            decoration: BoxDecoration(
                              color: on ? AppColors.teal.withValues(alpha: 0.10) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: on ? AppColors.teal : AppColors.border, width: on ? 1.5 : 1),
                            ),
                            child: Row(children: [
                              Icon(on ? Icons.check_circle : Icons.circle_outlined, color: on ? AppColors.teal : Colors.black26),
                              const SizedBox(width: 12),
                              Expanded(child: Text(discName(context, d['key'] as String),
                                  style: TextStyle(fontWeight: FontWeight.w600, color: on ? AppColors.navy : const Color(0xFF334155)))),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: AppColors.teal, padding: const EdgeInsets.symmetric(vertical: 15)),
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(dui(context, 'save')),
                        ),
                      ),
                    ),
                  ),
                ]),
    );
  }
}
