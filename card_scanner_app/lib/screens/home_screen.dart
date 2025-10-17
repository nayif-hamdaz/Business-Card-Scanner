import 'package:card_scanner_app/models/image_data.dart';
import 'package:card_scanner_app/screens/camera_screen.dart';
import 'package:card_scanner_app/screens/staging_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _showBatchOptions() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Card Type',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildOption(
                context,
                icon: Icons.photo_library_outlined,
                label: '1-Sided Card',
                onTap: _showSourceOptions,
              ),
              const SizedBox(height: 16),
              _buildOption(
                context,
                icon: Icons.dynamic_feed,
                label: '2-Sided Card (Coming Soon)',
                onTap: null, // This makes the button disabled
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showSourceOptions() async {
    // Close the first bottom sheet
    Navigator.of(context).pop();
    // Show the second one
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Image Source',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildOption(
                context,
                icon: Icons.upload_file,
                label: 'Upload from Device',
                onTap: _pickMultipleImages,
              ),
              const SizedBox(height: 16),
              _buildOption(
                context,
                icon: Icons.camera_alt_outlined,
                label: 'Capture with Camera',
                onTap: _openCamera,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickMultipleImages() async {
    Navigator.of(context).pop(); // Close the bottom sheet
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 80,
      );

      if (pickedFiles.isNotEmpty) {
        final List<ImageData> imageDatas = [];
        for (var file in pickedFiles) {
          final bytes = await file.readAsBytes();
          imageDatas.add(ImageData(bytes: bytes, name: file.name));
        }
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StagingScreen(images: imageDatas),
          ),
        );
      }
    } catch (e) {
      print("Error picking multiple images: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick images: $e')));
    }
  }

  void _openCamera() {
    Navigator.of(context).pop(); // Close the bottom sheet
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const CameraScreen()));
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: onTap != null ? Theme.of(context).primaryColor : Colors.grey,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: onTap != null ? Colors.black : Colors.grey,
          fontSize: 16,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: onTap != null ? Colors.grey.shade300 : Colors.grey.shade200,
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Card Scanner'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.document_scanner_outlined,
                size: 100,
                color: Colors.deepPurple.shade200,
              ),
              const SizedBox(height: 24),
              const Text(
                'Ready to Scan?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'A complete solution to digitize and manage your business cards.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _showBatchOptions,
                icon: const Icon(Icons.camera_enhance_outlined, size: 28),
                label: const Text('Scan Cards'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
