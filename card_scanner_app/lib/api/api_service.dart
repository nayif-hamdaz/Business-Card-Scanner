import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/business_card.dart';

class ApiService {
  // Use localhost for Chrome or 10.0.2.2 for Android Emulator
  static const String _baseUrl = 'https://business-card-scanner-tnu4.onrender.com';

  // This function is now updated to send both a front and an optional back image
  static Future<BusinessCard?> scanCard({
    required Uint8List frontImageBytes,
    required String frontFilename,
    Uint8List? backImageBytes,
    String? backFilename,
  }) async {
    try {
      final Uri uri = Uri.parse('$_baseUrl/scan-card');
      final request = http.MultipartRequest('POST', uri);

      // Add front image (required)
      final frontFile = http.MultipartFile.fromBytes(
        'front', // Field name must match the backend: request.files['front']
        frontImageBytes,
        filename: frontFilename,
      );
      request.files.add(frontFile);

      // Add back image (optional)
      if (backImageBytes != null && backFilename != null) {
        final backFile = http.MultipartFile.fromBytes(
          'back', // Field name must match the backend: request.files.get('back')
          backImageBytes,
          filename: backFilename,
        );
        request.files.add(backFile);
        print('Sending front and back images to backend...');
      } else {
        print('Sending front image to backend...');
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        print('Backend Response: $responseBody');
        final Map<String, dynamic> jsonData = jsonDecode(responseBody);
        return BusinessCard.fromJson(jsonData);
      } else {
        final errorBody = await response.stream.bytesToString();
        print('Server Error: ${response.statusCode}');
        print('Error Body: $errorBody');
        return null;
      }
    } catch (e) {
      print('An exception occurred: $e');
      return null;
    }
  }

  // The saveCard function remains the same as it's already correct
  static Future<bool> saveCard(BusinessCard card) async {
    try {
      final Uri uri = Uri.parse('$_baseUrl/save-contact');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(card.toJson()),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Save successful: ${responseData['message']}');
        return true;
      } else {
        print('Server Error on save: ${response.statusCode}');
        print('Error Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('An exception occurred during save: $e');
      return false;
    }
  }
}

