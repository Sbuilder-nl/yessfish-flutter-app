import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateCheckerService {
  final Dio _dio = Dio();
  static const String _versionUrl = 'https://yessfish.com/downloads/beta/version.json';

  // Download progress callback
  Function(int received, int total)? onDownloadProgress;

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

  /// Download and install APK update
  Future<bool> downloadAndInstallUpdate(String downloadUrl) async {
    try {
      print('🚀 Starting APK download from: $downloadUrl');

      // Request storage permissions for older Android versions
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (status.isDenied) {
          print('⚠️ Storage permission denied');
        }
      }

      // Get download directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not get download directory');
      }

      // Create file path for APK
      final fileName = 'yessfish-update.apk';
      final savePath = '${directory.path}/$fileName';

      print('📁 Saving APK to: $savePath');

      // Download APK with progress tracking
      await _dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            print('📥 Download progress: $progress%');
            onDownloadProgress?.call(received, total);
          }
        },
      );

      print('✅ APK downloaded successfully');

      // Verify file exists
      final file = File(savePath);
      if (!await file.exists()) {
        throw Exception('Downloaded file not found');
      }

      print('📦 APK file size: ${await file.length()} bytes');

      // Open APK for installation
      print('🔧 Opening APK for installation...');
      final result = await OpenFilex.open(savePath);

      print('📱 Installation result: ${result.type} - ${result.message}');

      if (result.type == ResultType.done || result.type == ResultType.noAppToOpen) {
        return true;
      } else {
        throw Exception('Failed to open APK: ${result.message}');
      }
    } catch (e) {
      print('❌ Update download/install failed: $e');
      return false;
    }
  }

  /// Legacy method for fallback - opens URL in browser
  Future<bool> openDownloadInBrowser(String downloadUrl) async {
    try {
      final uri = Uri.parse(downloadUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      return launched;
    } catch (e) {
      print('❌ Failed to open browser: $e');
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
