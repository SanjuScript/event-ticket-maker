import 'package:event_ticket_maker/screens/auth/login_screen.dart';
import 'package:event_ticket_maker/screens/auth/widgets/otp_box.dart';
import 'package:flutter/material.dart';

class OtpPanel extends StatefulWidget {
  final List<TextEditingController> ctrls;
  final List<FocusNode> focuses;
  final String phone;
  final int resendSecs;
  final Animation<double> shake;
  final bool loading;
  final VoidCallback onVerify, onResend, onBack;
  const OtpPanel({
    required this.ctrls,
    required this.focuses,
    required this.phone,
    required this.resendSecs,
    required this.shake,
    required this.loading,
    required this.onVerify,
    required this.onResend,
    required this.onBack,
  });
  @override
  State<OtpPanel> createState() => OtpPanelState();
}

class OtpPanelState extends State<OtpPanel> {
  int? _focusedIdx;
  bool _hover = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 6; i++) {
      final idx = i;
      widget.focuses[idx].addListener(
        () => setState(
          () => _focusedIdx = widget.focuses[idx].hasFocus ? idx : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: widget.onBack,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white.withOpacity(0.4),
                size: 13,
              ),
              const SizedBox(width: 4),
              Text(
                'Back',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Container(
              width: 3,
              height: 20,
              decoration: BoxDecoration(
                color: kNeonMagenta,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: kNeonMagenta.withOpacity(0.6),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'VERIFY OTP',
              style: TextStyle(
                color: kNeonMagenta,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Enter the code\nwe sent you',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 13,
            ),
            children: [
              const TextSpan(text: 'Code sent to '),
              TextSpan(
                text: '+91 ${widget.phone}',
                style: const TextStyle(
                  color: kNeonGold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        AnimatedBuilder(
          animation: widget.shake,
          builder: (_, child) => Transform.translate(
            offset: Offset(widget.shake.value, 0),
            child: child,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              6,
              (i) => OtpBox(
                ctrl: widget.ctrls[i],
                focus: widget.focuses[i],
                filled: widget.ctrls[i].text.isNotEmpty,
                focused: _focusedIdx == i,
              ),
            ),
          ),
        ),

        const SizedBox(height: 28),

        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            onTap: widget.loading ? null : widget.onVerify,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _hover
                      ? [kNeonCyan, kNeonMagenta]
                      : [kNeonMagenta, kPurple],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: kNeonMagenta.withOpacity(_hover ? 0.60 : 0.38),
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
                          Icon(
                            Icons.verified_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Verify & Continue',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: widget.onResend,
            child: widget.resendSecs > 0
                ? RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.38),
                        fontSize: 13,
                      ),
                      children: [
                        const TextSpan(text: 'Resend OTP in '),
                        TextSpan(
                          text: '${widget.resendSecs}s',
                          style: const TextStyle(
                            color: kNeonGold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
                : const Text(
                    'Resend OTP',
                    style: TextStyle(
                      color: kNeonCyan,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: kNeonCyan,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
