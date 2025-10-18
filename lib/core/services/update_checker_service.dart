import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class UpdateCheckerService {
  final Dio _dio = Dio();
  static const String _versionUrl = 'https://yessfish.com/downloads/beta/version.json';

  // Notifications
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _notificationsInitialized = false;

  // Download progress callback
  Function(int received, int total)? onDownloadProgress;
  
  // Background download state
  bool _isDownloading = false;
  String? _downloadedApkPath;

  bool get isDownloading => _isDownloading;
  String? get downloadedApkPath => _downloadedApkPath;

  /// Initialize notifications
  Future<void> initializeNotifications() async {
    if (_notificationsInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap - install APK
        if (_downloadedApkPath != null) {
          installDownloadedUpdate();
        }
      },
    );

    _notificationsInitialized = true;
  }

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

  /// Download update in background with notifications
  Future<bool> downloadUpdateInBackground(String downloadUrl, String version) async {
    if (_isDownloading) {
      print('⚠️ Download already in progress');
      return false;
    }

    _isDownloading = true;

    try {
      await initializeNotifications();

      print('🚀 Starting background APK download from: $downloadUrl');

      // Show download started notification

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
            final progress = ((received / total) * 100).round();
            
            // Only update every 10% to prevent notification spam and battery drain
            // Also update at 99% to show "almost done"
            if (progress % 10 == 0 || progress == 99) {
              print('📥 Download progress: $progress%');
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = ((received / total) * 100).round();
            // Alleen console logging - GEEN notifications tijdens downloaden!
            if (progress % 10 == 0) {
              print('📥 Download progress: $progress%');
            }
            onDownloadProgress?.call(received, total);
          }
        },
      print('✅ APK downloaded successfully');

      // Verify file exists
      final file = File(savePath);
      if (!await file.exists()) {
        throw Exception('Downloaded file not found');
      }

      print('📦 APK file size: ${await file.length()} bytes');

      _downloadedApkPath = savePath;

      // Show completion notification

      _isDownloading = false;
      return true;

    } catch (e) {
      print('❌ Background download failed: $e');
      
      // Show error notification

      _isDownloading = false;
      return false;
    }
  }

  /// Install previously downloaded update
  Future<bool> installDownloadedUpdate() async {
    if (_downloadedApkPath == null) {
      print('⚠️ No downloaded APK to install');
      return false;
    }

    try {
      print('🔧 Opening APK for installation: $_downloadedApkPath');
      final result = await OpenFilex.open(_downloadedApkPath!);

      print('📱 Installation result: ${result.type} - ${result.message}');

      if (result.type == ResultType.done || result.type == ResultType.noAppToOpen) {
        return true;
      } else {
        throw Exception('Failed to open APK: ${result.message}');
      }
    } catch (e) {
      print('❌ Installation failed: $e');
      return false;
    }
  }

  /// Show notification (helper method)
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    bool ongoing = false,
    bool showProgress = false,
    int progress = 0,
    bool silent = false,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'yessfish_updates',
      'App Updates',
      channelDescription: 'Notifications for app updates',
      importance: silent ? Importance.low : Importance.high,
      priority: silent ? Priority.low : Priority.high,
      playSound: !silent,
      enableVibration: !silent,
      ongoing: ongoing,
      showProgress: showProgress,
      maxProgress: 100,
      progress: progress,
      icon: '@mipmap/ic_launcher',
    );

    final details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(id, title, body, details);
  }

  /// Download and install APK update (legacy method - now shows dialog)
  Future<bool> downloadAndInstallUpdate(String downloadUrl) async {
    try {
      print('🚀 Starting APK download from: $downloadUrl');

      // Request storage permissions
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

      final fileName = 'yessfish-update.apk';
      final savePath = '${directory.path}/$fileName';

      print('📁 Saving APK to: $savePath');

      // Download APK
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
        options: Options(
          receiveTimeout: const Duration(minutes: 10),
          sendTimeout: const Duration(minutes: 10),
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );

      print('✅ APK downloaded successfully');

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
