import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final bool isLoading;
  final bool isPaymentDone;
  const LoadingWidget({
    super.key,
    this.isLoading = false,
    this.isPaymentDone = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox();

    return Container(
      alignment: Alignment.center,
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.white, strokeWidth: 4),
                SizedBox(height: 20),
                _AnimatedLoadingText(isPaymentDone: isPaymentDone),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedLoadingText extends StatefulWidget {
  final bool isPaymentDone;
  const _AnimatedLoadingText({required this.isPaymentDone});

  @override
  State<_AnimatedLoadingText> createState() => _AnimatedLoadingTextState();
}

class _AnimatedLoadingTextState extends State<_AnimatedLoadingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeInFadeOut;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _fadeInFadeOut = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeInFadeOut,
      child: Text(
        widget.isPaymentDone ? "Loading Ticket...." : 'Processing Payment...',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
