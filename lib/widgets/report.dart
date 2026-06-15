import 'package:flutter/material.dart';
import '../core/api.dart';

Future<void> showReportSheet(BuildContext context, {required String type, required int targetId}) async {
  const reasons = {'spam': 'Spam', 'abuse': 'Misbruik / intimidatie', 'inappropriate': 'Ongepaste inhoud', 'other': 'Anders'};
  final reason = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Padding(padding: EdgeInsets.all(14), child: Text('Melden', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
      ...reasons.entries.map((e) => ListTile(title: Text(e.value), onTap: () => Navigator.pop(ctx, e.key))),
    ])),
  );
  if (reason == null) return;
  try {
    await Api.post('/reports', {'type': type, 'target_id': targetId, 'reason': reason});
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bedankt, je melding is ontvangen.')));
  } catch (_) {}
}
