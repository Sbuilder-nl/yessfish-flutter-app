import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../data/services/posts_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final PostsService _postsService = PostsService();
  final ImagePicker _picker = ImagePicker();
  
  bool _isSubmitting = false;
  bool _uploadingPhoto = false;
  String? _selectedPhotoPath;
  String? _uploadedPhotoUrl;

  @override
  void dispose() {
    _contentController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedPhotoPath = photo.path;
        });

        // Upload immediately
        await _uploadPhoto(photo.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij foto selectie: $e')),
        );
      }
    }
  }

  Future<void> _uploadPhoto(String photoPath) async {
    setState(() => _uploadingPhoto = true);

    try {
      final photoUrl = await _postsService.uploadPostPhoto(photoPath);
      setState(() {
        _uploadedPhotoUrl = photoUrl;
        _uploadingPhoto = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto geüpload! 📸')),
        );
      }
    } catch (e) {
      setState(() => _uploadingPhoto = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload fout: $e')),
        );
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _selectedPhotoPath = null;
      _uploadedPhotoUrl = null;
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
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerij'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitPost() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vul tekst in voor je post')),
      );
      return;
    }

    if (_uploadingPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wacht tot foto upload klaar is')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _postsService.createPost(
        content: _contentController.text.trim(),
        imageUrl: _uploadedPhotoUrl,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true); // Return true to refresh feed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post geplaatst! 🎣')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nieuwe Post'),
        actions: [
          TextButton(
            onPressed: (_isSubmitting || _uploadingPhoto) ? null : _submitPost,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'PLAATSEN',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content field
            TextField(
              controller: _contentController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Wat wil je delen?',
                border: OutlineInputBorder(),
              ),
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 16),

            // Location field
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Locatie (optioneel)',
                hintText: 'Waar ben je?',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 16),

            // Photo preview
            if (_selectedPhotoPath != null) ...[
              Card(
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Image.file(
                      File(_selectedPhotoPath!),
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                    if (_uploadingPhoto)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black54,
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                        ),
                        onPressed: _uploadingPhoto ? null : _removePhoto,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Image upload button
            OutlinedButton.icon(
              onPressed: (_isSubmitting || _uploadingPhoto) 
                  ? null 
                  : _showPhotoSourceDialog,
              icon: _uploadingPhoto 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.image_outlined),
              label: Text(
                _selectedPhotoPath == null 
                    ? 'Foto toevoegen' 
                    : 'Andere foto kiezen'
              ),
            ),
          ],
        ),
      ),
    );
  }
}
