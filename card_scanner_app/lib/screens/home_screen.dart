import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../api/api_service.dart';
import '../models/business_card.dart';
import 'review_screen.dart'; // Make sure this import is here

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isTwoSided = false;
  ImageData? _frontImage;
  ImageData? _backImage;
  bool _isLoading = false;

  // Function to show the image source selection dialog (Camera vs Gallery)
  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Select Image Source'),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text('Camera', style: TextStyle(fontSize: 16)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text('Gallery', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // Function to handle picking an image for either front or back
  Future<void> _pickImage(bool isFront) async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final ImagePicker picker = ImagePicker();
    // Add image quality to reduce file size and processing time
    final XFile? imageFile = await picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      final name = imageFile.name;

      // We need context to be valid before showing the dialog
      if (!mounted) return;

      final confirm = await _showImageConfirmationDialog(bytes, source);

      // Only proceed if the user explicitly confirms
      if (confirm == true) {
        setState(() {
          if (isFront) {
            _frontImage = ImageData(bytes: bytes, name: name);
          } else {
            _backImage = ImageData(bytes: bytes, name: name);
          }
        });
      }
    }
  }

  // UPDATED: Dialog now includes a "Cancel" button for all cases.
  Future<bool?> _showImageConfirmationDialog(
    Uint8List imageBytes,
    ImageSource source,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            source == ImageSource.camera
                ? 'Confirm Picture?'
                : 'Confirm Selection?',
          ),
          content: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(imageBytes, fit: BoxFit.contain),
          ),
          actions: [
            // Cancel button (returns null)
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            // Retake button (only for camera, returns false)
            if (source == ImageSource.camera)
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Retake'),
              ),
            // Confirm button (returns true)
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  // The main function to trigger the scan
  Future<void> _scanCard() async {
    if (_frontImage == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload the front image of the card.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final BusinessCard? card = await ApiService.scanCard(
      frontImageBytes: _frontImage!.bytes,
      frontFilename: _frontImage!.name,
      backImageBytes: _backImage?.bytes,
      backFilename: _backImage?.name,
    );

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (card != null) {
      print("Successfully scanned card: ${card.name}");
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => ReviewScreen(cardData: card)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to scan card. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Card Scanner'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCardTypeToggle(),
            const SizedBox(height: 24),
            _buildImagePicker(isFront: true),
            if (_isTwoSided) ...[
              const SizedBox(height: 24),
              _buildImagePicker(isFront: false),
            ],
            const SizedBox(height: 40),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _scanCard,
                    icon: const Icon(Icons.document_scanner_outlined, size: 28),
                    label: const Text('Scan Card'),
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
    );
  }

  Widget _buildCardTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildToggleOption(
            '1-Sided Card',
            !_isTwoSided,
            () => setState(() => _isTwoSided = false),
          ),
          _buildToggleOption(
            '2-Sided Card',
            _isTwoSided,
            () => setState(() => _isTwoSided = true),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String title, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.deepPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.deepPurple,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker({required bool isFront}) {
    final image = isFront ? _frontImage : _backImage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isFront ? 'Front of Card' : 'Back of Card',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickImage(isFront),
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade400,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    // UPDATED: Changed fit to 'contain' to prevent zooming.
                    child: Image.memory(image.bytes, fit: BoxFit.contain),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          size: 40,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap to select image',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class ImageData {
  final Uint8List bytes;
  final String name;

  ImageData({required this.bytes, required this.name});
}
