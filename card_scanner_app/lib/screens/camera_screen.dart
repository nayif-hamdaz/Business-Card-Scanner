import 'dart:io';
import 'package:card_scanner_app/models/image_data.dart';
import 'package:card_scanner_app/screens/staging_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isScannerBusy = false;

  @override
  void initState() {
    super.initState();
    // Automatically open the scanner as soon as the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScan();
    });
  }

  Future<void> _startScan() async {
    if (_isScannerBusy) return;
    setState(() {
      _isScannerBusy = true;
    });

    // 1. Create scanning options
    final options = DocumentScannerOptions(
      mode: ScannerMode.full,
      pageLimit: 10,
    );

    // 2. Create an instance of the DocumentScanner
    final documentScanner = DocumentScanner(options: options);

    try {
      // 3. THE DEFINITIVE FIX (FROM YOU): Call the correct .scanDocument() method
      final DocumentScanningResult result = await documentScanner
          .scanDocument();

      if (result.images.isNotEmpty) {
        final List<ImageData> capturedImages = [];
        for (final imagePath in result.images) {
          final file = File(imagePath);
          final bytes = await file.readAsBytes();
          final name = file.path.split('/').last;
          capturedImages.add(ImageData(bytes: bytes, name: name));
        }

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => StagingScreen(images: capturedImages),
          ),
        );
      } else {
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      print("Error during document scan: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to scan documents: $e')));
      if (mounted) Navigator.of(context).pop();
    } finally {
      // 4. THE DEFINITIVE FIX (FROM YOU): Always release resources
      documentScanner.close();
      if (mounted) {
        setState(() {
          _isScannerBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Opening scanner...'),
          ],
        ),
      ),
    );
  }
}
