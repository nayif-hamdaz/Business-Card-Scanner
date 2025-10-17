import 'package:card_scanner_app/api/api_service.dart';
import 'package:flutter/material.dart';
import '../models/business_card.dart';

// Helper classes to pass a structured result back to the ResultsScreen
enum ReviewAction { savedIndividually, editsSaved }

class ReviewResult {
  final ReviewAction action;
  final BusinessCard card;
  ReviewResult({required this.action, required this.card});
}

class ReviewScreen extends StatefulWidget {
  final BusinessCard cardData;
  const ReviewScreen({super.key, required this.cardData});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _categoryController;
  late final TextEditingController _organizationController;
  late final TextEditingController _nameController;
  late final TextEditingController _designationController;
  late final TextEditingController _contactController;
  late final TextEditingController _emailController;
  late final TextEditingController _websiteController;
  late final TextEditingController _addressController;
  late final TextEditingController _remarksController;

  String? _selectedContactType;
  final List<String> _contactTypes = ['Supplier', 'Customer'];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController(text: widget.cardData.category);
    _organizationController = TextEditingController(
      text: widget.cardData.organization,
    );
    _nameController = TextEditingController(text: widget.cardData.name);
    _designationController = TextEditingController(
      text: widget.cardData.designation,
    );
    _contactController = TextEditingController(text: widget.cardData.contact);
    _emailController = TextEditingController(text: widget.cardData.email);
    _websiteController = TextEditingController(text: widget.cardData.website);
    _addressController = TextEditingController(text: widget.cardData.address);
    _remarksController = TextEditingController(text: widget.cardData.remarks);

    // Set default value for contact type
    _selectedContactType = widget.cardData.contactType;
    if (_selectedContactType == null || _selectedContactType!.isEmpty) {
      _selectedContactType = 'Supplier';
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _organizationController.dispose();
    _nameController.dispose();
    _designationController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  BusinessCard _getUpdatedCard() {
    return BusinessCard(
      category: _categoryController.text,
      organization: _organizationController.text,
      name: _nameController.text,
      designation: _designationController.text,
      contact: _contactController.text,
      email: _emailController.text,
      website: _websiteController.text,
      address: _addressController.text,
      remarks: _remarksController.text,
      contactType: _selectedContactType,
    );
  }

  void _saveEdits() {
    final updatedCard = _getUpdatedCard();
    Navigator.of(
      context,
    ).pop(ReviewResult(action: ReviewAction.editsSaved, card: updatedCard));
  }

  Future<void> _saveIndividually() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isSaving = true;
    });

    final updatedCard = _getUpdatedCard();
    final success = await ApiService.saveCard(updatedCard);

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (success) {
      Navigator.of(context).pop(
        ReviewResult(action: ReviewAction.savedIndividually, card: updatedCard),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save contact.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review & Edit'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _categoryController,
                label: 'Category',
                icon: Icons.category,
              ),
              _buildTextField(
                controller: _organizationController,
                label: 'Organization',
                icon: Icons.business,
              ),
              _buildTextField(
                controller: _nameController,
                label: 'Name',
                icon: Icons.person,
              ),
              _buildTextField(
                controller: _designationController,
                label: 'Designation',
                icon: Icons.work,
              ),
              _buildTextField(
                controller: _contactController,
                label: 'Contact',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              _buildTextField(
                controller: _websiteController,
                label: 'Website',
                icon: Icons.web,
              ),
              _buildTextField(
                controller: _addressController,
                label: 'Address',
                icon: Icons.location_on,
                maxLines: 3,
              ),
              _buildTextField(
                controller: _remarksController,
                label: 'Remarks',
                icon: Icons.note,
                maxLines: 3,
              ),
              _buildDropdown(),
              const SizedBox(height: 24),
              if (_isSaving)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saveEdits,
                        child: const Text('Save Edits'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveIndividually,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Save Individually to Excel'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: _selectedContactType,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a type.';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: 'Contact Type',
          prefixIcon: const Icon(Icons.people_alt_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        items: _contactTypes.map((String value) {
          return DropdownMenuItem<String>(value: value, child: Text(value));
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedContactType = newValue;
            });
          }
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }
}
