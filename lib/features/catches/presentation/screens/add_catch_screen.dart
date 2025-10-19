import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../../data/services/catches_service.dart';

class AddCatchScreen extends StatefulWidget {
  const AddCatchScreen({super.key});

  @override
  State<AddCatchScreen> createState() => _AddCatchScreenState();
}

class _AddCatchScreenState extends State<AddCatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _catchesService = CatchesService();
  final _picker = ImagePicker();

  // Form controllers
  final _speciesController = TextEditingController();
  final _weightController = TextEditingController();
  final _lengthController = TextEditingController();
  final _baitController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Photos
  List<String> _photoPaths = [];
  bool _uploadingPhotos = false;

  // Location
  Position? _currentPosition;
  bool _loadingLocation = false;
  String? _locationDisplay;

  // Saving state
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _speciesController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _baitController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _loadingLocation = true);

    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Locatie toestemming geweigerd')),
            );
          }
          setState(() => _loadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Locatie toestemming permanent geweigerd. Schakel in via instellingen.'),
            ),
          );
        }
        setState(() => _loadingLocation = false);
        return;
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      setState(() {
        _currentPosition = position;
        _locationDisplay = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        _loadingLocation = false;
      });
    } catch (e) {
      setState(() => _loadingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij ophalen locatie: $e')),
        );
      }
    }
  }

  Future<void> _addPhoto(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _photoPaths.add(photo.path);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto toegevoegd! 📸')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij toevoegen foto: $e')),
        );
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photoPaths.removeAt(index);
    });
  }

  void _showPhotoSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _addPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerij'),
              onTap: () {
                Navigator.pop(context);
                _addPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCatch() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_photoPaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voeg minimaal 1 foto toe')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Upload first photo
      String? photoUrl;
      if (_photoPaths.isNotEmpty) {
        setState(() => _uploadingPhotos = true);
        photoUrl = await _catchesService.uploadCatchPhoto(_photoPaths[0]);
        setState(() => _uploadingPhotos = false);
      }

      // Parse weight and length
      final weight = double.tryParse(_weightController.text.trim());
      final length = double.tryParse(_lengthController.text.trim());

      // Log catch
      await _catchesService.logCatch(
        fishSpecies: _speciesController.text.trim(),
        weight: weight,
        length: length,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        photoUrl: photoUrl,
        description: _descriptionController.text.trim(),
        baitUsed: _baitController.text.trim(),
        isPublic: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vangst gelogd! 🎣'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _uploadingPhotos = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vangst Toevoegen'),
        actions: [
          if (!_isSaving)
            TextButton(
              onPressed: _saveCatch,
              child: const Text('Opslaan'),
            )
          else
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Photos Section
            Text(
              'Foto\'s',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Voeg foto\'s van je vangst toe (je kunt later meer foto\'s toevoegen)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            // Photo Grid
            if (_photoPaths.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _photoPaths.length,
                itemBuilder: (context, index) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_photoPaths[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                            padding: const EdgeInsets.all(4),
                          ),
                          onPressed: () => _removePhoto(index),
                        ),
                      ),
                    ],
                  );
                },
              ),

            const SizedBox(height: 12),

            // Add Photo Button
            OutlinedButton.icon(
              onPressed: _showPhotoSourceDialog,
              icon: const Icon(Icons.add_a_photo),
              label: Text(_photoPaths.isEmpty ? 'Foto toevoegen' : 'Nog een foto toevoegen'),
            ),

            const SizedBox(height: 24),

            // Vangst Gegevens
            Text(
              'Vangst Gegevens',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Vis soort (required)
            TextFormField(
              controller: _speciesController,
              decoration: const InputDecoration(
                labelText: 'Vissoort *',
                hintText: 'Bijv. Snoek, Baars, Karper',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phishing),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vissoort is verplicht';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Weight and Length row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Gewicht (kg)',
                      hintText: '2.5',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.scale),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _lengthController,
                    decoration: const InputDecoration(
                      labelText: 'Lengte (cm)',
                      hintText: '45',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.straighten),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bait used
            TextFormField(
              controller: _baitController,
              decoration: const InputDecoration(
                labelText: 'Aas / Lokaas',
                hintText: 'Bijv. Worm, Spinner, Plug',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.bug_report),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beschrijving / Notities',
                hintText: 'Vertel over je vangst...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 4,
              maxLength: 500,
            ),
            const SizedBox(height: 24),

            // Location Section
            Text(
              'Locatie',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _loadingLocation
                              ? const Text('Locatie ophalen...')
                              : Text(
                                  _locationDisplay ?? 'Geen locatie beschikbaar',
                                  style: theme.textTheme.bodyMedium,
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: _loadingLocation ? null : _getCurrentLocation,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Ververs'),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Locatie wijzigen na opslaan beschikbaar in volgende versie'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_location),
                          label: const Text('Wijzig'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Save Button (large)
            FilledButton(
              onPressed: _isSaving ? null : _saveCatch,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : _uploadingPhotos
                      ? const Text('Foto\'s uploaden...')
                      : const Text(
                          'Vangst Opslaan 🎣',
                          style: TextStyle(fontSize: 18),
                        ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
