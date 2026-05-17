import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_ticket_maker/services/google_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

class GoogleSignInScreen extends StatefulWidget {
  final Map<String, dynamic> settings;
  final VoidCallback? onSuccess;

  const GoogleSignInScreen({super.key, required this.settings, this.onSuccess});

  @override
  State<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen> {
  // ── Getters from settings ──────────────────────────────
  String _getString(String key, [String fallback = '']) {
    final val = widget.settings[key];
    if (val == null) return fallback;
    if (val is String) return val;
    if (val is Timestamp) {
      return DateFormat('dd MMM yyyy').format(val.toDate());
    }
    return val.toString();
  }

  // Then replace all your getters with this:
  String get _eventName => _getString('eventName');
  String get _subtitle => _getString('eventSubtitle');
  String get _location => _getString('location');
  String get _date => _getString('eventDate'); // safe even if it's a Timestamp

  bool _isLoading = false;
  String? _error;

  final _googleSignIn = GoogleSignIn.instance;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // _initGoogleSignIn();
  }

  Future<void> _signIn() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await GoogleAuthService.instance.signInWithGoogle();
      if (mounted) widget.onSuccess!.call();
    } catch (e) {
      if (mounted) setState(() => _error = 'Sign in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: isMobile ? _buildMobile() : _buildDesktop(),
    );
  }

  // ── Mobile layout ──────────────────────────────────────────────────────────
  Widget _buildMobile() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            _buildEventBanner(compact: true),
            const SizedBox(height: 40),
            _buildSignInCard(compact: true),
            const SizedBox(height: 32),
            _buildFooter(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Desktop layout ─────────────────────────────────────────────────────────
  Widget _buildDesktop() {
    return Row(
      children: [
        // Left panel — event info
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0D0D0D),
              border: Border(right: BorderSide(color: Color(0xFF1E1E1E))),
            ),
            child: Center(child: _buildEventBanner(compact: false)),
          ),
        ),
        // Right panel — sign in
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSignInCard(compact: false),
                  const SizedBox(height: 32),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Event banner ───────────────────────────────────────────────────────────
  Widget _buildEventBanner({required bool compact}) {
    return Padding(
      padding: EdgeInsets.all(compact ? 0 : 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: compact
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          // Event badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE8FF47).withOpacity(0.1),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: const Color(0xFFE8FF47).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8FF47),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                const Text(
                  'Live Event',
                  style: TextStyle(
                    color: Color(0xFFE8FF47),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Event name
          Text(
            _eventName,
            textAlign: compact ? TextAlign.center : TextAlign.left,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 32 : 48,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle (only if present)
          if (_subtitle.isNotEmpty) ...[
            Text(
              _subtitle,
              textAlign: compact ? TextAlign.center : TextAlign.left,
              style: const TextStyle(
                color: Color(0xFF888888),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Chips — only show if data exists
          Wrap(
            alignment: compact ? WrapAlignment.center : WrapAlignment.start,
            spacing: 10,
            runSpacing: 8,
            children: [
              if (_date.isNotEmpty)
                _infoChip(Icons.calendar_today_rounded, _date),
              if (_location.isNotEmpty)
                _infoChip(Icons.location_on_rounded, _location),
              _infoChip(Icons.confirmation_number_rounded, 'Limited Seats'),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 40),
            // Decorative divider
            Container(height: 1, width: 60, color: const Color(0xFF2A2A2A)),
            const SizedBox(height: 28),
            const Text(
              'Sign in to book your seat\nand join thousands of fans.',
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 15,
                height: 1.7,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF888888), size: 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF888888),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Sign in card ───────────────────────────────────────────────────────────
  Widget _buildSignInCard({required bool compact}) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      padding: EdgeInsets.all(compact ? 24 : 32),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Sign in to continue',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Use your Google account to book tickets.',
            style: TextStyle(
              color: Color(0xFF888888),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

          // Google button
          GestureDetector(
            onTap: _isLoading ? null : _signIn,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _isLoading
                    ? Colors.white.withOpacity(0.75)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: _isLoading
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: _isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black45,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                          width: 20,
                          height: 20,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.g_mobiledata_rounded,
                            size: 22,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Continue with Google',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          // Error
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade800.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.redAccent,
                    size: 15,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(color: Color(0xFF2A2A2A)),
          const SizedBox(height: 16),

          // What you get after sign in
          _benefitRow(Icons.bolt_rounded, 'Instant booking confirmation'),
          const SizedBox(height: 10),
          _benefitRow(Icons.qr_code_rounded, 'QR ticket sent to your account'),
          const SizedBox(height: 10),
          _benefitRow(Icons.security_rounded, 'Secure & verified entry'),
        ],
      ),
    );
  }

  Widget _benefitRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFE8FF47).withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFE8FF47), size: 14),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
        ),
      ],
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return const Text(
      'By signing in you agree to our terms.\nYour data is used only for ticket booking.',
      textAlign: TextAlign.center,
      style: TextStyle(color: Color(0xFF444444), fontSize: 11, height: 1.6),
    );
  }
}
