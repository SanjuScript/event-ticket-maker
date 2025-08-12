import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static Future<String> uploadImageFile({
    required File file,
    required String path,
  }) async {
    final ref = _storage.ref().child(path);

    final uploadTask = ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final snapshot = await uploadTask.whenComplete(() {});
    final downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
  }

  static Future<String> uploadWebImage({
    required Uint8List data,
    required String path,
  }) async {
    final ref = _storage.ref().child(path);

    final uploadTask = ref.putData(
      data,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final snapshot = await uploadTask.whenComplete(() {});
    final downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
  }

  static Future<void> updateID(String ticketId, String imageUrl) async {
    final url = Uri.parse(
      'https://us-central1-event-ticket-maker-8e724.cloudfunctions.net/api/update-ticket-image',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'ticket_id': ticketId, 'id_card_url': imageUrl}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update ticket with image URL');
    }
  }
}
