import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class PremiumImagePicker extends StatelessWidget {
  final bool imageSelected;
  final dynamic userProvider;

  const PremiumImagePicker({
    super.key,
    required this.imageSelected,
    required this.userProvider,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = imageSelected
        ? (kIsWeb
            ? userProvider.webFileName ?? 'web_image.jpg'
            : userProvider.selectedImageFile?.path.split('/').last ?? '')
        : "No image selected";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                imageSelected ? Icons.check_circle : Icons.warning,
                color: imageSelected ? Colors.white : Colors.redAccent,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: imageSelected ? Colors.white : Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => userProvider.pickImage(context),
              icon: const Icon(Icons.upload_file, color: Colors.white),
              label: Text(
                imageSelected ? "Change Image" : "Select Image",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ).copyWith(
                backgroundColor: WidgetStateProperty.all(
                  Colors.transparent,
                ),
                elevation: WidgetStateProperty.all(0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
