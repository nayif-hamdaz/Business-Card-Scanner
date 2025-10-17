import 'package:card_scanner_app/api/api_service.dart';
import 'package:card_scanner_app/models/business_card.dart';
import 'package:card_scanner_app/models/image_data.dart';
import 'package:card_scanner_app/screens/results_screen.dart';
import 'package:flutter/material.dart';

class StagingScreen extends StatefulWidget {
  final List<ImageData> images;
  const StagingScreen({super.key, required this.images});

  @override
  State<StagingScreen> createState() => _StagingScreenState();
}

class _StagingScreenState extends State<StagingScreen> {
  late List<ImageData> _imageList;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _imageList = List.from(widget.images);
  }

  void _removeImage(int index) {
    setState(() {
      _imageList.removeAt(index);
    });
  }

  Future<void> _analyzeCards() async {
    if (_imageList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one image to analyze.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final List<BusinessCard?> results = await ApiService.scanBatch(
        images: _imageList,
      );
      if (!mounted) return;

      final List<BusinessCard> successfulScans = results
          .whereType<BusinessCard>()
          .toList();

      if (successfulScans.isEmpty && results.isNotEmpty) {
        throw Exception('All scans failed. Please check image quality.');
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ResultsScreen(scannedCards: successfulScans),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not analyze cards: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Review Selection (${_imageList.length})'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: _imageList.length,
                    itemBuilder: (context, index) {
                      return GridTile(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                _imageList[index].bytes,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _analyzeCards,
                    icon: const Icon(Icons.analytics_outlined),
                    label: Text('Analyze ${_imageList.length} Cards'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Analyzing Cards...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
