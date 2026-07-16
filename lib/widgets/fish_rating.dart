import 'package:flutter/material.dart';
import '../core/config.dart';

/// Vijf visjes-beoordeling (1-5). Klikbaar als [onRate] is opgegeven, anders read-only.
class FishRating extends StatefulWidget {
  final double value;       // gemiddelde (read-only weergave)
  final int? mine;          // eigen score
  final double size;
  final void Function(int score)? onRate;
  const FishRating({super.key, this.value = 0, this.mine, this.size = 26, this.onRate});

  @override
  State<FishRating> createState() => _FishRatingState();
}

class _FishRatingState extends State<FishRating> {
  int _hover = 0;

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onRate != null;
    final active = interactive ? (_hover != 0 ? _hover : (widget.mine ?? 0)) : 0;
    return Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (idx) {
      final i = idx + 1;
      final bool filled = interactive ? i <= active : i <= widget.value.round();
      final child = Icon(
        filled ? Icons.set_meal : Icons.set_meal_outlined,
        size: widget.size,
        color: filled ? AppColors.teal : Colors.black26,
      );
      if (!interactive) return Padding(padding: const EdgeInsets.only(right: 2), child: child);
      return GestureDetector(
        onTap: () => widget.onRate!(i),
        child: Padding(padding: const EdgeInsets.only(right: 2), child: child),
      );
    }));
  }
}
