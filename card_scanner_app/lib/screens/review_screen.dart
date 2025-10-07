import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/business_card.dart';

class ReviewScreen extends StatefulWidget {
  final BusinessCard cardData;
  const ReviewScreen({super.key, required this.cardData});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  // NEW: Added a controller for the category field.
  late final TextEditingController _categoryController;
  late final TextEditingController _organizationController;
  late final TextEditingController _nameController;
  late final TextEditingController _designationController;
  late final TextEditingController _contactController;
  late final TextEditingController _emailController;
  late final TextEditingController _websiteController;
  late final TextEditingController _addressController;
  late final TextEditingController _remarksController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize all controllers with the data from the scanned card.
    _categoryController = TextEditingController(text: widget.cardData.category);
    _organizationController = TextEditingController(text: widget.cardData.organization);
    _nameController = TextEditingController(text: widget.cardData.name);
    _designationController = TextEditingController(text: widget.cardData.designation);
    _contactController = TextEditingController(text: widget.cardData.contact);
    _emailController = TextEditingController(text: widget.cardData.email);
    _websiteController = TextEditingController(text: widget.cardData.website);
    _addressController = TextEditingController(text: widget.cardData.address);
    _remarksController = TextEditingController(text: widget.cardData.remarks);
  }

  @override
  void dispose() {
    // Dispose of all controllers to free up resources.
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

  Future<void> _saveContact() async {
    setState(() {
      _isSaving = true;
    });

    // Create a new BusinessCard object with the final, potentially edited data.
    final updatedCard = BusinessCard(
      category: _categoryController.text,
      organization: _organizationController.text,
      name: _nameController.text,
      designation: _designationController.text,
      contact: _contactController.text,
      email: _emailController.text,
      website: _websiteController.text,
      address: _addressController.text,
      remarks: _remarksController.text,
    );

    final success = await ApiService.saveCard(updatedCard);

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      final message = success ? 'Contact saved successfully!' : 'Failed to save contact.';
      final color = success ? Colors.green : Colors.red;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
      if (success) {
        // Go back to the home screen on success.
        Navigator.of(context).pop();
      }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // NEW: Added the text field for Category at the top.
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
            const SizedBox(height: 24),
            _isSaving
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveContact,
                      icon: const Icon(Icons.save),
                      label: const Text('Save to File'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // Helper widget to reduce repetitive code for text fields.
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }
}

