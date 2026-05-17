import 'package:event_ticket_maker/screens/auth/login_screen.dart';
import 'package:event_ticket_maker/screens/auth/widgets/glass_card.dart';
import 'package:event_ticket_maker/screens/auth/widgets/otp_panel.dart';
import 'package:event_ticket_maker/screens/auth/widgets/phone_panel.dart';
import 'package:flutter/material.dart';

class DesktopLogin extends StatelessWidget {
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

  const DesktopLogin({
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
          child: Row(
            children: [
              // Left branding
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ANIRUDH',
                      style: TextStyle(
                        color: kNeonCyan,
                        fontSize: 72,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -3,
                        height: 0.9,
                        shadows: [
                          Shadow(
                            color: kNeonCyan.withOpacity(0.55),
                            blurRadius: 40,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'RAVICHANDER',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'LIVE IN CONCERT',
                      style: TextStyle(
                        color: kNeonMagenta,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 7,
                        shadows: [
                          Shadow(
                            color: kNeonMagenta.withOpacity(0.65),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    Text(
                      'One login.\nUnforgettable night.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 18,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 36),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _badge(
                          Icons.verified_rounded,
                          'Verified Payments',
                          kNeonCyan,
                        ),
                        _badge(Icons.lock_rounded, 'OTP Secured', kNeonMagenta),
                        _badge(
                          Icons.bolt_rounded,
                          'Instant Booking',
                          kNeonGold,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 52),

              // Right card
              Expanded(
                flex: 4,
                child: FadeTransition(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.22), width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
