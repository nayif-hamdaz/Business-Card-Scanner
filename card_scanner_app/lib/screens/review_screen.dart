import 'package:flutter/material.dart'; // <--- THIS IS THE FIX
import '../api/api_service.dart';
import '../models/business_card.dart';

class ReviewScreen extends StatefulWidget {
  final BusinessCard cardData;
  const ReviewScreen({super.key, required this.cardData});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  // Controllers to manage the text in each field, allowing for edits
  late final TextEditingController _nameController;
  late final TextEditingController _orgController;
  late final TextEditingController _desigController;
  late final TextEditingController _contactController;
  late final TextEditingController _emailController;
  late final TextEditingController _websiteController;
  late final TextEditingController _addressController;
  late final TextEditingController _remarksController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with the data from the scanned card
    _nameController = TextEditingController(text: widget.cardData.name);
    _orgController = TextEditingController(text: widget.cardData.organization);
    _desigController = TextEditingController(text: widget.cardData.designation);
    _contactController = TextEditingController(text: widget.cardData.contact);
    _emailController = TextEditingController(text: widget.cardData.email);
    _websiteController = TextEditingController(text: widget.cardData.website);
    _addressController = TextEditingController(text: widget.cardData.address);
    _remarksController = TextEditingController(text: widget.cardData.remarks);
  }

  @override
  void dispose() {
    // Clean up the controllers when the screen is closed
    _nameController.dispose();
    _orgController.dispose();
    _desigController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    setState(() => _isSaving = true);

    // Create a new BusinessCard object with the potentially edited data
    final finalCardData = BusinessCard(
      name: _nameController.text,
      organization: _orgController.text,
      designation: _desigController.text,
      contact: _contactController.text,
      email: _emailController.text,
      website: _websiteController.text,
      address: _addressController.text,
      remarks: _remarksController.text,
    );

    // Call the ApiService to save the data
    final bool success = await ApiService.saveCard(finalCardData);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      // Go back to the home screen after a successful save
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save contact. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review & Save Contact'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildTextField(label: 'Name', controller: _nameController, icon: Icons.person),
            _buildTextField(label: 'Organization', controller: _orgController, icon: Icons.business),
            _buildTextField(label: 'Designation', controller: _desigController, icon: Icons.work),
            _buildTextField(label: 'Contact', controller: _contactController, icon: Icons.phone, keyboardType: TextInputType.phone),
            _buildTextField(label: 'Email', controller: _emailController, icon: Icons.email, keyboardType: TextInputType.emailAddress),
            _buildTextField(label: 'Website', controller: _websiteController, icon: Icons.public, keyboardType: TextInputType.url),
            _buildTextField(label: 'Address', controller: _addressController, icon: Icons.location_on),
            _buildTextField(label: 'Remarks', controller: _remarksController, icon: Icons.notes, maxLines: 3),
            const SizedBox(height: 30),
            if (_isSaving)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                onPressed: _saveContact,
                icon: const Icon(Icons.save_alt_outlined, size: 28),
                label: const Text('Save to File'),
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
    );
  }

  // Helper widget to reduce repetitive code for text fields
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
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
          fillColor: Colors.grey.shade100,
        ),
      ),
    );
  }
}

