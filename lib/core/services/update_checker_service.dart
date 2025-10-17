import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateCheckerService {
  final Dio _dio = Dio();
  static const String _versionUrl = 'https://yessfish.com/downloads/beta/version.json';

  /// Check if a new version is available
  Future<UpdateInfo?> checkForUpdates() async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      // Fetch latest version from server
      final response = await _dio.get(_versionUrl);

      if (response.statusCode == 200) {
        final data = response.data;
        final latestVersion = data['version'] as String;
        final latestBuildNumber = data['build_number'] as int;
        final downloadUrl = data['download_url'] as String;
        final changelog = data['changelog'] as String? ?? '';
        final forceUpdate = data['force_update'] as bool? ?? false;

        // Compare versions
        if (latestBuildNumber > currentBuildNumber) {
          return UpdateInfo(
            currentVersion: currentVersion,
            latestVersion: latestVersion,
            currentBuildNumber: currentBuildNumber,
            latestBuildNumber: latestBuildNumber,
            downloadUrl: downloadUrl,
            changelog: changelog,
            forceUpdate: forceUpdate,
          );
        }
      }

      return null; // No update available
    } catch (e) {
      print('Update check failed: $e');
      return null;
    }
  }

  /// Download and install update
  Future<bool> downloadUpdate(String downloadUrl) async {
    try {
      final uri = Uri.parse(downloadUrl);
      print('🚀 Attempting to launch download URL: $downloadUrl');

      // Try external application first (opens in browser)
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        print('❌ External application launch failed, trying platform default...');
        // Fallback to platform default
        launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      }

      if (!launched) {
        print('❌ Platform default launch failed');
        throw Exception('Could not launch download URL');
      }

      print('✅ Download URL launched successfully');
      return true;
    } catch (e) {
      print('❌ Failed to launch download: $e');
      return false;
    }
  }
}

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final int currentBuildNumber;
  final int latestBuildNumber;
  final String downloadUrl;
  final String changelog;
  final bool forceUpdate;

  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.currentBuildNumber,
    required this.latestBuildNumber,
    required this.downloadUrl,
    required this.changelog,
    required this.forceUpdate,
  });

  String get versionDifference {
    return 'v$currentVersion (build $currentBuildNumber) → v$latestVersion (build $latestBuildNumber)';
  }
}
