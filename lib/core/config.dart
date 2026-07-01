import 'package:flutter/material.dart';

class Config {
  static const String apiBase = 'https://api.yessfish.com/api';
  static const String origin = 'https://api.yessfish.com';
  // Realtime (Reverb / Pusher-protocol)
  static const String reverbKey = 'fe25b2682d3a72029cc4';
  static const String reverbHost = 'api.yessfish.com';
  static const int reverbPort = 443;
  static const String googleServerClientId = "722347151371-ht0f8ekdrb3e5p2k61ugb6jck8d42upm.apps.googleusercontent.com";
  static const String appVersion = "1.0.1 (92)";
}

class AppColors {
  // Identiek aan de web-huisstijl (globals.css).
  static const navy = Color(0xFF0A3D62);
  static const navy2 = Color(0xFF0E5A87);
  static const teal = Color(0xFF1F8A70);
  static const teal2 = Color(0xFF176B57);
  static const mint = Color(0xFF7BE0C4);
  static const bg = Color(0xFFEEF3F7);
  static const border = Color(0xFFE8EEF3);
  static const shared = Color(0xFF2563EB); // gedeelde stekken
  static const accent = Color(0xFFEF6C00); // vangsten/oranje
  static const danger = Color(0xFFE11D48);
}
