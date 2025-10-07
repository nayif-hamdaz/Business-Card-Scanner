import 'dart:typed_data';

class BusinessCard {
  // NEW: Added the category field.
  final String category;
  final String organization;
  final String name;
  final String designation;
  final String contact;
  final String email;
  final String website;
  final String address;
  final String remarks;

  BusinessCard({
    required this.category,
    required this.organization,
    required this.name,
    required this.designation,
    required this.contact,
    required this.email,
    required this.website,
    required this.address,
    required this.remarks,
  });

  // Factory constructor to create a BusinessCard from JSON.
  // This is used when we receive data from the Python backend.
  factory BusinessCard.fromJson(Map<String, dynamic> json) {
    return BusinessCard(
      category: json['category'] ?? '',
      organization: json['organization'] ?? '',
      name: json['name'] ?? '',
      designation: json['designation'] ?? '',
      contact: json['contact'] ?? '',
      email: json['email'] ?? '',
      website: json['website'] ?? '',
      address: json['address'] ?? '',
      remarks: json['remarks'] ?? '',
    );
  }

  // Method to convert a BusinessCard object to JSON.
  // This is used when we send data to the Python backend to be saved.
  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'organization': organization,
      'name': name,
      'designation': designation,
      'contact': contact,
      'email': email,
      'website': website,
      'address': address,
      'remarks': remarks,
    };
  }
}

// A simple class to hold image data for passing between screens.
class ImageData {
  final Uint8List bytes;
  final String name;

  ImageData({required this.bytes, required this.name});
}

