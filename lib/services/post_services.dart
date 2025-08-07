import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PostServices {
  static Future<void> uploadWebImage({
    required Uint8List imageData,
    required String fileName,
    required String ticketId,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://event-backend-fd1l.onrender.com/api/upload-id'),
    );
    request.fields['ticket_id'] = ticketId;
    request.files.add(
      http.MultipartFile.fromBytes('file', imageData, filename: fileName),
    );

    final response = await request.send();
    if (response.statusCode == 200) {
      debugPrint("Web image uploaded successfully");
    } else {
      log(response.toString());
      debugPrint("Web image upload failed: ${response.statusCode}");
    }
  }

  static Future<void> uploadMobileImage({
    required File file,
    required String ticketId,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://event-backend-fd1l.onrender.com/api/upload-id'),
    );
    request.fields['ticket_id'] = ticketId;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      debugPrint("Mobile image uploaded successfully");
    } else {
      debugPrint("Mobile image upload failed: ${response.statusCode}");
    }
  }
}
