import 'package:flutter/material.dart';
import '../services/update_checker_service.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;
  final VoidCallback onUpdate;
  final VoidCallback? onLater;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    required this.onUpdate,
    this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.system_update,
            color: colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text('Update Beschikbaar'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Er is een nieuwe versie van YessFish beschikbaar!',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Huidige versie',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      'v${updateInfo.currentVersion}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward,
                  color: colorScheme.onPrimaryContainer,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Nieuwe versie',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      'v${updateInfo.latestVersion}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (updateInfo.changelog.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Wat is er nieuw:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              updateInfo.changelog,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Na klikken op "Update Nu" opent de download. Installeer de APK om te updaten.',
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (updateInfo.forceUpdate) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Deze update is verplicht',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (!updateInfo.forceUpdate && onLater != null)
          TextButton(
            onPressed: onLater,
            child: const Text('Later'),
          ),
        FilledButton.icon(
          onPressed: onUpdate,
          icon: const Icon(Icons.download),
          label: const Text('Update Nu'),
        ),
      ],
    );
  }

  /// Show update dialog
  static Future<void> show(
    BuildContext context,
    UpdateInfo updateInfo,
    UpdateCheckerService updateService,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: !updateInfo.forceUpdate,
      builder: (context) => UpdateDialog(
        updateInfo: updateInfo,
        onUpdate: () {
          Navigator.of(context).pop();
          updateService.downloadUpdate(updateInfo.downloadUrl);
        },
        onLater: updateInfo.forceUpdate
            ? null
            : () {
                Navigator.of(context).pop();
              },
      ),
    );
  }
}
