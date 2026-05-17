import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'dart:ui';
import 'package:event_ticket_maker/helper/string_helper.dart';
import 'package:event_ticket_maker/models/payment_model.dart';
import 'package:event_ticket_maker/provider/device_info_provider.dart';
import 'package:event_ticket_maker/provider/verification_state.dart';
import 'package:event_ticket_maker/screens/auth/login_screen.dart';
import 'package:event_ticket_maker/widgets/developer_info.dart';
import 'package:event_ticket_maker/widgets/info_row.dart';
import 'package:event_ticket_maker/widgets/loading_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_razorpay_web/flutter_razorpay_web.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

bool _isDesktop(BuildContext ctx) => MediaQuery.of(ctx).size.width >= 768;

class _BgLaserPainter extends CustomPainter {
  final double t;
  _BgLaserPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    for (final (sx, col, amp, phase) in [
      (0.12, kNeonCyan, 0.18, 0.0),
      (0.88, kNeonMagenta, 0.14, 1.4),
      (0.50, kPurple, 0.12, 2.8),
    ]) {
      final startX = w * sx;
      final angle = math.sin(t * 2 * math.pi + phase) * amp;
      final endX = startX + math.sin(angle) * h * 1.1;
      canvas.drawLine(
        Offset(startX, h),
        Offset(endX, -h * 0.1),
        Paint()
          ..color = col.withOpacity(0.08)
          ..strokeWidth = 1.5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  @override
  bool shouldRepaint(_BgLaserPainter old) => old.t != t;
}

// ─── Neon Glass Field ─────────────────────────────────────────────────────────
class _NeonField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? prefixText;
  const _NeonField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.prefixText,
  });
  @override
  State<_NeonField> createState() => _NeonFieldState();
}

class _NeonFieldState extends State<_NeonField> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _focused
              ? kNeonCyan.withOpacity(0.07)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _focused ? kNeonCyan : Colors.white.withOpacity(0.12),
            width: _focused ? 1.5 : 1,
          ),
          boxShadow: _focused
              ? [BoxShadow(color: kNeonCyan.withOpacity(0.20), blurRadius: 18)]
              : [],
        ),
        child: TextField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(
              color: _focused
                  ? kNeonCyan.withOpacity(0.8)
                  : Colors.white.withOpacity(0.4),
              fontSize: 13,
            ),
            prefixIcon: Icon(
              widget.icon,
              color: _focused ? kNeonCyan : Colors.white38,
              size: 19,
            ),
            prefix: widget.prefixText != null
                ? Text(
                    widget.prefixText!,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Buy Button ───────────────────────────────────────────────────────────────
class _BuyButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _BuyButton({required this.onPressed});
  @override
  State<_BuyButton> createState() => _BuyButtonState();
}

class _BuyButtonState extends State<_BuyButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _hover = false;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onPressed();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 1.0,
            end: 0.96,
          ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _hover
                    ? [kNeonMagenta, kPurple, kNeonCyan]
                    : [kNeonMagenta, kPurple],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: kNeonMagenta.withOpacity(_hover ? 0.65 : 0.40),
                  blurRadius: _hover ? 36 : 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: kPurple.withOpacity(0.28),
                  blurRadius: 22,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.confirmation_num_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Complete Booking  •  ₹705',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Ticket Divider ───────────────────────────────────────────────────────────
class _TicketDivider extends StatelessWidget {
  const _TicketDivider();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _semi(true),
        Expanded(
          child: LayoutBuilder(
            builder: (_, c) {
              final count = (c.maxWidth / 12).floor();
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  count,
                  (_) => Container(
                    width: 6,
                    height: 2,
                    decoration: BoxDecoration(
                      color: kNeonCyan.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        _semi(false),
      ],
    );
  }

  Widget _semi(bool left) => Container(
    width: 16,
    height: 32,
    decoration: BoxDecoration(
      color: const Color(0xFF0A0812),
      borderRadius: BorderRadius.horizontal(
        left: left ? Radius.zero : const Radius.circular(16),
        right: left ? const Radius.circular(16) : Radius.zero,
      ),
    ),
  );
}

// ─── Home Screen ──────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  RazorpayWeb razorpayWeb = RazorpayWeb();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  late final AnimationController _fxCtrl, _waveCtrl, _enterCtrl;
  late final Animation<double> _enterFade;
  late final Animation<Offset> _enterSlide;

  void _handlePaymentSuccess(RpaySuccessResponse response) {
    final resp = response.toMap();
    verifyAndSaveTicket(
      response: RazorpayPaymentModel.fromJson(resp),
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
    );
  }

  void _handlePaymentError(RpayFailedResponse response) =>
      StringHelper.showError("Payment failed: $response", context);
  void _handleOnCancel(RpayCancelResponse response) =>
      log(response.toJson().toString());

  Future<void> startPayment() async {
    final pp = Provider.of<PaymentProvider>(context, listen: false);
    pp.setLoading(true);
    try {
      final name = _nameCtrl.text.trim();
      final phone = _phoneCtrl.text.trim();
      final err = StringHelper.validateFields(
        name,
        phone,
        RegExp(r'^[6-9]\d{9}$'),
      );
      if (err != null) {
        StringHelper.showError(err, context);
        pp.setLoading(false);
        return;
      }

      final response = await http.post(
        Uri.parse('http://localhost:3000/create-order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': 705 * 100,
          'receipt': 'receipt_${DateTime.now().millisecondsSinceEpoch}',
        }),
      );
      final data = jsonDecode(response.body);
      if (data['status'] != 'success') {
        if (mounted) StringHelper.showError("Order creation failed.", context);
        pp.setLoading(false);
        return;
      }
      makePayment(
        orderId: data['body']['id'],
        keyId: "rzp_test_SOoQi14i47lKnS",
        amount: 705 * 100,
        name: name,
        phone: phone,
      );
    } catch (e) {
      if (mounted) {
        StringHelper.showError("An unexpected error occurred.", context);
      }
      pp.setLoading(false);
    } finally {
      pp.setLoading(false);
    }
  }

  Future<void> verifyAndSaveTicket({
    required RazorpayPaymentModel response,
    required String name,
    required String phone,
  }) async {
    final pp = Provider.of<PaymentProvider>(context, listen: false);
    final devP = Provider.of<DeviceInfoProvider>(context, listen: false);
    pp.setLoading(true);

    try {
      final res = await http.post(
        Uri.parse('http://localhost:3000/verify-payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'payment_info': response.toJson(),
          'name': name,
          'phone': phone,
          'device_info': {
            'device_model': devP.deviceModel,
            'os': devP.os,
            'user_agent': devP.userAgent,
            'language': devP.language,
          },
          'ip_address': devP.ipAddress,
        }),
      );
      final result = jsonDecode(res.body);
      if (result['status'] == 'success') {
        pp.setPayment(true);
        final ticketId = result['ticket_id'];
        String? imageUrl;

        pp.setLoading(false);
        if (mounted) {
          // Navigator.pushReplacement(
          //   context,
          //   MaterialPageRoute(
          //     builder: (_) => SuccessScreen(ticketId: ticketId),
          //   ),
          // );
        }
      } else {
        pp.setLoading(false);
      }
    } catch (e) {
      log("Error: $e");
      pp.setLoading(false);
    }
  }

  void makePayment({
    required String orderId,
    required String keyId,
    required int amount,
    required String name,
    required String phone,
  }) {
    razorpayWeb.open({
      "key": keyId,
      "amount": "$amount",
      "currency": "INR",
      "name": "Anirudh Live Concert",
      "description": "Concert Ticket",
      "order_id": orderId,
      "send_sms_hash": true,
      'readonly': {'contact': true, 'email': true},
      'method': {
        'upi': true,
        'card': false,
        'netbanking': false,
        'wallet': false,
        'emi': false,
        'paylater': false,
      },
      "prefill": {"name": name, "contact": phone},
      "theme": {"color": "#FF006E"},
    });
  }

  @override
  void initState() {
    super.initState();
    razorpayWeb = RazorpayWeb(
      onSuccess: _handlePaymentSuccess,
      onCancel: _handleOnCancel,
      onFailed: _handlePaymentError,
    );
    _fxCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..repeat();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _enterFade = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _enterSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut));
    _enterCtrl.forward();
  }

  @override
  void dispose() {
    razorpayWeb.clear();
    _fxCtrl.dispose();
    _waveCtrl.dispose();
    _enterCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = _isDesktop(context);

    return Scaffold(
      backgroundColor: kDeepBlack,
      body: Consumer<PaymentProvider>(
        builder: (context, pp, _) => Stack(
          children: [
            // // BG gradient
            // Image.network(
            //   height: MediaQuery.sizeOf(context).height,
            //   width: MediaQuery.sizeOf(context).height,
            //   fit: BoxFit.cover,
            //   webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
            //   "https://www.hollywoodreporterindia.com/_next/image?url=https%3A%2F%2Fcdn.hollywoodreporterindia.com%2Farticle%2F2025-08-12T08%253A56%253A32.583Z-Ani.jpg&w=3840&q=75",
            // ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromARGB(144, 4, 4, 7),
                    if (isDesktop) Color.fromARGB(139, 7, 6, 15),

                    Color.fromARGB(255, 7, 6, 15),
                    Color.fromARGB(255, 7, 6, 15),
                    Color(0xFF090812),
                    Color(0xFF0B0A17),
                  ],
                ),
              ),
            ),

            // Subtle lasers
            AnimatedBuilder(
              animation: _fxCtrl,
              builder: (_, __) => CustomPaint(
                size: size,
                painter: _BgLaserPainter(_fxCtrl.value),
              ),
            ),

            // Glows
            Positioned(
              top: -80,
              left: -60,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      kNeonMagenta.withOpacity(0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              right: -40,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [kNeonCyan.withOpacity(0.08), Colors.transparent],
                  ),
                ),
              ),
            ),

            // Content
            FadeTransition(
              opacity: _enterFade,
              child: SlideTransition(
                position: _enterSlide,
                child: SafeArea(
                  child: isDesktop
                      ? _DesktopLayout(
                          nameCtrl: _nameCtrl,
                          phoneCtrl: _phoneCtrl,
                          waveCtrl: _waveCtrl,
                          onPay: startPayment,
                        )
                      : _MobileLayout(
                          nameCtrl: _nameCtrl,
                          phoneCtrl: _phoneCtrl,
                          waveCtrl: _waveCtrl,
                          onPay: startPayment,
                        ),
                ),
              ),
            ),

            if (pp.isLoading)
              Positioned.fill(
                child: LoadingWidget(
                  isLoading: true,
                  isPaymentDone: pp.isPaymentDone,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  final TextEditingController nameCtrl, phoneCtrl;
  final AnimationController waveCtrl;
  final VoidCallback onPay;
  const _DesktopLayout({
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.waveCtrl,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: _EventPanel(waveCtrl: waveCtrl)),
              const SizedBox(width: 36),
              Expanded(
                flex: 4,
                child: _BookingCard(
                  nameCtrl: nameCtrl,
                  phoneCtrl: phoneCtrl,
                  onPay: onPay,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  final TextEditingController nameCtrl, phoneCtrl;
  final AnimationController waveCtrl;
  final VoidCallback onPay;
  const _MobileLayout({
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.waveCtrl,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        children: [
          _EventPanel(waveCtrl: waveCtrl),
          const SizedBox(height: 24),
          _BookingCard(nameCtrl: nameCtrl, phoneCtrl: phoneCtrl, onPay: onPay),
        ],
      ),
    );
  }
}

class _EventPanel extends StatelessWidget {
  final AnimationController waveCtrl;
  const _EventPanel({required this.waveCtrl});

  @override
  Widget build(BuildContext context) {
    final isDesktop = _isDesktop(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ANIRUDH',
          style: TextStyle(
            color: kNeonCyan,
            fontSize: isDesktop ? 64 : 48,
            fontWeight: FontWeight.w900,
            letterSpacing: -2,
            height: 0.90,
            shadows: [
              Shadow(color: kNeonCyan.withOpacity(0.55), blurRadius: 30),
            ],
          ),
        ),
        Text(
          'RAVICHANDER',
          style: TextStyle(
            color: Colors.white.withOpacity(0.88),
            fontSize: isDesktop ? 28 : 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'LIVE IN CONCERT',
          style: TextStyle(
            color: kNeonMagenta,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 6,
            shadows: [
              Shadow(color: kNeonMagenta.withOpacity(0.65), blurRadius: 12),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.035),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kNeonCyan.withOpacity(0.10), width: 1),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EVENT DETAILS',
                style: TextStyle(
                  color: kNeonCyan,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.5,
                ),
              ),
              SizedBox(height: 14),
              InfoRow(
                icon: Icons.calendar_today_rounded,
                text: 'Thursday, 28 August 2026',
                iconColor: kNeonGold,
              ),
              InfoRow(
                icon: Icons.location_on_rounded,
                text: 'Krupanidhi College, Bengaluru',
                iconColor: kNeonCyan,
              ),
              InfoRow(
                icon: Icons.access_time_rounded,
                text: 'Doors open at 6:00 PM',
                iconColor: kNeonMagenta,
              ),
              InfoRow(
                icon: Icons.people_alt_rounded,
                text: 'Open to all students & families',
                iconColor: Colors.lightBlueAccent,
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Stats
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Stat('5000+', 'Fans', kNeonCyan),
            Container(
              width: 1,
              height: 36,
              color: Colors.white.withOpacity(0.08),
            ),
            _Stat('3 HRS', 'Show', kNeonMagenta),
            Container(
              width: 1,
              height: 36,
              color: Colors.white.withOpacity(0.08),
            ),
            _Stat('50+', 'Songs', kNeonGold),
          ],
        ),

        const SizedBox(height: 18),

        // Feature pills
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Pill('🎤', 'Live Performance'),
            _Pill('🎵', 'Tamil Hits'),
            _Pill('🎆', 'Laser Show'),
            _Pill('📸', 'Photo Pit'),
            _Pill('🎸', 'Live Band'),
          ],
        ),
      ],
    );
  }

  Widget _Stat(String val, String label, Color color) => Column(
    children: [
      Text(
        val,
        style: TextStyle(
          color: color,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          shadows: [Shadow(color: color.withOpacity(0.55), blurRadius: 10)],
        ),
      ),
      Text(
        label,
        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
      ),
    ],
  );

  Widget _Pill(String emoji, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.09), width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.72),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

// ─── Booking Card ──────────────────────────────────────────────────────────────
class _BookingCard extends StatelessWidget {
  final TextEditingController nameCtrl, phoneCtrl;
  final VoidCallback onPay;
  const _BookingCard({
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.10),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ticket header stub
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      kNeonMagenta.withOpacity(0.22),
                      kPurple.withOpacity(0.18),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CONCERT TICKET',
                            style: TextStyle(
                              color: kNeonCyan,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Reserve Your Seat',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [kNeonMagenta, kPurple],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: kNeonMagenta.withOpacity(0.45),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Text(
                        '₹705',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Perforated divider
              const _TicketDivider(),

              // Form
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR DETAILS',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _NeonField(
                      controller: nameCtrl,
                      label: 'Full Name',
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 12),
                    _NeonField(
                      controller: phoneCtrl,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      prefixText: '+91 ',
                    ),

                    const SizedBox(height: 20),

                    const SizedBox(height: 24),

                    _BuyButton(onPressed: onPay),
                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 12,
                          color: Colors.white.withOpacity(0.25),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Secured by Razorpay  •  UPI only',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.25),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    const DeveloperInfo(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
