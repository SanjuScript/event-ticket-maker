import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer' as dev;

class GoogleAuthService {
  GoogleAuthService._();
  static final instance = GoogleAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _google = GoogleSignIn.instance;
  bool _initialized = false;

  static const _tag = '[GoogleAuthService]';

  Future<void> init() async {
    if (_initialized) {
      dev.log('$_tag init() skipped — already initialized', name: 'Auth');
      return;
    }
    dev.log('$_tag Initializing GoogleSignIn...', name: 'Auth');
    await _google.initialize();
    _initialized = true;
    dev.log('$_tag GoogleSignIn initialized successfully', name: 'Auth');
  }

  Future<GoogleSignInAccount?> signIn() async {
    dev.log('$_tag signIn() called', name: 'Auth');
    await init();
    try {
      dev.log('$_tag Calling _google.authenticate()...', name: 'Auth');
      final account = await _google.authenticate();
      dev.log(
        '$_tag authenticate() success — email: ${account.email}',
        name: 'Auth',
      );
      return account;
    } catch (e, st) {
      dev.log(
        '$_tag authenticate() failed',
        name: 'Auth',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    dev.log(
      '$_tag signOut() called — platform: ${kIsWeb ? "web" : "native"}',
      name: 'Auth',
    );
    if (kIsWeb) {
      await _auth.signOut();
      dev.log('$_tag Firebase signOut done (web)', name: 'Auth');
    } else {
      await _google.signOut();
      dev.log('$_tag Google signOut done', name: 'Auth');
      await _auth.signOut();
      dev.log('$_tag Firebase signOut done', name: 'Auth');
    }
  }

  // ── Main entry point ───────────────────────────────────
  Future<UserCredential?> signInWithGoogle() async {
    dev.log(
      '$_tag signInWithGoogle() — platform: ${kIsWeb ? "web" : "native"}',
      name: 'Auth',
    );
    if (kIsWeb) return _signInWeb();
    return _signInNative();
  }

  // ── Save / update user in Firestore ───────────────────
  Future<void> _saveUserToFirestore(User user) async {
    dev.log(
      '$_tag _saveUserToFirestore() — uid: ${user.uid} email: ${user.email}',
      name: 'Auth',
    );
    try {
      final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);

      final doc = await ref.get();

      if (doc.exists) {
        dev.log('$_tag User exists — updating lastLoginAt', name: 'Auth');
        await ref.update({'lastLoginAt': FieldValue.serverTimestamp()});
        dev.log('$_tag lastLoginAt updated', name: 'Auth');
      } else {
        dev.log('$_tag New user — creating Firestore doc', name: 'Auth');
        await ref.set({
          'uid': user.uid,
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'photoUrl': user.photoURL ?? '',
          'phone': user.phoneNumber ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'provider': 'google',
        });
        dev.log('$_tag Firestore doc created for ${user.email}', name: 'Auth');
      }
    } catch (e, st) {
      dev.log(
        '$_tag _saveUserToFirestore() failed',
        name: 'Auth',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  // ── Web ────────────────────────────────────────────────
  Future<UserCredential?> _signInWeb() async {
    dev.log('$_tag _signInWeb() started', name: 'Auth');
    try {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');

      dev.log('$_tag Calling signInWithPopup()...', name: 'Auth');
      final result = await _auth.signInWithPopup(provider);
      dev.log(
        '$_tag signInWithPopup() success — uid: ${result.user?.uid}',
        name: 'Auth',
      );

      if (result.user != null) {
        await _saveUserToFirestore(result.user!);
      } else {
        dev.log('$_tag signInWithPopup() returned null user', name: 'Auth');
      }

      return result;
    } on FirebaseAuthException catch (e, st) {
      dev.log(
        '$_tag FirebaseAuthException in _signInWeb() — code: ${e.code} msg: ${e.message}',
        name: 'Auth',
        error: e,
        stackTrace: st,
      );
      if (e.code == 'account-exists-with-different-credential') {
        throw Exception("ACCOUNT_EXISTS_LINK_REQUIRED");
      }
      if (e.code == 'credential-already-in-use') {
        dev.log(
          '$_tag credential-already-in-use — signing in with existing credential',
          name: 'Auth',
        );
        return await _auth.signInWithCredential(e.credential!);
      }
      rethrow;
    } catch (e, st) {
      dev.log(
        '$_tag Unexpected error in _signInWeb()',
        name: 'Auth',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  // ── Native ─────────────────────────────────────────────
  Future<UserCredential?> _signInNative() async {
    dev.log('$_tag _signInNative() started', name: 'Auth');
    try {
      final account = await signIn();
      if (account == null) {
        dev.log('$_tag signIn() returned null — user cancelled', name: 'Auth');
        return null;
      }

      dev.log('$_tag Getting auth tokens for ${account.email}', name: 'Auth');
      final auth = account.authentication;
      dev.log(
        '$_tag Tokens received — idToken: ${auth.idToken != null ? "present" : "null"} '
        'accessToken: ',
        name: 'Auth',
      );

      final credential = GoogleAuthProvider.credential(idToken: auth.idToken);

      dev.log('$_tag Calling signInWithCredential()...', name: 'Auth');
      final result = await _auth.signInWithCredential(credential);
      dev.log(
        '$_tag signInWithCredential() success — uid: ${result.user?.uid}',
        name: 'Auth',
      );

      if (result.user != null) {
        await _saveUserToFirestore(result.user!);
      } else {
        dev.log(
          '$_tag signInWithCredential() returned null user',
          name: 'Auth',
        );
      }

      return result;
    } on FirebaseAuthException catch (e, st) {
      dev.log(
        '$_tag FirebaseAuthException in _signInNative() — code: ${e.code} msg: ${e.message}',
        name: 'Auth',
        error: e,
        stackTrace: st,
      );
      if (e.code == 'account-exists-with-different-credential') {
        throw Exception("ACCOUNT_EXISTS_LINK_REQUIRED");
      }
      if (e.code == 'credential-already-in-use') {
        dev.log(
          '$_tag credential-already-in-use — signing in with existing credential',
          name: 'Auth',
        );
        return await _auth.signInWithCredential(e.credential!);
      }
      rethrow;
    } catch (e, st) {
      dev.log(
        '$_tag Unexpected error in _signInNative()',
        name: 'Auth',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
