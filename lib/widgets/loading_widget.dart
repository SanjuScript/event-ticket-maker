import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final bool isLoading;
  const LoadingWidget({super.key, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox();

    return Container(
      color: Colors.black.withOpacity(0.6), // subtle blur background
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Colors.orangeAccent,
              strokeWidth: 4,
            ),
            SizedBox(height: 20),
            _AnimatedLoadingText(),
          ],
        ),
      ),
    );
  }
}

class _AnimatedLoadingText extends StatefulWidget {
  const _AnimatedLoadingText();

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
    _fadeInFadeOut = Tween<double>(begin: 0.2, end: 1.0).animate(_controller);
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
      child: const Text(
        'Please wait...',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
