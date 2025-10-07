import 'dart:convert';
import 'dart:async'; // Import for timeout functionality
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/business_card.dart';

class ApiService {
  static const String _baseUrl =
      'https://business-card-scanner-tnu4.onrender.com';

  static Future<BusinessCard?> scanCard({
    required Uint8List frontImageBytes,
    required String frontFilename,
    Uint8List? backImageBytes,
    String? backFilename,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/scan-card');
      var request = http.MultipartRequest('POST', uri);

      request.files.add(
        http.MultipartFile.fromBytes(
          'front',
          frontImageBytes,
          filename: frontFilename,
        ),
      );

      if (backImageBytes != null && backFilename != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'back',
            backImageBytes,
            filename: backFilename,
          ),
        );
      }

      print("Sending images to live backend...");

      // THE FIX IS HERE: We now send the request and wait for a response, with a 30-second timeout.
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );

      if (streamedResponse.statusCode == 200) {
        final responseBody = await streamedResponse.stream.bytesToString();
        print("Backend Response: $responseBody");
        final decodedData = json.decode(responseBody);
        return BusinessCard.fromJson(decodedData);
      } else {
        final errorBody = await streamedResponse.stream.bytesToString();
        print("Server Error: ${streamedResponse.statusCode}");
        print("Error Body: $errorBody");
        return null;
      }
    } on TimeoutException {
      print("The connection to the server timed out after 30 seconds.");
      return null;
    } catch (e) {
      print("An exception occurred during scan: $e");
      return null;
    }
  }

  static Future<bool> saveCard(BusinessCard card) async {
    try {
      final uri = Uri.parse('$_baseUrl/save-contact');
      // THE FIX IS HERE: We also add a timeout to the save operation.
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
