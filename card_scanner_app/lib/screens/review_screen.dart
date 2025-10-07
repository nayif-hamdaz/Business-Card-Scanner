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
  // Add a GlobalKey for the Form to enable validation
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

  // State variable for the new dropdown, nullable to allow a "hint"
  String? _selectedContactType;
  final List<String> _contactTypes = ['Customer', 'Supplier'];

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

  Future<void> _saveContact() async {
    // We now check if the form is valid before saving.
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Contact Type.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

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
      contactType: _selectedContactType, // Pass the selected dropdown value
    );

    final success = await ApiService.saveCard(updatedCard);
    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    final message = success
        ? 'Contact saved successfully!'
        : 'Failed to save contact.';
    final color = success ? Colors.green : Colors.red;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));

    if (success) {
      Navigator.of(context).pop(true);
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
      // Wrap the content in a Form widget
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
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

              // The new Dropdown menu widget
              _buildDropdown(),

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
      ),
    );
  }

  // Helper widget for the new dropdown
  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      // Added a validator and a hint for a better user experience
      child: DropdownButtonFormField<String>(
        value: _selectedContactType,
        hint: const Text(
          'Choose a contact type...',
        ), // This text shows when no value is selected
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a type.'; // Error message if not selected
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
      child: TextField(
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
