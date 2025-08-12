import 'dart:html';

bool isMobileBrowser() {
  final userAgent = window.navigator.userAgent.toLowerCase();
  return userAgent.contains('iphone') ||
         userAgent.contains('android') ||
         userAgent.contains('ipad') ||
         userAgent.contains('mobile');
}
