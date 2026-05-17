import 'dart:convert';
import 'dart:developer';
import 'package:event_ticket_maker/helper/string_helper.dart';
import 'package:event_ticket_maker/models/payment_model.dart';
import 'package:event_ticket_maker/provider/device_info_provider.dart';
import 'package:event_ticket_maker/provider/verification_state.dart';
import 'package:event_ticket_maker/screens/success_screen.dart';
import 'package:event_ticket_maker/services/google_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_razorpay_web/models/rpay_cancel_response.dart';
import 'package:flutter_razorpay_web/models/rpay_failed_response.dart';
import 'package:flutter_razorpay_web/models/rpay_success_response.dart';
import 'package:flutter_razorpay_web/razorpay_web/razorpay_web.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

// ── Constants ─────────────────────────────────────────────────
const _bg = Color(0xFF050505);
const _accent = Color(0xFFE8FF47);
const _accent2 = Color(0xFFFF3CAC);
const _white = Color(0xFFF5F5F0);
const _muted = Color(0xFF888888);
const _card = Color(0xFF0F0F0F);
const _border = Color(0xFF1A1A1A);
const _error = Color(0xFFFF4444);

// ── Config — update these ─────────────────────────────────────
const _razorpayKeyId = 'rzp_test_SOoQi14i47lKnS';
const _backendBase = 'http://localhost:3000';
const _eventName = 'Neon Nights';

enum TicketType { general, vip }

// ─────────────────────────────────────────────────────────────
class BookingPage extends StatefulWidget {
  final Map<String, dynamic> settings;
  const BookingPage({super.key, required this.settings});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  // 0 = select  1 = details  2 = confirm  3 = success
  int _step = 0;

  TicketType _selectedType = TicketType.general;
  int _quantity = 1;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _errorMessage;
  String? _ticketId;

  // Razorpay
  late RazorpayWeb razorpayWeb;

  @override
  void initState() {
    super.initState();
    razorpayWeb = RazorpayWeb(
      onSuccess: _handlePaymentSuccess,
      onCancel: _handleOnCancel,
      onFailed: _handlePaymentError,
    );
    final maxPerUser = (widget.settings['maxPerUser'] as num?)?.toInt() ?? 6;
    _quantity = _quantity.clamp(1, maxPerUser);
    _prefillUserDetails();
  }

  Future<void> _prefillUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Try Auth first (instant, no network)
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      _nameController.text = user.displayName!;
    }
    if (user.email != null && user.email!.isNotEmpty) {
      _emailController.text = user.email!;
    }

    // Then try Firestore for richer data (phone etc.)
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) return;
      final data = doc.data()!;

      // Only fill if not already set by Auth
      if (_nameController.text.isEmpty) {
        _nameController.text = data['name'] as String? ?? '';
      }
      if (_emailController.text.isEmpty) {
        _emailController.text = data['email'] as String? ?? '';
      }

      // Phone — Auth doesn't give this for Google login, Firestore might
      final phone = data['phone'] as String? ?? '';
      if (phone.isNotEmpty) {
        _phoneController.text = phone;
      }
    } catch (e) {
      log('[BookingPage] prefill from Firestore failed: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ── Computed ─────────────────────────────────────────────────
  int get _unitPrice {
    final s = widget.settings;
    return _selectedType == TicketType.vip
        ? (s['vipPrice'] as num?)?.toInt() ?? 1999
        : (s['ticketPrice'] as num?)?.toInt() ?? 799;
  }

  int get _total => _unitPrice * _quantity;
  int get _totalPaise => _total * 100;

  String get _ticketLabel =>
      _selectedType == TicketType.vip ? 'VIP Access' : 'General Admission';
  bool get _vipEnabled => widget.settings['vipEnabled'] == true;

  // ── Razorpay callbacks ────────────────────────────────────────
  void _handlePaymentSuccess(RpaySuccessResponse response) {
    log("[RAZORPAY] Success: ${response.toJson()}");

    final resp = response.toMap();
    _verifyAndSaveTicket(
      response: RazorpayPaymentModel.fromJson(resp),
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );
  }

  void _handlePaymentError(RpayFailedResponse response) {
    log("[RAZORPAY] Failed: ${response.toJson()}");

    StringHelper.showError('Payment failed', context);

    final pp = Provider.of<PaymentProvider>(context, listen: false);
    pp.setLoading(false);
  }

  void _handleOnCancel(RpayCancelResponse response) {
    log("[RAZORPAY] Cancelled: ${response.toJson()}");

    final pp = Provider.of<PaymentProvider>(context, listen: false);
    pp.setLoading(false);
  }

  // ── Step 1: Create Razorpay order ────────────────────────────
  Future<void> _startPayment() async {
    final pp = Provider.of<PaymentProvider>(context, listen: false);
    pp.setLoading(true);

    try {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      log("[PAYMENT] Start");
      log("[PAYMENT] Name: $name");
      log("[PAYMENT] Phone: $phone");
      log("[PAYMENT] Amount (paise): $_totalPaise");
      log("[PAYMENT] Endpoint: $_backendBase/create-order");

      final response = await http.post(
        Uri.parse('$_backendBase/create-order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': _totalPaise,
          'receipt': 'receipt_${DateTime.now().millisecondsSinceEpoch}',
        }),
      );

      log("[PAYMENT] Create-order status: ${response.statusCode}");
      log("[PAYMENT] Create-order response: ${response.body}");

      if (response.statusCode != 200) {
        throw Exception("Invalid status code: ${response.statusCode}");
      }

      final data = jsonDecode(response.body);

      if (data['status'] != 'success') {
        log("[PAYMENT] Order creation failed: $data");
        if (mounted) {
          StringHelper.showError('Order creation failed.', context);
        }
        pp.setLoading(false);
        return;
      }

      final orderId = data['body']['id'];
      log("[PAYMENT] Order created: $orderId");

      _makePayment(
        orderId: orderId,
        keyId: _razorpayKeyId,
        amount: _totalPaise,
        name: name,
        phone: phone,
      );
    } catch (e, stack) {
      log("[PAYMENT] Exception: $e");
      log("[PAYMENT] Stack: $stack");

      if (mounted) {
        StringHelper.showError('Create order failed.', context);
      }

      pp.setLoading(false);
    }
  }

  // ── Step 2: Open Razorpay modal ───────────────────────────────
  void _makePayment({
    required String orderId,
    required String keyId,
    required int amount,
    required String name,
    required String phone,
  }) {
    log("[RAZORPAY] Opening checkout");
    log("[RAZORPAY] orderId: $orderId");
    log("[RAZORPAY] key: $keyId");
    log("[RAZORPAY] amount: $amount");

    razorpayWeb.open({
      'key': keyId,
      'amount': '$amount',
      'currency': 'INR',
      'name': _eventName,
      'description': '$_ticketLabel × $_quantity',
      'send_sms_hash': true,
      'readonly': {'contact': true, 'email': true},
      'order_id': orderId,
      'method': {
        'upi': true,
        'card': true,
        'netbanking': true,
        'wallet': false,
        'emi': false,
        'paylater': false,
      },
      'prefill': {'name': name, 'contact': phone},
      'theme': {'color': '#E8FF47'},
    });
  }

  // ── Step 3: Verify + save to Firestore ───────────────────────
  Future<void> _verifyAndSaveTicket({
    required RazorpayPaymentModel response,
    required String name,
    required String phone,
  }) async {
    final pp = Provider.of<PaymentProvider>(context, listen: false);
    final devP = Provider.of<DeviceInfoProvider>(context, listen: false);
    pp.setLoading(true);

    try {
      log("[VERIFY] Start verification");
      final res = await http.post(
        Uri.parse('$_backendBase/verify-payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'payment_info': response.toJson(),
          'name': name,
          'phone': phone,
          'email': _emailController.text.trim(),
          'ticket_type': _selectedType.name,
          'quantity': _quantity,
          'total_amount': _total,
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
      log("[VERIFY] Status: ${res.statusCode}");
      log("[VERIFY] Response: ${res.body}");

      if (result['status'] == 'success') {
        pp.setPayment(true);
        final ticketId = result['ticket_id'] as String;
        final user = FirebaseAuth.instance.currentUser;

        // ── Save full booking to Firestore ──────────────────────
        await FirebaseFirestore.instance
            .collection('tickets')
            .doc(ticketId)
            .set({
              // Identifiers
              'ticketId': ticketId,
              'bookingId': ticketId,
              'userId': user!.uid,
              // Attendee
              'name': name,
              'email': _emailController.text.trim(),
              'phone': phone,

              // Ticket details
              'ticketType': _selectedType.name,
              'ticketLabel': _ticketLabel,
              'quantity': _quantity,
              'unitPrice': _unitPrice,
              'totalAmount': _total,
              'used': false,

              // Payment info (full Razorpay response)
              'paymentId': response.paymentId,
              'orderId': response.orderId,
              'signature': response.signature,
              'paymentStatus': 'paid',

              // Device info (matching your existing verifyAndSaveTicket)
              'deviceInfo': {
                'deviceModel': devP.deviceModel,
                'os': devP.os,
                'userAgent': devP.userAgent,
                'language': devP.language,
              },
              'ipAddress': devP.ipAddress,

              // Timestamps
              'createdAt': FieldValue.serverTimestamp(),
              'paidAt': FieldValue.serverTimestamp(),
            });
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('booked_tickets')
              .doc(ticketId)
              .set({
                // Reference
                'ticketId': ticketId,
                'uid': user.uid,

                // Attendee
                'name': name,
                'email': _emailController.text.trim(),
                'phone': phone,

                'ticketType': _selectedType.name,
                'ticketLabel': _ticketLabel,
                'quantity': _quantity,
                'unitPrice': _unitPrice,
                'totalAmount': _total,
                'used': false,

                'paymentId': response.paymentId,
                'orderId': response.orderId,
                'paymentStatus': 'paid',

                'eventName': widget.settings['eventName'] ?? '',
                'eventDate': widget.settings['eventDate'],

                // Timestamps
                'bookedAt': FieldValue.serverTimestamp(),
              });
        }
        setState(() => _ticketId = ticketId);
        pp.setLoading(false);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SuccessScreen(
                ticketId: _ticketId! ?? '',
                ticketType: _selectedType == TicketType.vip
                    ? 'VIP Access'
                    : 'General Admission',
                quantity: _quantity,
                totalPrice: _total,
                settings: widget.settings,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          StringHelper.showError(
            result['message'] ?? 'Verification failed.',
            context,
          );
        }
        pp.setLoading(false);
      }
    } catch (e) {
      log('BookingPage verifyAndSaveTicket error: $e');
      if (mounted) {
        StringHelper.showError(
          'Could not verify payment. Contact support.',
          context,
        );
      }
      pp.setLoading(false);
    }
  }

  // ── UI helpers ────────────────────────────────────────────────
  Widget _monoLabel(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontFamily: 'monospace',
      fontSize: 10,
      color: _accent,
      letterSpacing: 3,
    ),
  );

  Widget _divider() => const Divider(color: _border, height: 1, thickness: 1);

  // ── Step indicator ────────────────────────────────────────────
  Widget _stepIndicator() {
    const labels = ['SELECT', 'DETAILS', 'CONFIRM'];
    return Row(
      children: List.generate(labels.length, (i) {
        final active = i == _step;
        final done = i < _step;
        return Row(
          children: [
            Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: done
                        ? _accent
                        : active
                        ? _accent.withOpacity(0.12)
                        : Colors.transparent,
                    border: Border.all(
                      color: done || active ? _accent : _border,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: done
                      ? const Icon(Icons.check, color: Colors.black, size: 13)
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            color: active ? _accent : _muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(height: 5),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 8,
                    color: active ? _accent : _muted,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            if (i < labels.length - 1)
              Container(
                width: 40,
                height: 1,
                margin: const EdgeInsets.only(bottom: 20),
                color: i < _step ? _accent : _border,
              ),
          ],
        );
      }),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // LEFT PANEL
  // ══════════════════════════════════════════════════════════════
  Widget _leftPanel() {
    final s = widget.settings;
    final eventName = s['eventName']?.toString() ?? 'Neon Nights';
    final location = s['location']?.toString() ?? 'Chennai';
    final date = _formatDate(s['eventDate']);
    final gaPrice = (s['ticketPrice'] as num?)?.toInt() ?? 799;
    final vipPrice = (s['vipPrice'] as num?)?.toInt() ?? 1999;

    return Container(
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: _border)),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          Positioned(
            left: -80,
            top: 120,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_accent.withOpacity(0.07), Colors.transparent],
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(64),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Row(
                      children: [
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.arrow_back, color: _muted, size: 13),
                                SizedBox(width: 8),
                                Text(
                                  'BACK',
                                  style: TextStyle(
                                    color: _muted,
                                    fontSize: 10,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        _userChip(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 64),
                _monoLabel('Booking'),
                const SizedBox(height: 20),
                Text(
                  eventName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: _white,
                    height: 0.92,
                    letterSpacing: -1,
                  ),
                ),
                const Text(
                  'VOL. 3',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: _accent2,
                    height: 0.92,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 48),
                _divider(),
                const SizedBox(height: 32),
                _metaRow('Date', date),
                const SizedBox(height: 20),
                _metaRow('Doors Open', '7:00 PM'),
                const SizedBox(height: 20),
                _metaRow('Venue', location),
                const SizedBox(height: 20),
                _metaRow(
                  'Capacity',
                  '${s['totalBookingsAllowed'] ?? 500} only',
                ),
                const SizedBox(height: 32),
                _divider(),
                const SizedBox(height: 32),
                _monoLabel('Pricing'),
                const SizedBox(height: 20),
                _priceRow('General Admission', '₹$gaPrice'),
                if (_vipEnabled) ...[
                  const SizedBox(height: 1),
                  _priceRow('VIP Access', '₹$vipPrice', accent: true),
                ],
                const SizedBox(height: 32),
                _divider(),
                const SizedBox(height: 32),
                _monoLabel('Policies'),
                const SizedBox(height: 16),
                ...[
                  'Non-refundable after purchase',
                  'Non-transferable tickets',
                  'Valid government ID required',
                  'No re-entry once you exit',
                  'Ages 18+ strictly enforced',
                  'UPI payments only',
                ].map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 14,
                          height: 1,
                          margin: const EdgeInsets.only(top: 8),
                          color: _muted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            p,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _userChip() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          CircleAvatar(
            radius: 14,
            backgroundColor: _accent.withOpacity(0.15),
            child: user.photoURL != null
                ? ClipOval(
                    child: Image.network(
                      user.photoURL!,
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Text(
                        (user.displayName ?? user.email ?? '?')[0]
                            .toUpperCase(),
                        style: const TextStyle(
                          color: _accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                : Text(
                    (user.displayName ?? user.email ?? '?')[0].toUpperCase(),
                    style: const TextStyle(
                      color: _accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          // Name + email
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (user.displayName != null && user.displayName!.isNotEmpty)
                Text(
                  user.displayName!,
                  style: const TextStyle(
                    color: _white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              Text(
                user.email ?? '',
                style: const TextStyle(color: _muted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // Divider
          Container(width: 1, height: 28, color: _border),
          const SizedBox(width: 10),
          // Logout
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () async {
                await GoogleAuthService.instance.signOut();
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text(
                'SIGN OUT',
                style: TextStyle(color: _muted, fontSize: 9, letterSpacing: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 100,
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 9, color: _muted, letterSpacing: 2),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: _white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );

  Widget _priceRow(String label, String price, {bool accent = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: accent ? _accent.withOpacity(0.05) : Colors.transparent,
          border: Border.all(
            color: accent ? _accent.withOpacity(0.3) : _border,
          ),
        ),
        child: Row(
          children: [
            Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
            const Spacer(),
            Text(
              price,
              style: TextStyle(
                color: accent ? _accent : _white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );

  // ══════════════════════════════════════════════════════════════
  // RIGHT PANEL
  // ══════════════════════════════════════════════════════════════
  Widget _rightPanel() {
    return Consumer<PaymentProvider>(
      builder: (context, pp, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(64),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _stepIndicator(),
              const SizedBox(height: 56),
              _monoLabel(
                [
                  'Choose Your Ticket',
                  'Attendee Details',
                  'Review & Pay',
                ][_step],
              ),
              const SizedBox(height: 8),
              Text(
                [
                  'Select ticket type and quantity.',
                  'Your QR ticket will be sent to this email.',
                  'Confirm details and complete payment via UPI.',
                ][_step],
                style: const TextStyle(
                  color: _muted,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: switch (_step) {
                    0 => _buildSelectStep(),
                    1 => _buildDetailsStep(),
                    _ => _buildConfirmStep(pp),
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectStep() {
    final maxPerUser = (widget.settings['maxPerUser'] as num?)?.toInt() ?? 6;
    final totalAllowed =
        (widget.settings['totalBookingsAllowed'] as num?)?.toInt() ?? 500;

    final effectiveMax = maxPerUser.clamp(
      1,
      totalAllowed > 0 ? totalAllowed : maxPerUser,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TicketCard(
          label: 'General Admission',
          price: (widget.settings['ticketPrice'] as num?)?.toInt() ?? 799,
          perks: const [
            'Full event access',
            'Standard queue entry',
            'QR ticket via email',
            'Non-transferable',
          ],
          selected: _selectedType == TicketType.general,
          onTap: () => setState(() => _selectedType = TicketType.general),
        ),
        if (_vipEnabled) ...[
          const SizedBox(height: 1),
          _TicketCard(
            label: 'VIP Access',
            price: (widget.settings['vipPrice'] as num?)?.toInt() ?? 1999,
            perks: const [
              'Priority fast-track entry',
              'Dedicated VIP area',
              'Complimentary welcome drink',
              'Exclusive merch bag',
              'QR ticket via email',
            ],
            selected: _selectedType == TicketType.vip,
            featured: true,
            onTap: () => setState(() => _selectedType = TicketType.vip),
          ),
        ],
        const SizedBox(height: 48),

        // Quantity
        Row(
          children: [
            const Text(
              'QUANTITY',
              style: TextStyle(fontSize: 10, color: _muted, letterSpacing: 3),
            ),
            const Spacer(),
            _QtyButton(
              icon: Icons.remove,
              onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
            ),
            SizedBox(
              width: 64,
              child: Center(
                child: Text(
                  '$_quantity',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: _white,
                  ),
                ),
              ),
            ),
            _QtyButton(
              icon: Icons.add,
              onTap: _quantity < effectiveMax
                  ? () => setState(() => _quantity++)
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Max $effectiveMax per booking',
            style: const TextStyle(fontSize: 10, color: _muted),
          ),
        ),
        const SizedBox(height: 40),
        _divider(),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_quantity × $_ticketLabel',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹$_total',
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: _accent,
                    height: 1,
                  ),
                ),
              ],
            ),
            const Spacer(),
            _PrimaryBtn(
              label: 'CONTINUE →',
              onTap: () => setState(() => _step = 1),
              // onTap: () => GoogleAuthService.instance.signOut(),
            ),
          ],
        ),
      ],
    );
  }

  // ── STEP 1 : Details ──────────────────────────────────────────
  Widget _buildDetailsStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BookingField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'As on your government ID',
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: 24),
          _BookingField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(v.trim())) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          _BookingField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: '98765 43210  (no country code)',
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'\d'))],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Phone is required';
              if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v.trim())) {
                return 'Enter a valid 10-digit Indian mobile number';
              }
              return null;
            },
          ),

          const SizedBox(height: 48),
          _divider(),
          const SizedBox(height: 28),

          Row(
            children: [
              _GhostBtn(
                label: '← BACK',
                onTap: () => setState(() => _step = 0),
              ),
              const Spacer(),
              _PrimaryBtn(
                label: 'REVIEW ORDER →',
                onTap: () {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _step = 2);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── STEP 2 : Confirm + Pay ────────────────────────────────────
  Widget _buildConfirmStep(PaymentProvider pp) {
    final rows = [
      ('Ticket Type', _ticketLabel),
      ('Quantity', '$_quantity'),
      ('Unit Price', '₹$_unitPrice'),
      ('Name', _nameController.text.trim()),
      ('Email', _emailController.text.trim()),
      ('Phone', _phoneController.text.trim()),
      ('Payment', 'UPI only'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Order table
        Container(
          decoration: BoxDecoration(
            color: _card,
            border: Border.all(color: _border),
          ),
          child: Column(
            children: [
              ...rows.map(
                (r) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Text(
                            r.$1.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              color: _muted,
                              letterSpacing: 2,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            r.$2,
                            style: const TextStyle(
                              fontSize: 14,
                              color: _white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: _border, height: 1),
                  ],
                ),
              ),
              // Total
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    const Text(
                      'TOTAL DUE',
                      style: TextStyle(
                        fontSize: 10,
                        color: _muted,
                        letterSpacing: 3,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '₹$_total',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: _accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // UPI notice
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.04),
            border: Border.all(color: _accent.withOpacity(0.2)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.currency_rupee, color: _accent, size: 14),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Payment is processed via Razorpay (UPI only). '
                  'You will be redirected to complete payment. '
                  'Your QR ticket will be emailed on successful payment.',
                  style: TextStyle(color: _muted, fontSize: 12, height: 1.6),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Policy note
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(border: Border.all(color: _border)),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: _muted, size: 13),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tickets are non-refundable and non-transferable. '
                  'By proceeding you agree to the event terms.',
                  style: TextStyle(color: _muted, fontSize: 12, height: 1.6),
                ),
              ),
            ],
          ),
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            color: _error.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: _error, size: 13),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: _error, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 32),
        _divider(),
        const SizedBox(height: 28),

        Row(
          children: [
            _GhostBtn(
              label: '← BACK',
              onTap: pp.isLoading ? null : () => setState(() => _step = 1),
            ),
            const Spacer(),
            // ── PAY BUTTON ──────────────────────────────────────
            pp.isLoading
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    color: _accent.withOpacity(0.3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'PROCESSING...',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  )
                : _PrimaryBtn(
                    label: 'PAY ₹$_total VIA UPI →',
                    onTap: _startPayment,
                  ),
          ],
        ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Row(
        children: [
          // LEFT — 38% fixed event summary
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.38,
            height: double.infinity,
            child: _leftPanel(),
          ),
          // RIGHT — 62% scrollable step content
          Expanded(child: _rightPanel()),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────

class _TicketCard extends StatelessWidget {
  final String label;
  final int price;
  final List<String> perks;
  final bool selected;
  final bool featured;
  final VoidCallback onTap;

  const _TicketCard({
    required this.label,
    required this.price,
    required this.perks,
    required this.selected,
    required this.onTap,
    this.featured = false,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: selected
                ? (featured
                      ? const Color(0xFF0D1A00)
                      : _accent.withOpacity(0.04))
                : _card,
            border: Border.all(
              color: selected ? _accent : _border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? _accent : _border,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? Center(
                        child: CircleAvatar(
                          radius: 4,
                          backgroundColor: _accent,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          label.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: _muted,
                            letterSpacing: 2,
                          ),
                        ),
                        if (featured) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            color: _accent,
                            child: const Text(
                              'POPULAR',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '₹$price',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: _white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 20,
                      runSpacing: 8,
                      children: perks
                          .map(
                            (p) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 12, height: 1, color: _accent),
                                const SizedBox(width: 8),
                                Text(
                                  p,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _muted,
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
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

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(border: Border.all(color: _border)),
          child: Icon(icon, color: onTap != null ? _white : _muted, size: 16),
        ),
      ),
    );
  }
}

class _BookingField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const _BookingField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 9, color: _muted, letterSpacing: 2),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(color: _white, fontSize: 15),
          cursorColor: _accent,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _muted, fontSize: 14),
            filled: true,
            fillColor: _card,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: _border),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: _border),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: _accent),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: _error),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: _error),
            ),
            errorStyle: const TextStyle(
              color: _error,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _PrimaryBtn({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          color: onTap != null ? _accent : _accent.withOpacity(0.4),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _GhostBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _GhostBtn({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(border: Border.all(color: _border)),
          child: Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Painters ──────────────────────────────────────────────────
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

// ── Date formatter ────────────────────────────────────────────
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
