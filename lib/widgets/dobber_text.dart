import "package:flutter/material.dart";

/// Tekst waarin elke ⭐ wordt vervangen door het dobber-logo (de YessFish-valuta "dobbers").
/// Het logo schaalt mee met de fontgrootte van [style].
class DobberText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  const DobberText(this.text, {super.key, this.style, this.textAlign, this.maxLines, this.overflow});

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.merge(style);
    final size = (base.fontSize ?? 14) * 1.15;
    final parts = text.split("⭐");
    final spans = <InlineSpan>[];
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) spans.add(TextSpan(text: parts[i]));
      if (i < parts.length - 1) {
        spans.add(WidgetSpan(alignment: PlaceholderAlignment.middle,
          child: Image.asset("assets/logo.png", width: size * 0.8, height: size, fit: BoxFit.contain)));
      }
    }
    return Text.rich(TextSpan(style: base, children: spans), textAlign: textAlign, maxLines: maxLines, overflow: overflow);
  }
}
