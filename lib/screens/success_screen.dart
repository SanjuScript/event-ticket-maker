import 'dart:html' as html;
import 'dart:typed_data';
import 'package:event_ticket_maker/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;

class SuccessScreen extends StatefulWidget {
  final String ticketId;

  const SuccessScreen({super.key, required this.ticketId});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  final GlobalKey qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), _autoDownloadQrImage);
  }

  Future<void> _autoDownloadQrImage() async {
    try {
      final imageBytes = await _capturePng();
      final blob = html.Blob([imageBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "ticket-${widget.ticketId}.png")
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      debugPrint("❌ Auto-download failed: $e");
    }
  }

  Future<Uint8List> _capturePng() async {
    final boundary =
        qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _manualDownload() async {
    final bytes = await _capturePng();
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "ticket-${widget.ticketId}.png")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _copyTicketId() {
    Clipboard.setData(ClipboardData(text: widget.ticketId));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("✅ Ticket ID copied")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.celebration, color: Colors.orange, size: 50),
              const SizedBox(height: 16),
              const Text(
                'Ticket Booked Successfully!',
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
              const SizedBox(height: 20),
              RepaintBoundary(
                key: qrKey,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: QrImageView(
                    data: widget.ticketId,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.circle,
                      color: Colors.deepPurple,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.circle,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SelectableText(
                "Ticket ID: ${widget.ticketId}",
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _manualDownload,
                    icon: const Icon(Icons.download),
                    label: Text(
                      "Download QR",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _copyTicketId,
                    icon: const Icon(Icons.copy),
                    label: Text(
                      "Copy ID",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => HomeScreen()),
                    (route) => false,
                  );
                },
                child: Text(
                  "Back to Home",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
