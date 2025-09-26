import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../api/api_service.dart';
import '../models/business_card.dart';
import 'review_screen.dart'; // <--- THIS IS THE FIX

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  bool _isTwoSided = false;
  XFile? _frontImageFile;
  XFile? _backImageFile;

  // --- Image Picking and Confirmation Logic ---
  Future<void> _pickImage(ImageSource source, bool isFront) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image == null) return; // User cancelled

    // --- Confirmation Dialog ---
    final bool? shouldUpload = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must make a choice
      builder: (BuildContext context) => AlertDialog(
        title: Text(source == ImageSource.camera ? 'Use This Photo?' : 'Confirm Upload'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: FutureBuilder<Uint8List>(
                future: image.readAsBytes(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Image.memory(snapshot.data!, fit: BoxFit.contain, height: 200);
                  }
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text('Use this image as the ${isFront ? 'FRONT' : 'BACK'} of the card?'),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // 'false' means cancel/retake
            child: Text(source == ImageSource.camera ? 'Retake' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true), // 'true' means confirm
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (shouldUpload == true) {
      setState(() {
        if (isFront) {
          _frontImageFile = image;
        } else {
          _backImageFile = image;
        }
      });
    }
  }

  // --- Main Scanning Logic ---
  Future<void> _scanCard() async {
    if (_frontImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a front image first.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final frontBytes = await _frontImageFile!.readAsBytes();
      Uint8List? backBytes;
      if (_isTwoSided && _backImageFile != null) {
        backBytes = await _backImageFile!.readAsBytes();
      }

      final BusinessCard? card = await ApiService.scanCard(
        frontImageBytes: frontBytes,
        frontFilename: _frontImageFile!.name,
        backImageBytes: backBytes,
        backFilename: _backImageFile?.name,
      );

      if (!mounted) return;

      if (card != null) {
        // On success, navigate to the review screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ReviewScreen(cardData: card),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to scan image. The server could not extract data.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred during scanning: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Card Scanner'),
        backgroundColor: const Color.fromARGB(255, 15, 10, 80),
        foregroundColor: Colors.white,
        elevation: 4.0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Scan Your Business Cards and Save Contacts Instantly',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 49, 2, 73)),
              ),
              const SizedBox(height: 20),

              // --- 1-Sided / 2-Sided Toggle ---
              SwitchListTile(
                title: const Text('2-Sided Card', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                value: _isTwoSided,
                onChanged: (bool value) {
                  setState(() {
                    _isTwoSided = value;
                    if (!_isTwoSided) {
                      _backImageFile = null; // Clear back image if switching to 1-sided
                    }
                  });
                },
                activeColor: Colors.deepPurple,
                secondary: const Icon(Icons.flip_to_front_outlined),
              ),
              const SizedBox(height: 20),

              // --- Image Display and Selection ---
              _buildImagePicker(isFront: true, imageFile: _frontImageFile),
              if (_isTwoSided) const SizedBox(height: 20),
              if (_isTwoSided) _buildImagePicker(isFront: false, imageFile: _backImageFile),
              const SizedBox(height: 40),

              // --- Scan Button ---
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _frontImageFile == null ? null : _scanCard, // Button is disabled if no front image
                  icon: const Icon(Icons.document_scanner_outlined, size: 28),
                  label: const Text('Scan Card'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widget for Image Pickers ---
  Widget _buildImagePicker({required bool isFront, XFile? imageFile}) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias, // Ensures content respects the rounded corners
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              isFront ? 'Front Image' : 'Back Image',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: _ImagePreview(file: imageFile),
                    )
                  : const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera, isFront),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
                TextButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery, isFront),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// --- A small helper widget to display image from XFile without blocking the UI ---
class _ImagePreview extends StatelessWidget {
  final XFile file;
  const _ImagePreview({required this.file});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(snapshot.data!, fit: BoxFit.contain);
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

