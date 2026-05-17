import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:event_ticket_maker/screens/auth/widgets/desktop_login.dart';
import 'package:event_ticket_maker/screens/auth/widgets/mobile_login.dart';
import 'package:event_ticket_maker/screens/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const kNeonCyan = Color(0xFF00F5FF);

const kNeonMagenta = Color(0xFFFF006E);
const kNeonGold = Color(0xFFFFD60A);
const kDeepBlack = Color(0xFF050508);
const kPurple = Color(0xFF7B2FFF);
const kPink = Color(0xFFFF2D78);

class _BgLaserPainter extends CustomPainter {
  final double t;
  _BgLaserPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final beams = [
      (0.15, kNeonCyan, 0.20, 0.0),
      (0.50, kNeonMagenta, 0.15, 1.2),
      (0.85, kPurple, 0.18, 2.4),
    ];
    for (final (sx, color, amp, phase) in beams) {
      final startX = w * sx;
      final angle = math.sin(t * 2 * math.pi + phase) * amp;
      final endX = startX + math.sin(angle) * h * 1.1;
      canvas.drawLine(
        Offset(startX, h),
        Offset(endX, -h * 0.1),
        Paint()
          ..color = color.withOpacity(0.10)
          ..strokeWidth = 1.5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  @override
  bool shouldRepaint(_BgLaserPainter old) => old.t != t;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  bool _showOtp = false, _isLoading = false;
  String _phone = '';
  int _resendSecs = 30;
  Timer? _timer;

  final _phoneCtrl = TextEditingController();
  final _phoneFocus = FocusNode();
  final _otpCtrls = List.generate(6, (_) => TextEditingController());
  final _otpFocuses = List.generate(6, (_) => FocusNode());

  late final AnimationController _bgCtrl, _cardCtrl, _shakeCtrl;
  late final Animation<double> _cardFade, _shake;
  late final Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _cardFade = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut));
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _shake = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -9.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -9.0, end: 9.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 9.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(_shakeCtrl);

    _cardCtrl.forward();
    Future.delayed(
      const Duration(milliseconds: 700),
      () => _phoneFocus.requestFocus(),
    );

    for (int i = 0; i < 6; i++) {
      _otpCtrls[i].addListener(() {
        if (_otpCtrls[i].text.length == 1 && i < 5) {
          _otpFocuses[i + 1].requestFocus();
        }
        if (_otpCtrls[i].text.isEmpty && i > 0) {
          _otpFocuses[i - 1].requestFocus();
        }
        setState(() {});
        if (_otpCtrls.every((c) => c.text.length == 1)) {
          Future.delayed(const Duration(milliseconds: 200), _verifyOtp);
        }
      });
    }
  }

  Future<void> _sendOtp() async {
    final p = _phoneCtrl.text.trim();
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(p)) {
      _shakeCtrl.forward(from: 0);
      _snack('Enter a valid 10-digit Indian mobile number');
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    setState(() {
      _isLoading = false;
      _phone = p;
      _showOtp = true;
    });
    _startTimer();
    Future.delayed(
      const Duration(milliseconds: 300),
      () => _otpFocuses[0].requestFocus(),
    );
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrls.map((c) => c.text).join();
    if (otp.length < 6) {
      _shakeCtrl.forward(from: 0);
      _snack('Enter the complete 6-digit OTP');
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1600));
    setState(() => _isLoading = false);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, __) => const HomeScreen(),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _resendSecs = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSecs == 0) {
        t.cancel();
      } else {
        setState(() => _resendSecs--);
      }
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _cardCtrl.dispose();
    _shakeCtrl.dispose();
    _timer?.cancel();
    _phoneCtrl.dispose();
    _phoneFocus.dispose();
    for (final c in _otpCtrls) {
      c.dispose();
    }
    for (final f in _otpFocuses) {
      f.dispose();
    }
    super.dispose();
  }

  bool get _isDesktop => MediaQuery.of(context).size.width >= 768;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: kDeepBlack,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF040408),
                  Color(0xFF07060F),
                  Color(0xFF090812),
                  Color(0xFF0B0A17),
                ],
              ),
            ),
          ),

          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _BgLaserPainter(_bgCtrl.value),
            ),
          ),

          Positioned(
            top: -100,
            left: size.width * 0.3,
            child: Container(
              width: 400,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [kPurple.withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -40,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [kNeonCyan.withOpacity(0.10), Colors.transparent],
                ),
              ),
            ),
          ),

          SafeArea(
            child: _isDesktop
                ? DesktopLogin(
                    showOtp: _showOtp,
                    isLoading: _isLoading,
                    phoneCtrl: _phoneCtrl,
                    phoneFocus: _phoneFocus,
                    otpCtrls: _otpCtrls,
                    otpFocuses: _otpFocuses,
                    phone: _phone,
                    resendSecs: _resendSecs,
                    cardFade: _cardFade,
                    cardSlide: _cardSlide,
                    shake: _shake,
                    onSend: _sendOtp,
                    onVerify: _verifyOtp,
                    onResend: () {
                      if (_resendSecs == 0) {
                        for (final c in _otpCtrls) {
                          c.clear();
                        }
                        _otpFocuses[0].requestFocus();
                        _startTimer();
                        _snack('OTP resent to +91 $_phone');
                      }
                    },
                    onBack: () => setState(() {
                      _showOtp = false;
                      for (final c in _otpCtrls) {
                        c.clear();
                      }
                    }),
                  )
                : MobileLogin(
                    showOtp: _showOtp,
                    isLoading: _isLoading,
                    phoneCtrl: _phoneCtrl,
                    phoneFocus: _phoneFocus,
                    otpCtrls: _otpCtrls,
                    otpFocuses: _otpFocuses,
                    phone: _phone,
                    resendSecs: _resendSecs,
                    cardFade: _cardFade,
                    cardSlide: _cardSlide,
                    shake: _shake,
                    onSend: _sendOtp,
                    onVerify: _verifyOtp,
                    onResend: () {
                      if (_resendSecs == 0) {
                        for (final c in _otpCtrls) {
                          c.clear();
                        }
                        _otpFocuses[0].requestFocus();
                        _startTimer();
                        _snack('OTP resent to +91 $_phone');
                      }
                    },
                    onBack: () => setState(() {
                      _showOtp = false;
                      for (final c in _otpCtrls) {
                        c.clear();
                      }
                    }),
                  ),
          ),
        ],
      ),
    );
  }
}
