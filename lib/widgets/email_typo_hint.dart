// "Bedoel je …@gmail.com? Ja, aanpassen" onder een e-mailveld (07-10-2026, zoals op de website).
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/config.dart';
import '../core/email_typo.dart';
import '../core/i18n.dart';

class EmailTypoHint extends StatelessWidget {
  final TextEditingController controller;
  const EmailTypoHint({super.key, required this.controller});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<TextEditingValue>(
    valueListenable: controller,
    builder: (context, v, _) {
      final s = emailSuggestie(v.text);
      if (s == null) return const SizedBox.shrink();
      final t = emailSuggestieTekst(Provider.of<I18n>(context, listen: false).locale);
      return Container(
        key: const Key('email-typo-hint'),
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
        decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Expanded(child: Text.rich(TextSpan(children: [
            TextSpan(text: '${t[0]} '), TextSpan(text: s, style: const TextStyle(fontWeight: FontWeight.bold)), const TextSpan(text: '?'),
          ]), style: const TextStyle(color: Color(0xFF7A4F00), fontSize: 13.5))),
          TextButton(
            onPressed: () => controller.value = TextEditingValue(text: s, selection: TextSelection.collapsed(offset: s.length)),
            child: Text(t[1], style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700)),
          ),
        ]),
      );
    },
  );
}
