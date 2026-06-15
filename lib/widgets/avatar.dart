import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/config.dart';

class Avatar extends StatelessWidget {
  final String? name;
  final String? src;
  final double size;
  const Avatar({super.key, this.name, this.src, this.size = 40});
  @override
  Widget build(BuildContext context) {
    if (src != null && src!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: src!, width: size, height: size, fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _initials(),
          placeholder: (_, __) => _initials(),
        ),
      );
    }
    return _initials();
  }
  Widget _initials() {
    final letter = (name != null && name!.isNotEmpty) ? name!.substring(0, 1).toUpperCase() : '?';
    return Container(
      width: size, height: size,
      decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(letter, style: TextStyle(color: Colors.white, fontSize: size * 0.42, fontWeight: FontWeight.bold)),
    );
  }
}
