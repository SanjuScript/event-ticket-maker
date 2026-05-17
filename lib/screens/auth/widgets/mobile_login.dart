import 'package:event_ticket_maker/screens/auth/login_screen.dart';
import 'package:event_ticket_maker/screens/auth/widgets/glass_card.dart';
import 'package:event_ticket_maker/screens/auth/widgets/otp_panel.dart';
import 'package:event_ticket_maker/screens/auth/widgets/phone_panel.dart';
import 'package:flutter/material.dart';

class MobileLogin extends StatelessWidget {
  final bool showOtp, isLoading;
  final TextEditingController phoneCtrl;
  final FocusNode phoneFocus;
  final List<TextEditingController> otpCtrls;
  final List<FocusNode> otpFocuses;
  final String phone;
  final int resendSecs;
  final Animation<double> cardFade, shake;
  final Animation<Offset> cardSlide;
  final VoidCallback onSend, onVerify, onResend, onBack;

  const MobileLogin({
    super.key,
    required this.showOtp,
    required this.isLoading,
    required this.phoneCtrl,
    required this.phoneFocus,
    required this.otpCtrls,
    required this.otpFocuses,
    required this.phone,
    required this.resendSecs,
    required this.cardFade,
    required this.cardSlide,
    required this.shake,
    required this.onSend,
    required this.onVerify,
    required this.onResend,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 32,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        children: [
          // Concert brand
          Column(
            children: [
              Text(
                'ANIRUDH',
                style: TextStyle(
                  color: kNeonCyan,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  shadows: [
                    Shadow(color: kNeonCyan.withOpacity(0.6), blurRadius: 20),
                  ],
                ),
              ),
              Text(
                'LIVE IN CONCERT',
                style: TextStyle(
                  color: kNeonMagenta,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 5,
                  shadows: [
                    Shadow(
                      color: kNeonMagenta.withOpacity(0.6),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          FadeTransition(
            opacity: cardFade,
            child: SlideTransition(
              position: cardSlide,
              child: GlassCard(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 380),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.06, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: showOtp
                      ? OtpPanel(
                          ctrls: otpCtrls,
                          focuses: otpFocuses,
                          phone: phone,
                          resendSecs: resendSecs,
                          shake: shake,
                          loading: isLoading,
                          onVerify: onVerify,
                          onResend: onResend,
                          onBack: onBack,
                        )
                      : PhonePanel(
                          ctrl: phoneCtrl,
                          focus: phoneFocus,
                          shake: shake,
                          loading: isLoading,
                          onSend: onSend,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
