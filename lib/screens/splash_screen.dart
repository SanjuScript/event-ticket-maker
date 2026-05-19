import 'dart:async';
import 'package:event_ticket_maker/screens/auth/google_sign_in.dart';
import 'package:event_ticket_maker/screens/booking_page.dart';
import 'package:event_ticket_maker/theme/site_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _bg = Color(0xFF050505);
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

  Color get _accentColor => context.siteAccent;

  List<(String, GlobalKey)> get _navItems => [
    ('Lineup', _lineupKey),
    ('Tickets', _ticketsKey),
    ('Venue', _venueKey),
    ('FAQ', _faqKey),
  ];

  bool _isMobileLayout(BuildContext context) =>
      MediaQuery.of(context).size.width < 768;

  bool _isTabletLayout(BuildContext context) =>
      MediaQuery.of(context).size.width < 1100;

  double _responsiveInset(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width < 768) return mobile;
    if (width < 1100) return tablet;
    return desktop;
  }

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

  Map<String, dynamic> get _promoBanner =>
      Map<String, dynamic>.from((_settings['promoBanner'] as Map?) ?? const {});

  Uri? _promoUri(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) return null;

    final withScheme =
        trimmed.startsWith('http://') || trimmed.startsWith('https://')
        ? trimmed
        : 'https://$trimmed';

    return Uri.tryParse(withScheme);
  }

  Future<void> _openPromoLink(String rawValue) async {
    final uri = _promoUri(rawValue);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  Future<void> _openMobileNavMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        void navigateTo(GlobalKey key) {
          Navigator.of(sheetContext).pop();
          Future.delayed(const Duration(milliseconds: 180), () {
            if (!mounted) return;
            _scrollTo(key);
          });
        }

        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            decoration: const BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: _border)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _label('Navigate'),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded, color: _white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._navItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => navigateTo(item.$2),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: _card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _border),
                        ),
                        child: Row(
                          children: [
                            Text(
                              item.$1.toUpperCase(),
                              style: const TextStyle(
                                color: _white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_outward_rounded,
                              color: _accentColor,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (_settings['bookingEnabled'] == true) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => navigateTo(_ticketsKey),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _accentColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'GET TICKETS',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Reusable Widgets ────────────────────────────────────────

  Widget _label(String text) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontFamily: 'monospace',
      fontSize: 10,
      color: _accentColor,
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

  // ── Nav ─────────────────────────────────────────────────────

  Widget _navbar() {
    final isMobile = _isMobileLayout(context);
    final horizontalPadding = _responsiveInset(
      context,
      mobile: 20,
      tablet: 32,
      desktop: 48,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: isMobile ? 14 : 18,
      ),
      decoration: BoxDecoration(
        color: _navScrolled ? _bg.withOpacity(0.95) : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: _navScrolled ? _border : Colors.transparent,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'NEON NIGHTS',
            style: TextStyle(
              fontSize: isMobile ? 14 : 18,
              fontWeight: FontWeight.w900,
              color: _accentColor,
              letterSpacing: isMobile ? 3 : 4,
            ),
          ),
          const Spacer(),
          if (isMobile)
            GestureDetector(
              onTap: _openMobileNavMenu,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.menu_rounded, color: _accentColor, size: 22),
              ),
            )
          else ...[
            ..._navItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(left: 32),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _scrollTo(item.$2),
                    child: Text(
                      item.$1.toUpperCase(),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  color: _accentColor,
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
        ],
      ),
    );
  }

  // ── Announcement ────────────────────────────────────────────

  Widget _announcementBar() {
    final enabled = _settings['announcementEnabled'] == true;
    final text = _settings['announcementText'] ?? '';
    if (!enabled || text.isEmpty) return const SizedBox.shrink();

    final isMobile = _isMobileLayout(context);
    final type = _settings['announcementType'] ?? 'info';
    final color = type == 'danger'
        ? const Color(0xFFFF4444)
        : type == 'warning'
        ? Colors.orange
        : Colors.blue;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 12,
        vertical: isMobile ? 12 : 10,
      ),
      color: color.withOpacity(0.15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: isMobile ? 11.5 : 12,
                letterSpacing: isMobile ? 1.1 : 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _promoBannerSection() {
    final banner = _promoBanner;
    final enabled = banner['enabled'] == true;
    final title = (banner['title'] ?? '').toString().trim();
    final description = (banner['description'] ?? '').toString().trim();
    final label = (banner['label'] ?? 'Sponsored').toString().trim();
    final sponsor = (banner['sponsor'] ?? '').toString().trim();
    final ctaText = (banner['ctaText'] ?? '').toString().trim();
    final ctaUrl = (banner['ctaUrl'] ?? '').toString().trim();
    final imageUrl = (banner['imageUrl'] ?? '').toString().trim();

    if (!enabled ||
        (title.isEmpty && description.isEmpty && imageUrl.isEmpty)) {
      return const SizedBox.shrink();
    }

    final isMobile = _isMobileLayout(context);
    final wide = MediaQuery.of(context).size.width >= 980;
    final hasLink = _promoUri(ctaUrl) != null;

    return Container(
      padding: EdgeInsets.all(
        _responsiveInset(context, mobile: 20, tablet: 32, desktop: 48),
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 20 : 28),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _border),
          gradient: LinearGradient(
            colors: [_accentColor.withOpacity(0.08), Colors.transparent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 7,
                    child: _promoBannerContent(
                      label: label,
                      sponsor: sponsor,
                      title: title,
                      description: description,
                      ctaText: ctaText,
                      ctaUrl: ctaUrl,
                      hasLink: hasLink,
                    ),
                  ),
                  if (imageUrl.isNotEmpty) ...[
                    const SizedBox(width: 24),
                    Expanded(flex: 5, child: _promoBannerImage(imageUrl)),
                  ],
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _promoBannerContent(
                    label: label,
                    sponsor: sponsor,
                    title: title,
                    description: description,
                    ctaText: ctaText,
                    ctaUrl: ctaUrl,
                    hasLink: hasLink,
                  ),
                  if (imageUrl.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _promoBannerImage(imageUrl),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _promoBannerContent({
    required String label,
    required String sponsor,
    required String title,
    required String description,
    required String ctaText,
    required String ctaUrl,
    required bool hasLink,
  }) {
    final isMobile = _isMobileLayout(context);
    final headline = title.isEmpty ? 'Featured Partner' : title;
    final body = description.isEmpty
        ? 'Use this area to showcase event partners, ticketing partners, or featured promotions.'
        : description;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            if (sponsor.isNotEmpty)
              Text(
                sponsor.toUpperCase(),
                style: const TextStyle(
                  color: _muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          headline,
          style: TextStyle(
            color: _white,
            fontSize: isMobile ? 28 : 34,
            fontWeight: FontWeight.w900,
            height: 1.05,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 620,
          ),
          child: Text(
            body,
            style: const TextStyle(color: _muted, fontSize: 14, height: 1.7),
          ),
        ),
        if (hasLink && ctaText.isNotEmpty) ...[
          const SizedBox(height: 22),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _openPromoLink(ctaUrl),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                color: _accentColor,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ctaText.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.open_in_new_rounded,
                      color: Colors.black,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _promoBannerImage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            decoration: BoxDecoration(
              color: _card,
              border: Border.all(color: _border),
            ),
            child: Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: _accentColor,
                size: 28,
              ),
            ),
          ),
        ),
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
    final bookingEnabled = _settings['bookingEnabled'] == true;
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final isMobile = _isMobileLayout(context);
    final isTablet = _isTabletLayout(context) && !isMobile;
    final horizontalPadding = _responsiveInset(
      context,
      mobile: 20,
      tablet: 32,
      desktop: 48,
    );
    final titleSize = isMobile
        ? width.clamp(320.0, 520.0) * 0.14
        : isTablet
        ? width * 0.11
        : width * 0.1;
    final heroMinHeight = isMobile ? height * 0.92 : height;
    final topSpacing = isMobile
        ? 120.0
        : isTablet
        ? 170.0
        : 200.0;
    final bottomSpacing = isMobile ? 40.0 : 48.0;
    final glowSize = isMobile
        ? 320.0
        : isTablet
        ? 440.0
        : 600.0;

    return Container(
      key: _heroKey,
      width: double.infinity,
      height: isMobile ? null : height,
      constraints: BoxConstraints(minHeight: heroMinHeight),
      color: _bg,
      child: Stack(
        children: [
          // Grid background
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          // Glow
          Positioned(
            right: isMobile ? -120 : -100,
            top: isMobile ? 120 : 100,
            child: Container(
              width: glowSize,
              height: glowSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_accentColor.withOpacity(0.06), Colors.transparent],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              topSpacing,
              horizontalPadding,
              bottomSpacing,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final detailWidth = isMobile
                    ? (constraints.maxWidth - 12) / 2
                    : 180.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: _label(subtitle),
                      ),
                    Text(
                      eventName.toUpperCase(),
                      style: TextStyle(
                        fontSize: titleSize,
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
                          fontSize: titleSize,
                          fontWeight: FontWeight.w900,
                          color: _accent2,
                          height: 0.9,
                          letterSpacing: -2,
                        ),
                      ),
                    SizedBox(height: isMobile ? 28 : 40),
                    if (isMobile) ...[
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: detailWidth,
                            child: _heroDetail('Date', date, boxed: true),
                          ),
                          SizedBox(
                            width: detailWidth,
                            child: _heroDetail('Doors', '7:00 PM', boxed: true),
                          ),
                          SizedBox(
                            width: detailWidth,
                            child: _heroDetail('Venue', location, boxed: true),
                          ),
                          SizedBox(
                            width: detailWidth,
                            child: _heroDetail(
                              'Capacity',
                              '${_settings['totalBookingsAllowed'] ?? 500} Only',
                              boxed: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (isLive && showLiveTag) ...[
                        _liveTag(),
                        const SizedBox(height: 16),
                      ],
                      if (bookingEnabled) ...[
                        _heroActionButton(
                          label: 'BOOK NOW',
                          onTap: () => _scrollTo(_ticketsKey),
                          filled: true,
                          fullWidth: true,
                        ),
                        const SizedBox(height: 12),
                      ],
                      _heroActionButton(
                        label: 'LINEUP',
                        onTap: () => _scrollTo(_lineupKey),
                        fullWidth: true,
                      ),
                    ] else if (isTablet) ...[
                      Wrap(
                        spacing: 20,
                        runSpacing: 18,
                        children: [
                          SizedBox(
                            width: detailWidth,
                            child: _heroDetail('Date', date),
                          ),
                          SizedBox(
                            width: detailWidth,
                            child: _heroDetail('Doors', '7:00 PM'),
                          ),
                          SizedBox(
                            width: detailWidth,
                            child: _heroDetail('Venue', location),
                          ),
                          SizedBox(
                            width: detailWidth,
                            child: _heroDetail(
                              'Capacity',
                              '${_settings['totalBookingsAllowed'] ?? 500} Only',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (isLive && showLiveTag) _liveTag(),
                          if (bookingEnabled)
                            _heroActionButton(
                              label: 'BOOK NOW',
                              onTap: () => _scrollTo(_ticketsKey),
                              filled: true,
                            ),
                          _heroActionButton(
                            label: 'LINEUP',
                            onTap: () => _scrollTo(_lineupKey),
                          ),
                        ],
                      ),
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
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
                          Row(
                            children: [
                              if (isLive && showLiveTag) _liveTag(),
                              if (isLive && showLiveTag)
                                const SizedBox(width: 12),
                              if (bookingEnabled) ...[
                                _heroActionButton(
                                  label: 'BOOK NOW',
                                  onTap: () => _scrollTo(_ticketsKey),
                                  filled: true,
                                ),
                                const SizedBox(width: 12),
                              ],
                              _heroActionButton(
                                label: 'LINEUP',
                                onTap: () => _scrollTo(_lineupKey),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroDetail(String label, String value, {bool boxed = false}) =>
      Container(
        padding: boxed ? const EdgeInsets.all(16) : EdgeInsets.zero,
        decoration: boxed
            ? BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _border),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                color: _muted,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value.isEmpty ? 'TBA' : value,
              style: TextStyle(
                fontSize: boxed ? 14 : 15,
                color: _white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  Widget _liveTag() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: _accent2.withOpacity(0.1),
      border: Border.all(color: _accent2.withOpacity(0.4)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PulsingDot(color: _accent2),
        const SizedBox(width: 8),
        const Text(
          'LIVE',
          style: TextStyle(color: _accent2, fontSize: 11, letterSpacing: 2),
        ),
      ],
    ),
  );

  Widget _heroActionButton({
    required String label,
    required VoidCallback onTap,
    bool filled = false,
    bool fullWidth = false,
  }) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        color: filled ? _accentColor : null,
        decoration: filled
            ? null
            : BoxDecoration(border: Border.all(color: _border)),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: filled ? Colors.black : _white,
            fontSize: 13,
            fontWeight: filled ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 2,
          ),
        ),
      ),
    ),
  );

  // ── Countdown ───────────────────────────────────────────────

  Widget _countdown() {
    if (_settings['showCountdown'] != true) return const SizedBox.shrink();
    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours % 24;
    final mins = _timeLeft.inMinutes % 60;
    final secs = _timeLeft.inSeconds % 60;
    final isMobile = _isMobileLayout(context);
    final isCompact = _isTabletLayout(context);
    final horizontalPadding = _responsiveInset(
      context,
      mobile: 20,
      tablet: 32,
      desktop: 48,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: isMobile ? 28 : 40,
      ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: _border),
          bottom: BorderSide(color: _border),
        ),
      ),
      child: isCompact
          ? LayoutBuilder(
              builder: (context, constraints) {
                final unitWidth = isMobile
                    ? (constraints.maxWidth - 12) / 2
                    : (constraints.maxWidth - 36) / 4;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _countdownUnit(
                          _pad(days),
                          'Days',
                          compact: true,
                          width: unitWidth,
                        ),
                        _countdownUnit(
                          _pad(hours),
                          'Hours',
                          compact: true,
                          width: unitWidth,
                        ),
                        _countdownUnit(
                          _pad(mins),
                          'Minutes',
                          compact: true,
                          width: unitWidth,
                        ),
                        _countdownUnit(
                          _pad(secs),
                          'Seconds',
                          compact: true,
                          width: unitWidth,
                        ),
                      ],
                    ),
                  ],
                );
              },
            )
          : Row(
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

  Widget _countdownUnit(
    String value,
    String label, {
    bool last = false,
    bool compact = false,
    double? width,
  }) {
    final isMobile = _isMobileLayout(context);

    return Container(
      width: width,
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 20)
          : EdgeInsets.only(left: 32, right: last ? 0 : 32),
      decoration: compact
          ? BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
            )
          : BoxDecoration(
              border: Border(
                right: last
                    ? BorderSide.none
                    : const BorderSide(color: _border),
              ),
            ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: compact ? (isMobile ? 42 : 48) : 64,
              fontWeight: FontWeight.w900,
              color: _accentColor,
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
  }

  // ── Lineup + About ──────────────────────────────────────────

  Widget _lineupSection() {
    final isCompact = _isTabletLayout(context);
    final sectionPadding = _responsiveInset(
      context,
      mobile: 24,
      tablet: 48,
      desktop: 80,
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('About the Event'),
        const SizedBox(height: 24),
        _sectionTitle(
          'One Night.\nOne Stage.\nFull Send.',
          size: isCompact ? 40 : 56,
        ),
        const SizedBox(height: 24),
        Text(
          _settings['eventSubtitle'] ??
              "Chennai's finest underground selectors for an all-night journey through techno, house, and everything in between.",
          style: const TextStyle(color: _muted, fontSize: 15, height: 1.8),
        ),
        const SizedBox(height: 16),
        Text(
          'Limited to ${_settings['totalBookingsAllowed'] ?? 500} people. No re-entry. Ages 18+.',
          style: const TextStyle(color: _muted, fontSize: 15, height: 1.8),
        ),
      ],
    );

    return Container(
      key: _lineupKey,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: isCompact
          ? Container(padding: EdgeInsets.all(sectionPadding), child: content)
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(sectionPadding),
                    decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: _border)),
                    ),
                    child: content,
                  ),
                ),
              ],
            ),
    );
  }

  // ── Tickets ─────────────────────────────────────────────────

  Widget _ticketsSection() {
    final bookingEnabled = _settings['bookingEnabled'] == true;
    final vipEnabled = _settings['vipEnabled'] == true;
    final price = _settings['ticketPrice']?.toString() ?? '799';
    final vipPrice = _settings['vipPrice']?.toString() ?? '1999';
    final total = _settings['totalBookingsAllowed']?.toString() ?? '500';
    final isCompact = _isTabletLayout(context);
    final sectionPadding = _responsiveInset(
      context,
      mobile: 24,
      tablet: 48,
      desktop: 80,
    );

    return Container(
      key: _ticketsKey,
      padding: EdgeInsets.all(sectionPadding),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCompact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Secure Your Spot'),
                const SizedBox(height: 12),
                _sectionTitle('Tickets', size: 40),
                const SizedBox(height: 12),
                Text(
                  'Limited to $total. Once sold out, no door sales.',
                  style: const TextStyle(color: _muted, fontSize: 13),
                ),
              ],
            )
          else
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
          SizedBox(height: isCompact ? 32 : 48),
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
              child: const Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  Icon(Icons.lock_outline, color: Color(0xFFFF4444), size: 16),
                  Text(
                    'Bookings are currently closed.',
                    style: TextStyle(color: Color(0xFFFF4444), fontSize: 14),
                  ),
                ],
              ),
            )
          else if (isCompact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ticketCard(
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
                if (vipEnabled) const SizedBox(height: 16),
                if (vipEnabled)
                  _ticketCard(
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
              ],
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
  }) {
    final isMobile = _isMobileLayout(context);
    final isCompact = _isTabletLayout(context);

    return Container(
      padding: EdgeInsets.all(
        isMobile
            ? 24
            : isCompact
            ? 32
            : 40,
      ),
      color: featured ? _accentColor.withOpacity(0.08) : _card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (featured)
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                color: _accentColor,
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
            style: TextStyle(
              fontSize: isMobile
                  ? 56
                  : isCompact
                  ? 64
                  : 72,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 16, height: 1, color: _accentColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p,
                      style: TextStyle(
                        fontSize: 13,
                        color: featured ? _white : _muted,
                      ),
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

                // // Authorized — proceed
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
                  color: featured ? _accentColor : Colors.transparent,
                  border: Border.all(color: featured ? _accentColor : _border),
                ),
                alignment: Alignment.center,
                child: Text(
                  'BUY $type — $price',
                  textAlign: TextAlign.center,
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
  }

  // ── Venue ───────────────────────────────────────────────────
  Widget _venueSection() {
    final location = _settings['location'] ?? '';
    final metro = _settings['metro'] ?? '';
    final parking = _settings['parking'] ?? '';
    final timings = _settings['timings'] ?? '';
    final isCompact = _isTabletLayout(context);
    final isMobile = _isMobileLayout(context);
    final sectionPadding = _responsiveInset(
      context,
      mobile: 24,
      tablet: 48,
      desktop: 80,
    );

    final venueDetails = [
      if (location.isNotEmpty) ('📍', 'Address', location),
      if (metro.isNotEmpty) ('🚇', 'Metro', metro),
      if (parking.isNotEmpty) ('🅿️', 'Parking', parking),
      if (timings.isNotEmpty) ('🕖', 'Timings', timings),
    ];

    final detailsPanel = Container(
      padding: EdgeInsets.all(sectionPadding),
      decoration: isCompact
          ? null
          : const BoxDecoration(
              border: Border(right: BorderSide(color: _border)),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Getting There'),
          const SizedBox(height: 24),
          _sectionTitle('Venue', size: isCompact ? 40 : 56),
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
                      child: Text(v.$1, style: const TextStyle(fontSize: 14)),
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
                            style: const TextStyle(fontSize: 14, color: _white),
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
    );

    final mapPanel = Container(
      height: isMobile
          ? 320
          : isCompact
          ? 380
          : 500,
      color: const Color(0xFF0A0A0A),
      child: CustomPaint(
        painter: _MapPainter(accentColor: _accentColor),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 1, height: 32, color: _accentColor),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: _accentColor,
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
                  location.isNotEmpty ? location.toUpperCase() : 'VENUE TBA',
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
    );

    return Container(
      key: _venueKey,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [detailsPanel, mapPanel],
            )
          : Row(
              children: [
                Expanded(child: detailsPanel),
                Expanded(child: mapPanel),
              ],
            ),
    );
  }
  // ── FAQ ─────────────────────────────────────────────────────

  Widget _faqSection() {
    final isMobile = _isMobileLayout(context);
    final sectionPadding = _responsiveInset(
      context,
      mobile: 24,
      tablet: 48,
      desktop: 80,
    );
    final faqs = const <({String q, String a})>[
      (
        q: 'What ID do I need?',
        a: 'Any government-issued photo ID (Aadhaar, Passport, Driving License). Age 18+ strictly enforced.',
      ),
      (
        q: 'Is re-entry allowed?',
        a: 'No re-entry once you exit the venue. Please plan accordingly.',
      ),
      (
        q: 'Can I transfer my ticket?',
        a: 'Tickets are non-transferable and tied to the buyer\'s name. QR code works only once.',
      ),
      (
        q: 'What\'s the refund policy?',
        a: 'No refunds after purchase. In case of event cancellation, full refunds will be issued.',
      ),
      (
        q: 'Is there a dress code?',
        a: 'No strict dress code. Rave wear welcome. Management reserves right of admission.',
      ),
      (
        q: 'Can I bring a camera?',
        a: 'Phone cameras fine. Professional DSLR/video equipment requires press credentials.',
      ),
    ];

    return Container(
      key: _faqKey,
      padding: EdgeInsets.all(sectionPadding),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Got Questions?'),
          const SizedBox(height: 24),
          _sectionTitle('FAQ', size: isMobile ? 40 : 56),
          const SizedBox(height: 48),
          if (isMobile)
            Column(
              children: faqs
                  .map(
                    (faq) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _FaqItem(q: faq.q, a: faq.a),
                    ),
                  )
                  .toList(),
            )
          else
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 1,
              crossAxisSpacing: 1,
              childAspectRatio: 3,
              children: faqs
                  .map((faq) => _FaqItem(q: faq.q, a: faq.a))
                  .toList(),
            ),
        ],
      ),
    );
  }

  // ── Footer ──────────────────────────────────────────────────

  Widget _footer() {
    final isMobile = _isMobileLayout(context);
    final horizontalPadding = _responsiveInset(
      context,
      mobile: 20,
      tablet: 32,
      desktop: 48,
    );
    final socialLinks = ['IG', 'YT', 'TW']
        .map(
          (s) => Container(
            margin: EdgeInsets.only(left: isMobile ? 0 : 12),
            width: 36,
            height: 36,
            decoration: BoxDecoration(border: Border.all(color: _border)),
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
        .toList();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: isMobile ? 28 : 32,
      ),
      child: isMobile
          ? Column(
              children: [
                Text(
                  'NEON NIGHTS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _muted,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '© 2025 Neon Nights. All rights reserved.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
                if (_settings['showSocialLinks'] == true) ...[
                  const SizedBox(height: 18),
                  Wrap(spacing: 12, runSpacing: 12, children: socialLinks),
                ],
              ],
            )
          : Row(
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
                  Row(children: socialLinks),
              ],
            ),
    );
  }

  // ── Maintenance ─────────────────────────────────────────────

  Widget _maintenanceScreen() => Scaffold(
    backgroundColor: _bg,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.construction_outlined, color: _accentColor, size: 48),
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
    final isMobile = _isMobileLayout(context);
    final hasAnnouncement =
        _settings['announcementEnabled'] == true &&
        (_settings['announcementText'] ?? '').isNotEmpty;
    final navSpacerHeight = isMobile ? 72.0 : 60.0;
    final navTopOffset = hasAnnouncement ? (isMobile ? 56.0 : 40.0) : 0.0;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _accentColor)),
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
                SizedBox(height: navSpacerHeight),
                _hero(),
                _promoBannerSection(),
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
          Positioned(top: navTopOffset, left: 0, right: 0, child: _navbar()),
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
  final Color accentColor;

  _MapPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor.withOpacity(0.05)
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
  bool shouldRepaint(_MapPainter oldDelegate) =>
      oldDelegate.accentColor != accentColor;
}
