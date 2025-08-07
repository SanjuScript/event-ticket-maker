import 'dart:html' as html; // ⬅️ Only for Flutter Web
import 'dart:typed_data';
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
    Future.delayed(const Duration(milliseconds: 500), _autoDownloadQrImage); // ⬅️ Try auto-download
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Ticket ID copied")),
    );
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
                child: QrImageView(
                  data: widget.ticketId,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
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
                    label: const Text("Download QR"),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _copyTicketId,
                    icon: const Icon(Icons.copy),
                    label: const Text("Copy ID"),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Back to Home"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
