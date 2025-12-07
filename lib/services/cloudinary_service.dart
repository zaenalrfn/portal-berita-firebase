// lib/services/cloudinary_service.dart
import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

import 'package:crypto/crypto.dart';

class CloudinaryService {
  final String cloudName;
  final String uploadPreset;
  final String? apiKey;
  final String? apiSecret;

  CloudinaryService({
    required this.cloudName,
    required this.uploadPreset,
    this.apiKey,
    this.apiSecret,
  });

  /// Upload file to Cloudinary (unsigned preset).
  /// Returns secure_url on success.
  Future<String> uploadImage(XFile file) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
    final parts = mimeType.split('/');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset;

    // Read bytes for cross-platform support (Web & Mobile)
    final bytes = await file.readAsBytes();

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name,
        contentType: MediaType(parts[0], parts[1]),
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body);
      if (body != null && body['secure_url'] != null) {
        return body['secure_url'] as String;
      } else {
        throw Exception(
          'Cloudinary upload succeeded but secure_url missing: ${response.body}',
        );
      }
    } else {
      throw Exception(
        'Cloudinary upload failed: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<void> deleteImage(String publicId) async {
    if (apiKey == null || apiSecret == null) {
      print('Cloudinary API Key/Secret missing. Skipping deletion.');
      return;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    // Signature generation:
    // Sort parameters (public_id, timestamp)
    // String to sign: public_id=...&timestamp=... + api_secret
    final params = {'public_id': publicId, 'timestamp': timestamp.toString()};
    final sortedKeys = params.keys.toList()..sort();
    final paramString = sortedKeys.map((k) => '$k=${params[k]}').join('&');
    final stringToSign = '$paramString$apiSecret';
    final signature = sha1.convert(utf8.encode(stringToSign)).toString();

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/destroy',
    );

    final response = await http.post(
      uri,
      body: {
        'public_id': publicId,
        'timestamp': timestamp.toString(),
        'api_key': apiKey,
        'signature': signature,
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      print('Cloudinary image deleted: $publicId');
    } else {
      print2('Cloudinary delete failed: ${response.body}');
      // Don't throw to avoid blocking the main flow (e.g. news deletion)
    }
  }
}

// Helper to print error
void print2(String s) => print(s);
