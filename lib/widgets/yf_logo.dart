import 'package:flutter/material.dart';
import '../core/config.dart';

class YfLogo extends StatelessWidget {
  final double size;
  final bool light;
  final bool showText;
  const YfLogo({super.key, this.size = 30, this.light = false, this.showText = true});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Image.asset('assets/logo.png', height: size, width: size),
      if (showText) ...[
        const SizedBox(width: 8),
        Text('YessFish', style: TextStyle(fontSize: size * 0.72, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: light ? Colors.white : AppColors.navy)),
      ],
    ]);
  }
}
