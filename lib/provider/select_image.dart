import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class ImageUploadProvider with ChangeNotifier {
  File? _selectedImageFile;
  Uint8List? _webImage;
  String? _webFileName;

  File? get selectedImageFile => _selectedImageFile;
  Uint8List? get webImage => _webImage;
  String? get webFileName => _webFileName;

  Future<void> pickImage(BuildContext context) async {
    const maxSizeInBytes = 1048576;

    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final file = result.files.single;
        if (file.size > maxSizeInBytes) {
          _showSizeError(context);
          return;
        }

        _webImage = file.bytes;
        _webFileName = file.name;
        notifyListeners();
      }
    } else {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();

        if (fileSize > maxSizeInBytes) {
          _showSizeError(context);
          return;
        }

        _selectedImageFile = file;
        notifyListeners();
      }
    }
  }

  void _showSizeError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Image size should not exceed 1 MB."),
        backgroundColor: Colors.red,
      ),
    );
  }

  void clearImage() {
    _selectedImageFile = null;
    _webImage = null;
    _webFileName = null;
    notifyListeners();
  }
}
