import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

const Color _kAccent = Color(0xFFFF6B35);
const Color _kTextPrimary = Color(0xFFF0F0FF);
const Color _kTextSecondary = Color(0xFF9090B0);
const Color _kGlass = Color(0x1AFFFFFF);
const Color _kGlassBorder = Color(0x33FFFFFF);

class PremiumImagePicker extends StatefulWidget {
  final bool imageSelected;
  final dynamic userProvider;

  const PremiumImagePicker({
    super.key,
    required this.imageSelected,
    required this.userProvider,
  });

  @override
  State<PremiumImagePicker> createState() => _PremiumImagePickerState();
}

class _PremiumImagePickerState extends State<PremiumImagePicker> {
  bool _hovering = false;

  String get _fileName {
    if (!widget.imageSelected) return 'No file selected';
    if (kIsWeb) {
      return widget.userProvider.webFileName ?? 'web_image.jpg';
    }
    return widget.userProvider.selectedImageFile?.path.split('/').last ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final bool selected = widget.imageSelected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kAccent, Color(0xFFFFD700)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  '04',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Upload ID / Proof',
              style: TextStyle(
                color: _kTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: const Text(
                'Required',
                style: TextStyle(
                  color: _kTextSecondary,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: GestureDetector(
            onTap: () => widget.userProvider.pickImage(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 22,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF1A4D2E).withValues(alpha: .35)
                        : _hovering
                        ? _kAccent.withValues(alpha: .08)
                        : _kGlass,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected
                          ? Colors.greenAccent.withValues(alpha: .5)
                          : _hovering
                          ? _kAccent.withValues(alpha: .6)
                          : _kGlassBorder,
                      width: 1.5,
                    ),
                  ),
                  child: selected
                      ? _SelectedState(
                          fileName: _fileName,
                          userProvider: widget.userProvider,
                        )
                      : _EmptyState(hovering: _hovering),
                ),
              ),
            ),
          ),
        ),

        if (!selected)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: _kTextSecondary.withValues(alpha: .6),
                  size: 12,
                ),
                const SizedBox(width: 5),
                const Text(
                  'JPG, PNG or PDF · Max 5 MB',
                  style: TextStyle(color: _kTextSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hovering;
  const _EmptyState({required this.hovering});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Upload icon inside a glowing box
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: hovering
                ? _kAccent.withValues(alpha: .2)
                : Colors.white.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hovering
                  ? _kAccent.withValues(alpha: .5)
                  : Colors.white.withValues(alpha: .1),
            ),
            boxShadow: hovering
                ? [
                    BoxShadow(
                      color: _kAccent.withValues(alpha: .3),
                      blurRadius: 16,
                    ),
                  ]
                : [],
          ),
          child: Icon(
            Icons.upload_file_rounded,
            color: hovering ? _kAccent : _kTextSecondary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hovering ? 'Click to browse...' : 'Upload your ID card',
                style: TextStyle(
                  color: hovering ? _kAccent : _kTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'College ID, Aadhar, or any valid proof',
                style: TextStyle(color: _kTextSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
        // Arrow indicator
        AnimatedOpacity(
          opacity: hovering ? 1 : 0.3,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kAccent.withValues(alpha: .15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: _kAccent,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectedState extends StatefulWidget {
  final String fileName;
  final dynamic userProvider;

  const _SelectedState({required this.fileName, required this.userProvider});

  @override
  State<_SelectedState> createState() => _SelectedStateState();
}

class _SelectedStateState extends State<_SelectedState>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkCtrl;
  late Animation<double> _checkAnim;

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _checkAnim = CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    super.dispose();
  }

  String get _ext {
    final parts = widget.fileName.split('.');
    return parts.length > 1 ? parts.last.toUpperCase() : 'FILE';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ScaleTransition(
          scale: _checkAnim,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.greenAccent.withValues(alpha: .4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent.withValues(alpha: .2),
                  blurRadius: 14,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.greenAccent,
              size: 26,
            ),
          ),
        ),
        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _ext,
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kTextPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'File uploaded successfully',
                style: TextStyle(color: Colors.greenAccent, fontSize: 11),
              ),
            ],
          ),
        ),

        GestureDetector(
          onTap: () => widget.userProvider.pickImage(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _kAccent.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kAccent.withValues(alpha: .4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_rounded, color: _kAccent, size: 14),
                SizedBox(width: 4),
                Text(
                  'Change',
                  style: TextStyle(
                    color: _kAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
