import 'package:event_ticket_maker/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhonePanel extends StatefulWidget {
  final TextEditingController ctrl;
  final FocusNode focus;
  final Animation<double> shake;
  final bool loading;
  final VoidCallback onSend;
  const PhonePanel({
    required this.ctrl,
    required this.focus,
    required this.shake,
    required this.loading,
    required this.onSend,
  });
  @override
  State<PhonePanel> createState() => PhonePanelState();
}

class PhonePanelState extends State<PhonePanel> {
  bool _focused = false, _hover = false;
  @override
  void initState() {
    super.initState();
    widget.focus.addListener(
      () => setState(() => _focused = widget.focus.hasFocus),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          children: [
            Container(
              width: 3,
              height: 20,
              decoration: BoxDecoration(
                color: kNeonCyan,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(color: kNeonCyan.withOpacity(0.6), blurRadius: 8),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'SIGN IN',
              style: TextStyle(
                color: kNeonCyan,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Enter your\nmobile number',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "We'll send a one-time verification code.",
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),

        // Phone field
        AnimatedBuilder(
          animation: widget.shake,
          builder: (_, child) => Transform.translate(
            offset: Offset(widget.shake.value, 0),
            child: child,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _focused
                  ? kNeonCyan.withOpacity(0.07)
                  : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _focused ? kNeonCyan : Colors.white.withOpacity(0.12),
                width: _focused ? 1.5 : 1,
              ),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: kNeonCyan.withOpacity(0.20),
                        blurRadius: 20,
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: Colors.white.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('🇮🇳', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        '+91',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: widget.ctrl,
                    focusNode: widget.focus,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                    onSubmitted: (_) => widget.onSend(),
                    decoration: InputDecoration(
                      hintText: '98765 43210',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.22),
                        fontSize: 16,
                        letterSpacing: 2,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            onTap: widget.loading ? null : widget.onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _hover
                      ? [kNeonCyan, kPurple]
                      : [kNeonMagenta, kPurple],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (_hover ? kNeonCyan : kNeonMagenta).withOpacity(
                      _hover ? 0.55 : 0.38,
                    ),
                    blurRadius: _hover ? 32 : 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: widget.loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Send OTP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 12,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(width: 5),
              Text(
                'Your number is safe with us',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
