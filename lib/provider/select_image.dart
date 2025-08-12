import 'dart:io';
import 'dart:typed_data';
import 'package:event_ticket_maker/helper/browser_finder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:html' as html;

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
       if (isMobileBrowser()) {
      _pickImageUsingHtmlInput(context);
      return;
    } 

      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final file = result.files.single;
        if (file.size > maxSizeInBytes) {
          _showSizeError(context, msg: "Image size should not exceed 1 MB.");
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
          _showSizeError(context, msg: "Image size should not exceed 1 MB.");
          return;
        }

        _selectedImageFile = file;
        notifyListeners();
      }
    }
  }

  void _showSizeError(BuildContext context, {required String msg}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _pickImageUsingHtmlInput(BuildContext context) {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();

    input.onChange.listen((event) {
      final file = input.files?.first;
      final reader = html.FileReader();

      if (file != null) {
        if (file.size > 1048576) {
          _showSizeError(context, msg: "Image size should not exceed 1 MB.");
          return;
        }

        reader.readAsArrayBuffer(file);
        reader.onLoadEnd.listen((event) {
          _webImage = reader.result as Uint8List?;
          _webFileName = file.name;
          notifyListeners();
        });
      }
    });
  }

  void clearImage() {
    _selectedImageFile = null;
    _webImage = null;
    _webFileName = null;
    notifyListeners();
  }
}
