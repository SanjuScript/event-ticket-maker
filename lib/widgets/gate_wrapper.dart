import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GateWrapper extends StatefulWidget {
  final String? eventId;
  final Widget child;
  final Map<String, dynamic> settings;

  const GateWrapper({
    super.key,
    this.eventId = "ma7qfNJQ4Ev8uab8ztVd",
    required this.child,
    required this.settings,
  });

  @override
  State<GateWrapper> createState() => _GateWrapperState();
}

class _GateWrapperState extends State<GateWrapper> {
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _eventStream;

  static const _bg = Color(0xFF0A0A0A);
  static const _accent = Color(0xFFE8FF47);
  static const _muted = Color(0xFF888888);
  static const _white = Color(0xFFF5F5F0);
  static const _border = Color(0xFF2A2A2A);
  static const _surface = Color(0xFF141414);

  @override
  void initState() {
    super.initState();
    _eventStream = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .snapshots();
  }

  // Check if signed-in user is whitelisted
  Future<bool> _isUserWhitelisted() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final doc = await FirebaseFirestore.instance
        .collection('whitelisted_users')
        .doc(uid)
        .get();
    return doc.exists;
  }

  // Check if email is in whitelist (for guest flow)
  Future<bool> _isEmailWhitelisted(String email) async {
    final query = await FirebaseFirestore.instance
        .collection('whitelisted_users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Widget _buildGate(Map<String, dynamic>? eventData) {
    final isPublic = eventData?['is_public'] as bool? ?? false;
    if (!isPublic) return const _RestrictedScreen();

    final requireWhitelist = widget.settings['requireWhitelist'] == true;
    final guestCheckout = widget.settings['guestCheckoutEnabled'] == true;
    final currentUser = FirebaseAuth.instance.currentUser;

    // No whitelist required — let everyone through
    if (!requireWhitelist) return widget.child;

    // Whitelist required — check the current user
    return FutureBuilder<bool>(
      future: currentUser != null ? _isUserWhitelisted() : Future.value(false),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final isWhitelisted = snap.data == true;

        // Signed in and whitelisted — allow
        if (currentUser != null && isWhitelisted) return widget.child;

        // Not signed in but guest checkout is on — allow
        if (currentUser == null && guestCheckout) return widget.child;

        // Not whitelisted — show restricted with reason
        return _RestrictedScreen(
          message: currentUser != null
              ? 'Your account is not on the guest list for this event.'
              : 'This event requires an invitation. Please sign in with your invited email.',
          showSignIn: currentUser == null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _eventStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }
        if (snapshot.hasError) {
          debugPrint('GateWrapper error: ${snapshot.error}');
          return const _RestrictedScreen();
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const _RestrictedScreen();
        }

        return _buildGate(snapshot.data!.data());
      },
    );
  }
}

// ── Loading ───────────────────────────────────────────────

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE8FF47),
          strokeWidth: 1.5,
        ),
      ),
    );
  }
}

// ── Restricted ────────────────────────────────────────────

class _RestrictedScreen extends StatelessWidget {
  final String message;
  final bool showSignIn;

  const _RestrictedScreen({
    this.message = 'This event is not available.',
    this.showSignIn = false,
  });

  static const _bg = Color(0xFF0A0A0A);
  static const _accent = Color(0xFFE8FF47);
  static const _muted = Color(0xFF888888);
  static const _white = Color(0xFFF5F5F0);
  static const _border = Color(0xFF2A2A2A);
  static const _surface = Color(0xFF141414);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFFF4444).withOpacity(0.3),
                  ),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFFFF4444),
                  size: 28,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'ACCESS RESTRICTED',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _white,
                  letterSpacing: 4,
                  fontFamily: 'newbo',
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 13,
                    height: 1.6,
                    fontFamily: 'newbo',
                  ),
                ),
              ),
              if (showSignIn) ...[
                const SizedBox(height: 28),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () async {
                      try {
                        await FirebaseAuth.instance.signInWithPopup(
                          GoogleAuthProvider(),
                        );
                        // GateWrapper will rebuild automatically
                        // via StreamBuilder after auth state change
                      } catch (e) {
                        debugPrint('Sign in error: $e');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      color: _accent,
                      child: const Text(
                        'SIGN IN WITH GOOGLE',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          fontFamily: 'newbo',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Contact the organiser if you believe this is a mistake.',
                style: TextStyle(color: _muted.withOpacity(0.5), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
