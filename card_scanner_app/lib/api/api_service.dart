import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:card_scanner_app/models/image_data.dart';
import 'package:http/http.dart' as http;
import '../models/business_card.dart';

class ApiService {
  // --- FOR LOCAL DEVELOPMENT ---
  // Use this when testing on a physical device.
  // Replace "YOUR_LAPTOP_IP" with your computer's local IP address.
  // static const String _baseUrl = 'http://YOUR_LAPTOP_IP:5001';

  // Use this when testing on a local emulator or as a desktop app.
  static const String _baseUrl =
      'https://business-card-scanner-tnu4.onrender.com';

  // --- FOR PRODUCTION ---
  // static const String _baseUrl = 'https://business-card-scanner-tnu4.onrender.com';

  static Future<List<BusinessCard?>> scanBatch({
    required List<ImageData> images,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/scan-batch');
      var request = http.MultipartRequest('POST', uri);

      for (var image in images) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'images', // The key must match the backend
            image.bytes,
            filename: image.name,
          ),
        );
      }

      print("Sending batch of ${images.length} images to local backend...");

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );

      if (streamedResponse.statusCode == 200) {
        final responseBody = await streamedResponse.stream.bytesToString();
        print("Backend Response: $responseBody");
        final List<dynamic> decodedList = json.decode(responseBody);
        return decodedList.map((json) => BusinessCard.fromJson(json)).toList();
      } else {
        final errorBody = await streamedResponse.stream.bytesToString();
        print("Server Error: ${streamedResponse.statusCode}");
        print("Error Body: $errorBody");
        return [];
      }
    } on TimeoutException {
      print("The connection to the server timed out after 60 seconds.");
      throw Exception('Server timed out. Please try again later.');
    } catch (e) {
      print("An exception occurred during batch scan: $e");
      throw Exception('Could not analyze cards. Please try again later.');
    }
  }

  static Future<bool> saveCard(BusinessCard card) async {
    try {
      final uri = Uri.parse('$_baseUrl/save-contact');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(card.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        print("Contact saved successfully.");
        return true;
      } else {
        print("Failed to save contact. Status: ${response.statusCode}");
        print("Response Body: ${response.body}");
        return false;
      }
    } on TimeoutException {
      print("The connection to the server timed out while saving.");
      return false;
    } catch (e) {
      print("An exception occurred while saving: $e");
      return false;
    }
  }
}
