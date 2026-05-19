// ignore: deprecated_member_use
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:event_ticket_maker/theme/site_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

// Match your app's color scheme exactly
const _bg = Color(0xFF0A0A0A);
const _surface = Color(0xFF141414);
const _card = Color(0xFF1C1C1C);
const _white = Color(0xFFF5F5F0);
const _muted = Color(0xFF888888);
const _border = Color(0xFF2A2A2A);
const _green = Color(0xFF4CAF50);
const _red = Color(0xFFFF4444);

class SuccessScreen extends StatefulWidget {
  final String ticketId;
  final String ticketType; // 'General Admission' or 'VIP Access'
  final int quantity;
  final int totalPrice;
  final Map<String, dynamic> settings; // pass your Firestore settings map

  const SuccessScreen({
    super.key,
    required this.ticketId,
    required this.ticketType,
    required this.quantity,
    required this.totalPrice,
    required this.settings,
  });

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _qrKey = GlobalKey();
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _copied = false;

  Color get _accentColor => context.siteAccent;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 100), _ctrl.forward);
    Future.delayed(const Duration(milliseconds: 900), _autoDownload);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return '';
    final d = (ts as dynamic).toDate() as DateTime;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<Uint8List> _capture() async {
    final b =
        _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final img = await b.toImage(pixelRatio: 3.0);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<void> _autoDownload() async {
    try {
      final bytes = await _capture();
      final url = html.Url.createObjectUrlFromBlob(html.Blob([bytes]));
      html.AnchorElement(href: url)
        ..setAttribute(
          'download',
          '${(widget.settings['eventName'] ?? 'ticket').toString().toLowerCase().replaceAll(' ', '-')}-${widget.ticketId}.png',
        )
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      debugPrint('Download failed: $e');
    }
  }

  void _copyId() {
    Clipboard.setData(ClipboardData(text: widget.ticketId));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 720;
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.pushReplacementNamed(context, '/');
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 80 : 24,
                    vertical: 40,
                  ),
                  child: wide ? _desktopBody(context) : _mobileBody(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Mobile ────────────────────────────────────────────────

  Widget _mobileBody(BuildContext ctx) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _topBar(),
      const SizedBox(height: 32),
      _heading(),
      const SizedBox(height: 28),
      RepaintBoundary(key: _qrKey, child: _ticket()),
      const SizedBox(height: 20),
      _actions(),
    ],
  );

  // ── Desktop ───────────────────────────────────────────────

  Widget _desktopBody(BuildContext ctx) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 960),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar(),
        const SizedBox(height: 48),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_heading(), const SizedBox(height: 32), _actions()],
              ),
            ),
            const SizedBox(width: 40),
            Expanded(
              flex: 5,
              child: RepaintBoundary(key: _qrKey, child: _ticket()),
            ),
          ],
        ),
      ],
    ),
  );

  // ── Top bar ───────────────────────────────────────────────

  Widget _topBar() => Row(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: _accentColor.withOpacity(0.4)),
        ),
        child: Icon(Icons.bolt_rounded, color: _accentColor, size: 14),
      ),
      const SizedBox(width: 10),
      Text(
        (widget.settings['eventName'] ?? 'Event').toUpperCase(),
        style: const TextStyle(
          color: _white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 3,
        ),
      ),
    ],
  );

  // ── Heading ───────────────────────────────────────────────

  Widget _heading() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _CheckRing(),
      const SizedBox(height: 16),
      Text(
        "YOU'RE IN",
        style: TextStyle(
          color: _accentColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 4,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Booking\nConfirmed',
        style: TextStyle(
          color: _white,
          fontSize: 48,
          fontWeight: FontWeight.w900,
          height: 1.0,
          letterSpacing: -2,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'Your ${widget.ticketType} ticket for\n${widget.settings['eventName'] ?? 'the event'} is locked in.',
        style: const TextStyle(color: _muted, fontSize: 14, height: 1.6),
      ),
    ],
  );

  // ── Ticket card ───────────────────────────────────────────

  Widget _ticket() => Container(
    decoration: BoxDecoration(
      color: _surface,
      border: Border.all(color: _border),
    ),
    child: Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (widget.settings['eventName'] ?? 'EVENT')
                          .toString()
                          .toUpperCase(),
                      style: TextStyle(
                        color: _accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.settings['eventSubtitle'] ?? '',
                      style: const TextStyle(
                        color: _white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          color: _accentColor,
                          size: 11,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _formatDate(widget.settings['eventDate']),
                          style: const TextStyle(color: _muted, fontSize: 12),
                        ),
                        const SizedBox(width: 14),
                        Icon(
                          Icons.location_on_outlined,
                          color: _accentColor,
                          size: 11,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            widget.settings['location'] ?? '',
                            style: const TextStyle(color: _muted, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Confirmed badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.1),
                      border: Border.all(color: _green.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _green,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'CONFIRMED',
                          style: TextStyle(
                            color: _green,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Price
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: _accentColor.withOpacity(0.35)),
                    ),
                    child: Text(
                      '₹${widget.totalPrice}',
                      style: TextStyle(
                        color: _accentColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Ticket type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    color: _card,
                    child: Text(
                      widget.ticketType.toUpperCase(),
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 9,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Perforated divider
        const _TearLine(),

        // QR + details
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // QR
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: _accentColor.withOpacity(0.15),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: widget.ticketId,
                  version: QrVersions.auto,
                  size: 120,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF0A0A0A),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TICKET ID',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    SelectableText(
                      widget.ticketId,
                      style: const TextStyle(
                        color: _white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Quantity row
                    Row(
                      children: [
                        const Text(
                          'QTY',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 9,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.quantity}',
                          style: TextStyle(
                            color: _accentColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            _accentColor.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Show QR at entrance',
                      style: TextStyle(color: _muted, fontSize: 11),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Non-transferable  ·  No re-entry',
                      style: TextStyle(color: Color(0xFF555555), fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  // ── Actions ───────────────────────────────────────────────

  Widget _actions() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          _Btn(
            label: 'Download',
            icon: Icons.download_rounded,
            filled: true,
            onTap: _autoDownload,
          ),
          const SizedBox(width: 10),
          _Btn(
            label: _copied ? 'Copied!' : 'Copy ID',
            icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
            onTap: _copyId,
          ),
        ],
      ),
      const SizedBox(height: 12),
      const Text(
        'Ticket auto-saved to downloads',
        style: TextStyle(color: Color(0xFF444444), fontSize: 11),
      ),
    ],
  );
}

// ── Animated check ring ───────────────────────────────────

class _CheckRing extends StatefulWidget {
  const _CheckRing();

  @override
  State<_CheckRing> createState() => _CheckRingState();
}

class _CheckRingState extends State<_CheckRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _ring, _check;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _ring = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _check = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
    );
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: const Size(52, 52), painter: _Arc(_ring.value)),
          Transform.scale(
            scale: _check.value,
            child: const Icon(Icons.check_rounded, color: _green, size: 24),
          ),
        ],
      ),
    ),
  );
}

class _Arc extends CustomPainter {
  final double p;
  _Arc(this.p);

  @override
  void paint(Canvas c, Size s) => c.drawArc(
    Rect.fromCircle(center: s.center(Offset.zero), radius: 24),
    -math.pi / 2,
    2 * math.pi * p,
    false,
    Paint()
      ..color = _green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round,
  );

  @override
  bool shouldRepaint(_Arc o) => o.p != p;
}

// ── Perforated tear line ──────────────────────────────────

class _TearLine extends StatelessWidget {
  const _TearLine();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _notch(true),
      Expanded(
        child: LayoutBuilder(
          builder: (_, c) {
            final n = (c.maxWidth / 12).floor();
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                n,
                (_) => Container(width: 5, height: 1, color: _border),
              ),
            );
          },
        ),
      ),
      _notch(false),
    ],
  );

  Widget _notch(bool left) => Container(
    width: 16,
    height: 24,
    decoration: BoxDecoration(
      color: _bg,
      borderRadius: BorderRadius.horizontal(
        left: left ? Radius.zero : const Radius.circular(16),
        right: left ? const Radius.circular(16) : Radius.zero,
      ),
    ),
  );
}

// ── Button ────────────────────────────────────────────────

class _Btn extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _Btn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  State<_Btn> createState() => _BtnState();
}

class _BtnState extends State<_Btn> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _h = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _h = true),
    onExit: (_) => setState(() => _h = false),
    child: GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onTap();
      },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: Tween<double>(
          begin: 1.0,
          end: 0.96,
        ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut)),
        child: Builder(
          builder: (context) {
            final accent = context.siteAccent;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: widget.filled
                    ? (_h ? accent.withOpacity(0.85) : accent)
                    : Colors.transparent,
                border: widget.filled
                    ? null
                    : Border.all(color: _h ? accent.withOpacity(0.5) : _border),
                boxShadow: widget.filled && _h
                    ? [
                        BoxShadow(
                          color: accent.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    size: 15,
                    color: widget.filled
                        ? Colors.black
                        : (_h ? accent : _muted),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.filled
                          ? Colors.black
                          : (_h ? accent : _muted),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}
