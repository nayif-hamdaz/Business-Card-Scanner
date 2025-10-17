import 'package:card_scanner_app/api/api_service.dart';
import 'package:card_scanner_app/models/business_card.dart';
import 'package:card_scanner_app/screens/review_screen.dart';
import 'package:flutter/material.dart';

class ResultsScreen extends StatefulWidget {
  final List<BusinessCard> scannedCards;
  const ResultsScreen({super.key, required this.scannedCards});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late List<BusinessCard> _cardList;
  bool _isSavingAll = false;

  @override
  void initState() {
    super.initState();
    _cardList = List.from(widget.scannedCards);
  }

  Future<void> _editCard(int index) async {
    final result = await Navigator.of(context).push<ReviewResult>(
      MaterialPageRoute(
        builder: (context) => ReviewScreen(cardData: _cardList[index]),
      ),
    );

    if (result == null) return; // User just went back without action

    if (result.action == ReviewAction.savedIndividually) {
      setState(() {
        _cardList.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact saved and removed from list.'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (result.action == ReviewAction.editsSaved) {
      setState(() {
        _cardList[index] = result.card;
      });
    }
  }

  Future<void> _saveAllContacts() async {
    if (_cardList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No contacts left to save.')),
      );
      return;
    }

    setState(() {
      _isSavingAll = true;
    });

    int successCount = 0;
    for (final card in _cardList) {
      final success = await ApiService.saveCard(card);
      if (success) {
        successCount++;
      }
    }

    if (!mounted) return;

    setState(() {
      _isSavingAll = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved $successCount of ${_cardList.length} contacts.'),
        backgroundColor: successCount == _cardList.length
            ? Colors.green
            : Colors.orange,
      ),
    );

    // Clear the list after attempting to save all
    setState(() {
      _cardList.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanned Results'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _cardList.isEmpty
                ? const Center(
                    child: Text(
                      'All contacts have been saved.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _cardList.length,
                    itemBuilder: (context, index) {
                      final card = _cardList[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card.name.isNotEmpty ? card.name : '(No Name)',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (card.organization.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  card.organization,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                              const Divider(height: 24),
                              _buildDetailRow(
                                Icons.work_outline,
                                card.designation,
                              ),
                              _buildDetailRow(
                                Icons.phone_outlined,
                                card.contact,
                              ),
                              _buildDetailRow(Icons.email_outlined, card.email),
                              _buildDetailRow(
                                Icons.language_outlined,
                                card.website,
                              ),
                              _buildDetailRow(
                                Icons.location_on_outlined,
                                card.address,
                              ),
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => _editCard(index),
                                  child: const Text('EDIT & SAVE'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_cardList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: _isSavingAll
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: _saveAllContacts,
                        icon: const Icon(Icons.save_alt),
                        label: Text('Save All (${_cardList.length}) to Excel'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Done'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
