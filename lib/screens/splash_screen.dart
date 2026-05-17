import 'dart:async';
import 'package:event_ticket_maker/screens/auth/google_sign_in.dart';
import 'package:event_ticket_maker/screens/booking_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _bg = Color(0xFF050505);
  static const _accent = Color(0xFFE8FF47);
  static const _accent2 = Color(0xFFFF3CAC);
  static const _white = Color(0xFFF5F5F0);
  static const _muted = Color(0xFF888888);
  static const _card = Color(0xFF0F0F0F);
  static const _border = Color(0xFF1A1A1A);
  static const _surface = Color(0xFF141414);

  Map<String, dynamic> _settings = {};
  bool _isLoading = true;
  Timer? _countdownTimer;
  Duration _timeLeft = Duration.zero;
  final ScrollController _scrollController = ScrollController();
  bool _navScrolled = false;

  final _heroKey = GlobalKey();
  final _lineupKey = GlobalKey();
  final _ticketsKey = GlobalKey();
  final _venueKey = GlobalKey();
  final _faqKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _scrollController.addListener(() {
      final scrolled = _scrollController.offset > 60;
      if (scrolled != _navScrolled) setState(() => _navScrolled = scrolled);
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final doc = await FirebaseFirestore.instance
        .collection('settings')
        .doc('site')
        .get();
    setState(() {
      _settings = doc.data() ?? {};
      _isLoading = false;
    });
    _startCountdown();
  }

  void _startCountdown() {
    final ts = _settings['eventDate'];
    if (ts == null) return;
    final eventDate = (ts as Timestamp).toDate();
    _updateCountdown(eventDate);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown(eventDate);
    });
  }

  void _updateCountdown(DateTime target) {
    final diff = target.difference(DateTime.now());
    if (mounted)
      setState(() => _timeLeft = diff.isNegative ? Duration.zero : diff);
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  String _formatDate(dynamic ts) {
    if (ts == null) return '';
    final d = (ts as Timestamp).toDate();
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
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  // ── Reusable Widgets ────────────────────────────────────────

  Widget _label(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontFamily: 'monospace',
      fontSize: 10,
      color: _accent,
      letterSpacing: 3,
    ),
  );

  Widget _sectionTitle(String text, {double size = 56}) => Text(
    text,
    style: TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w900,
      color: _white,
      height: 1,
      letterSpacing: -1,
    ),
  );

  Widget _divider() => const Divider(color: _border, height: 1, thickness: 1);

  // ── Nav ─────────────────────────────────────────────────────

  Widget _navbar() => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
    decoration: BoxDecoration(
      color: _navScrolled ? _bg.withOpacity(0.95) : Colors.transparent,
      border: Border(
        bottom: BorderSide(color: _navScrolled ? _border : Colors.transparent),
      ),
    ),
    child: Row(
      children: [
        Text(
          'NEON NIGHTS',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: _accent,
            letterSpacing: 4,
          ),
        ),
        const Spacer(),
        ...[
          ('Lineup', _lineupKey),
          ('Tickets', _ticketsKey),
          ('Venue', _venueKey),
          ('FAQ', _faqKey),
        ].map(
          (e) => Padding(
            padding: const EdgeInsets.only(left: 32),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _scrollTo(e.$2),
                child: Text(
                  e.$1.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: _muted,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 32),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _scrollTo(_ticketsKey),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              color: _accent,
              child: const Text(
                'GET TICKETS',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  // ── Announcement ────────────────────────────────────────────

  Widget _announcementBar() {
    final enabled = _settings['announcementEnabled'] == true;
    final text = _settings['announcementText'] ?? '';
    if (!enabled || text.isEmpty) return const SizedBox.shrink();

    final type = _settings['announcementType'] ?? 'info';
    final color = type == 'danger'
        ? const Color(0xFFFF4444)
        : type == 'warning'
        ? Colors.orange
        : Colors.blue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: color.withOpacity(0.15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            type == 'danger'
                ? Icons.error_outline
                : type == 'warning'
                ? Icons.warning_amber_outlined
                : Icons.info_outline,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 12, letterSpacing: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Hero ─────────────────────────────────────────────────────

  Widget _hero() {
    final eventName = _settings['eventName'] ?? 'Neon Nights';
    final subtitle = _settings['eventSubtitle'] ?? '';
    final location = _settings['location'] ?? '';
    final date = _formatDate(_settings['eventDate']);
    final eventTagline = _settings['eventTagline'] ?? '';
    final isLive = _settings['isLive'] == true;
    final showLiveTag = _settings['showLiveTag'] == true;

    return Container(
      key: _heroKey,
      height: MediaQuery.of(context).size.height,
      width: double.infinity,
      color: _bg,
      child: Stack(
        children: [
          // Grid background
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          // Glow
          Positioned(
            right: -100,
            top: 100,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_accent.withOpacity(0.06), Colors.transparent],
                ),
              ),
            ),
          ),
          // Content
          Positioned(
            left: 48,
            right: 48,
            // bottom: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 200),
                if (subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _label(subtitle),
                  ),
                Text(
                  eventName.toUpperCase(),
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.1,
                    fontWeight: FontWeight.w900,
                    color: _white,
                    height: 0.9,
                    letterSpacing: -2,
                  ),
                ),
                if (eventTagline.isNotEmpty)
                  Text(
                    eventTagline.toUpperCase(),
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.1,
                      fontWeight: FontWeight.w900,
                      color: _accent2,
                      height: 0.9,
                      letterSpacing: -2,
                    ),
                  ),
                const SizedBox(height: 40),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Details
                    Row(
                      children: [
                        _heroDetail('Date', date),
                        const SizedBox(width: 48),
                        _heroDetail('Doors', '7:00 PM'),
                        const SizedBox(width: 48),
                        _heroDetail('Venue', location),
                        const SizedBox(width: 48),
                        _heroDetail(
                          'Capacity',
                          '${_settings['totalBookingsAllowed'] ?? 500} Only',
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Actions
                    Row(
                      children: [
                        if (isLive && showLiveTag)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _accent2.withOpacity(0.1),
                              border: Border.all(
                                color: _accent2.withOpacity(0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                _PulsingDot(color: _accent2),
                                const SizedBox(width: 8),
                                const Text(
                                  'LIVE',
                                  style: TextStyle(
                                    color: _accent2,
                                    fontSize: 11,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (isLive && showLiveTag) const SizedBox(width: 12),
                        if (_settings['bookingEnabled'] == true) ...[
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => _scrollTo(_ticketsKey),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 16,
                                ),
                                color: _accent,
                                child: const Text(
                                  'BOOK NOW',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => _scrollTo(_lineupKey),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: _border),
                              ),
                              child: const Text(
                                'LINEUP',
                                style: TextStyle(
                                  color: _white,
                                  fontSize: 13,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroDetail(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label.toUpperCase(),
        style: const TextStyle(fontSize: 10, color: _muted, letterSpacing: 2),
      ),
      const SizedBox(height: 6),
      Text(
        value,
        style: const TextStyle(
          fontSize: 15,
          color: _white,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );

  // ── Countdown ───────────────────────────────────────────────

  Widget _countdown() {
    if (_settings['showCountdown'] != true) return const SizedBox.shrink();
    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours % 24;
    final mins = _timeLeft.inMinutes % 60;
    final secs = _timeLeft.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: _border),
          bottom: BorderSide(color: _border),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'TIME UNTIL DOORS OPEN',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: _muted,
              letterSpacing: 3,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              _countdownUnit(_pad(days), 'Days'),
              _countdownUnit(_pad(hours), 'Hours'),
              _countdownUnit(_pad(mins), 'Minutes'),
              _countdownUnit(_pad(secs), 'Seconds', last: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _countdownUnit(String value, String label, {bool last = false}) =>
      Container(
        padding: EdgeInsets.only(left: 32, right: last ? 0 : 32),
        decoration: BoxDecoration(
          border: Border(
            right: last ? BorderSide.none : const BorderSide(color: _border),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w900,
                color: _accent,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                color: _muted,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      );

  // ── Lineup + About ──────────────────────────────────────────

  Widget _lineupSection() => Container(
    key: _lineupKey,
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: _border)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // About
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(80),
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: _border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('About the Event'),
                const SizedBox(height: 24),
                _sectionTitle('One Night.\nOne Stage.\nFull Send.'),
                const SizedBox(height: 24),
                Text(
                  _settings['eventSubtitle'] ??
                      "Chennai's finest underground selectors for an all-night journey through techno, house, and everything in between.",
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 15,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Limited to ${_settings['totalBookingsAllowed'] ?? 500} people. No re-entry. Ages 18+.',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 15,
                    height: 1.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  // ── Tickets ─────────────────────────────────────────────────

  Widget _ticketsSection() {
    final bookingEnabled = _settings['bookingEnabled'] == true;
    final vipEnabled = _settings['vipEnabled'] == true;
    final price = _settings['ticketPrice']?.toString() ?? '799';
    final vipPrice = _settings['vipPrice']?.toString() ?? '1999';
    final total = _settings['totalBookingsAllowed']?.toString() ?? '500';

    return Container(
      key: _ticketsKey,
      padding: const EdgeInsets.all(80),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Secure Your Spot'),
                  const SizedBox(height: 12),
                  _sectionTitle('Tickets'),
                ],
              ),
              const Spacer(),
              Text(
                'Limited to $total. Once sold out, no door sales.',
                style: const TextStyle(color: _muted, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 48),
          if (!bookingEnabled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4444).withOpacity(0.1),
                border: Border.all(
                  color: const Color(0xFFFF4444).withOpacity(0.3),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, color: Color(0xFFFF4444), size: 16),
                  SizedBox(width: 10),
                  Text(
                    'Bookings are currently closed.',
                    style: TextStyle(color: Color(0xFFFF4444), fontSize: 14),
                  ),
                ],
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ticketCard(
                    settings: _settings,
                    type: 'General Admission',
                    price: '₹$price',
                    perks: const [
                      'Full event access',
                      'Standard queue entry',
                      'QR ticket on email',
                      'Non-transferable',
                    ],
                    featured: false,
                  ),
                ),
                const SizedBox(width: 1),
                if (vipEnabled)
                  Expanded(
                    child: _ticketCard(
                      settings: _settings,
                      type: 'VIP Access',
                      price: '₹$vipPrice',
                      perks: const [
                        'Priority fast-track entry',
                        'Dedicated VIP area',
                        'Complimentary welcome drink',
                        'Exclusive merch bag',
                        'QR ticket on email',
                      ],
                      featured: true,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _ticketCard({
    required String type,
    required String price,
    required List<String> perks,
    required bool featured,
    required Map<String, dynamic> settings,
  }) => Container(
    padding: const EdgeInsets.all(40),
    color: featured ? const Color(0xFF0D1A00) : _card,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (featured)
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              color: _accent,
              child: const Text(
                'MOST POPULAR',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        if (featured) const SizedBox(height: 12),
        Text(
          type.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: _muted,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          price,
          style: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.w900,
            color: _white,
            height: 1,
          ),
        ),
        const SizedBox(height: 24),
        ...perks.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(width: 16, height: 1, color: _accent),
                const SizedBox(width: 10),
                Text(
                  p,
                  style: TextStyle(
                    fontSize: 13,
                    color: featured ? _white : _muted,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () async {
              final user = FirebaseAuth.instance.currentUser;

              if (user == null) {
                // Not signed in — bounce to login
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GoogleSignInScreen(
                      settings: _settings,
                      onSuccess: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingPage(settings: _settings),
                          ),
                        );
                      },
                    ),
                  ),
                );
                return;
              }

              // Check whitelist
              final doc = await FirebaseFirestore.instance
                  .collection('whitelisted_users')
                  .doc(user.uid)
                  .get();

              if (!doc.exists) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Access denied. You are not authorized.'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                return;
              }

              // Authorized — proceed
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingPage(settings: _settings),
                  ),
                );
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: featured ? _accent : Colors.transparent,
                border: Border.all(color: featured ? _accent : _border),
              ),
              alignment: Alignment.center,
              child: Text(
                'BUY $type — $price',
                style: TextStyle(
                  color: featured ? Colors.black : _white,
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  // ── Venue ───────────────────────────────────────────────────
  Widget _venueSection() {
    final location = _settings['location'] ?? '';
    final metro = _settings['metro'] ?? '';
    final parking = _settings['parking'] ?? '';
    final timings = _settings['timings'] ?? '';

    final venueDetails = [
      if (location.isNotEmpty) ('📍', 'Address', location),
      if (metro.isNotEmpty) ('🚇', 'Metro', metro),
      if (parking.isNotEmpty) ('🅿️', 'Parking', parking),
      if (timings.isNotEmpty) ('🕖', 'Timings', timings),
    ];

    return Container(
      key: _venueKey,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(80),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: _border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Getting There'),
                  const SizedBox(height: 24),
                  _sectionTitle('Venue'),
                  const SizedBox(height: 32),
                  if (venueDetails.isEmpty)
                    const Text(
                      'Venue details coming soon.',
                      style: TextStyle(color: _muted, fontSize: 14),
                    )
                  else
                    ...venueDetails.map(
                      (v) => Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                border: Border.all(color: _border),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                v.$1,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    v.$2.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: _muted,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    v.$3,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: _white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Map side
          Expanded(
            child: Container(
              height: 500,
              color: const Color(0xFF0A0A0A),
              child: CustomPaint(
                painter: _MapPainter(),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 1, height: 32, color: _accent),
                      Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: _accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        color: _card,
                        child: Text(
                          location.isNotEmpty
                              ? location.toUpperCase()
                              : 'VENUE TBA',
                          style: const TextStyle(
                            fontSize: 11,
                            color: _white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  // ── FAQ ─────────────────────────────────────────────────────

  Widget _faqSection() => Container(
    key: _faqKey,
    padding: const EdgeInsets.all(80),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: _border)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Got Questions?'),
        const SizedBox(height: 24),
        _sectionTitle('FAQ'),
        const SizedBox(height: 48),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 1,
          crossAxisSpacing: 1,
          childAspectRatio: 3,
          children: const [
            _FaqItem(
              q: 'What ID do I need?',
              a: 'Any government-issued photo ID (Aadhaar, Passport, Driving License). Age 18+ strictly enforced.',
            ),
            _FaqItem(
              q: 'Is re-entry allowed?',
              a: 'No re-entry once you exit the venue. Please plan accordingly.',
            ),
            _FaqItem(
              q: 'Can I transfer my ticket?',
              a: 'Tickets are non-transferable and tied to the buyer\'s name. QR code works only once.',
            ),
            _FaqItem(
              q: 'What\'s the refund policy?',
              a: 'No refunds after purchase. In case of event cancellation, full refunds will be issued.',
            ),
            _FaqItem(
              q: 'Is there a dress code?',
              a: 'No strict dress code. Rave wear welcome. Management reserves right of admission.',
            ),
            _FaqItem(
              q: 'Can I bring a camera?',
              a: 'Phone cameras fine. Professional DSLR/video equipment requires press credentials.',
            ),
          ],
        ),
      ],
    ),
  );

  // ── Footer ──────────────────────────────────────────────────

  Widget _footer() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
    child: Row(
      children: [
        Text(
          'NEON NIGHTS',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: _muted,
            letterSpacing: 4,
          ),
        ),
        const Spacer(),
        const Text(
          '© 2025 Neon Nights. All rights reserved.',
          style: TextStyle(color: _muted, fontSize: 12),
        ),
        const Spacer(),
        if (_settings['showSocialLinks'] == true)
          Row(
            children: ['IG', 'YT', 'TW']
                .map(
                  (s) => Container(
                    margin: const EdgeInsets.only(left: 12),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      border: Border.all(color: _border),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      s,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    ),
  );

  // ── Maintenance ─────────────────────────────────────────────

  Widget _maintenanceScreen() => Scaffold(
    backgroundColor: _bg,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.construction_outlined, color: _accent, size: 48),
          const SizedBox(height: 24),
          const Text(
            'UNDER MAINTENANCE',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: _white,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'We\'ll be back shortly.',
            style: TextStyle(color: _muted, fontSize: 15),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _accent)),
      );
    }

    if (_settings['maintenanceMode'] == true) {
      return _maintenanceScreen();
    }

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                _announcementBar(),
                // Nav spacer
                const SizedBox(height: 60),
                _hero(),
                _countdown(),
                _lineupSection(),
                _ticketsSection(),
                _venueSection(),
                _faqSection(),
                _footer(),
              ],
            ),
          ),
          // Sticky Nav on top
          Positioned(
            top:
                _settings['announcementEnabled'] == true &&
                    (_settings['announcementText'] ?? '').isNotEmpty
                ? 40
                : 0,
            left: 0,
            right: 0,
            child: _navbar(),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────

class _FaqItem extends StatelessWidget {
  final String q;
  final String a;
  const _FaqItem({required this.q, required this.a});

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFF050505),
    padding: const EdgeInsets.all(32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          q,
          style: const TextStyle(
            color: Color(0xFFF5F5F0),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          a,
          style: const TextStyle(
            color: Color(0xFF888888),
            fontSize: 13,
            height: 1.7,
          ),
        ),
      ],
    ),
  );
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _a = Tween(begin: 0.3, end: 1.0).animate(_c);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _a,
    child: Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    ),
  );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 0.5;
    const step = 80.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE8FF47).withOpacity(0.05)
      ..strokeWidth = 0.5;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
