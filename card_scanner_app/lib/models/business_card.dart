import 'dart:typed_data';

class BusinessCard {
  final String category;
  final String organization;
  final String name;
  final String designation;
  final String contact;
  final String email;
  final String website;
  final String address;
  final String remarks;
  final String? contactType;

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
    this.contactType,
  });

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
      // THE FINAL FIX IS HERE: Changed back to 'ContactType' to match your Python code.
      'ContactType': contactType ?? '',
    };
  }
}

class ImageData {
  final Uint8List bytes;
  final String name;

  ImageData({required this.bytes, required this.name});
}
