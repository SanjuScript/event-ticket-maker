// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/foundation.dart';

// // ─── Auth Result wrapper ──────────────────────────────────────────────────────

// enum AuthStatus {
//   success,
//   invalidPhone,
//   invalidOtp,
//   otpExpired,
//   tooManyRequests,
//   networkError,
//   recaptchaFailed,
//   unknown,
// }

// class AuthResult {
//   final AuthStatus status;
//   final String? message;       
//   final UserCredential? credential; 

//   const AuthResult._({
//     required this.status,
//     this.message,
//     this.credential,
//   });

//   bool get isSuccess => status == AuthStatus.success;

//   factory AuthResult.success(UserCredential cred) => AuthResult._(
//         status: AuthStatus.success,
//         message: 'Signed in successfully!',
//         credential: cred,
//       );

//   factory AuthResult.failure(AuthStatus status, String message) => AuthResult._(
//         status: status,
//         message: message,
//       );
// }

// // ─── Auth Service ─────────────────────────────────────────────────────────────

// class AuthService {
//   AuthService._();
//   static final AuthService instance = AuthService._();

//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   /// Holds the web confirmation result between sendOtp() and verifyOtp().
//   ConfirmationResult? _webConfirmationResult;

//   // ── Current user ────────────────────────────────────────────────────────────

//   User? get currentUser => _auth.currentUser;
//   bool get isSignedIn => currentUser != null;

//   Stream<User?> get authStateChanges => _auth.authStateChanges();

//   // ── Sign out ─────────────────────────────────────────────────────────────────

//   Future<void> signOut() async => _auth.signOut();

//   // ── Send OTP (web — uses signInWithPhoneNumber + reCAPTCHA) ─────────────────
//   //
//   // [phoneNumber]   Full E.164 format, e.g. "+919876543210"
//   // [recaptchaContainerId]  Optional HTML element ID for an inline reCAPTCHA
//   //                         widget. If null the invisible widget is used.
//   //
//   // Returns an [AuthResult] so the caller never needs to catch Firebase errors.

//   Future<AuthResult> sendOtp({
//     required String phoneNumber,
//     String? recaptchaContainerId,
//   }) async {
//     if (!kIsWeb) {
//       // This service is web-only.  Add Android/iOS handling here if needed.
//       return AuthResult.failure(
//         AuthStatus.unknown,
//         'Phone auth via this service is web-only.',
//       );
//     }

//     try {
//       // Build the reCAPTCHA verifier.
//       // • container = null  → invisible (full-page modal overlay)
//       // • container = 'some-div-id' → inline compact widget
//       final verifier = RecaptchaVerifier(
//         auth: _auth,
//         container: recaptchaContainerId,       // null = invisible
//         size: recaptchaContainerId != null
//             ? RecaptchaVerifierSize.compact
//             : RecaptchaVerifierSize.normal,
//         theme: RecaptchaVerifierTheme.dark,
//         onSuccess: () => debugPrint('[AuthService] reCAPTCHA completed ✓'),
//         onError: (FirebaseAuthException e) =>
//             debugPrint('[AuthService] reCAPTCHA error: ${e.message}'),
//         onExpired: () =>
//             debugPrint('[AuthService] reCAPTCHA expired — user must retry'),
//       );

//       _webConfirmationResult = await _auth.signInWithPhoneNumber(
//         phoneNumber,
//         verifier,
//       );

//       debugPrint('[AuthService] OTP sent to $phoneNumber');
//       return AuthResult._(
//         status: AuthStatus.success,
//         message: 'OTP sent to $phoneNumber',
//       );
//     } on FirebaseAuthException catch (e) {
//       return _mapSendError(e);
//     } catch (e) {
//       debugPrint('[AuthService] sendOtp unexpected error: $e');
//       return AuthResult.failure(
//         AuthStatus.unknown,
//         'Something went wrong. Please try again.',
//       );
//     }
//   }

//   // ── Verify OTP ───────────────────────────────────────────────────────────────
//   //
//   // Call after [sendOtp] succeeds. Provide the 6-digit SMS code.

//   Future<AuthResult> verifyOtp({required String smsCode}) async {
//     if (_webConfirmationResult == null) {
//       return AuthResult.failure(
//         AuthStatus.unknown,
//         'No OTP session found. Please request a new code.',
//       );
//     }

//     try {
//       final credential = await _webConfirmationResult!.confirm(smsCode);
//       debugPrint('[AuthService] OTP verified — uid: ${credential.user?.uid}');
//       _webConfirmationResult = null; // clear after use
//       return AuthResult.success(credential);
//     } on FirebaseAuthException catch (e) {
//       return _mapVerifyError(e);
//     } catch (e) {
//       debugPrint('[AuthService] verifyOtp unexpected error: $e');
//       return AuthResult.failure(
//         AuthStatus.unknown,
//         'Verification failed. Please try again.',
//       );
//     }
//   }

//   // ── Error mappers ────────────────────────────────────────────────────────────

//   AuthResult _mapSendError(FirebaseAuthException e) {
//     debugPrint('[AuthService] sendOtp Firebase error: ${e.code} — ${e.message}');
//     switch (e.code) {
//       case 'invalid-phone-number':
//         return AuthResult.failure(
//           AuthStatus.invalidPhone,
//           'The phone number you entered is invalid. Please check and try again.',
//         );
//       case 'too-many-requests':
//         return AuthResult.failure(
//           AuthStatus.tooManyRequests,
//           'Too many attempts. Please wait a few minutes before trying again.',
//         );
//       case 'captcha-check-failed':
//       case 'recaptcha-not-enabled':
//         return AuthResult.failure(
//           AuthStatus.recaptchaFailed,
//           'reCAPTCHA verification failed. Please refresh and try again.',
//         );
//       case 'network-request-failed':
//         return AuthResult.failure(
//           AuthStatus.networkError,
//           'Network error. Please check your internet connection.',
//         );
//       case 'quota-exceeded':
//         return AuthResult.failure(
//           AuthStatus.tooManyRequests,
//           'SMS quota exceeded for this project. Please try later.',
//         );
//       default:
//         return AuthResult.failure(
//           AuthStatus.unknown,
//           e.message ?? 'Failed to send OTP. Please try again.',
//         );
//     }
//   }

//   AuthResult _mapVerifyError(FirebaseAuthException e) {
//     debugPrint('[AuthService] verifyOtp Firebase error: ${e.code} — ${e.message}');
//     switch (e.code) {
//       case 'invalid-verification-code':
//         return AuthResult.failure(
//           AuthStatus.invalidOtp,
//           'Incorrect OTP. Please check the code and try again.',
//         );
//       case 'code-expired':
//         return AuthResult.failure(
//           AuthStatus.otpExpired,
//           'This OTP has expired. Please request a new one.',
//         );
//       case 'session-expired':
//         return AuthResult.failure(
//           AuthStatus.otpExpired,
//           'Your session has expired. Please start over.',
//         );
//       case 'network-request-failed':
//         return AuthResult.failure(
//           AuthStatus.networkError,
//           'Network error during verification. Please check your connection.',
//         );
//       default:
//         return AuthResult.failure(
//           AuthStatus.unknown,
//           e.message ?? 'Verification failed. Please try again.',
//         );
//     }
//   }
// }