import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_ticket_maker/firebase_options.dart';
import 'package:event_ticket_maker/provider/device_info_provider.dart';
import 'package:event_ticket_maker/provider/select_image.dart';
import 'package:event_ticket_maker/provider/verification_state.dart';
import 'package:event_ticket_maker/screens/maintainance_screen.dart';
import 'package:event_ticket_maker/screens/splash_screen.dart';
import 'package:event_ticket_maker/widgets/gate_wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

const _defaultPrimaryColor = Color(0xFFE8FF47);

Color _parsePrimaryColor(dynamic value) {
  if (value is Color) return value;

  if (value is int) {
    return Color(value);
  }

  if (value is String) {
    final normalized = value
        .trim()
        .replaceFirst('#', '')
        .replaceFirst('0x', '')
        .replaceFirst('0X', '');

    if (normalized.length == 6) {
      return Color(int.parse('FF$normalized', radix: 16));
    }

    if (normalized.length == 8) {
      return Color(int.parse(normalized, radix: 16));
    }
  }

  return _defaultPrimaryColor;
}

bool _parseBool(dynamic value, {required bool fallback}) {
  if (value is bool) return value;

  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
  }

  return fallback;
}

ThemeData _buildAppTheme({
  required Color primaryColor,
  required Brightness brightness,
}) {
  final isDark = brightness == Brightness.dark;
  final backgroundColor = isDark
      ? const Color(0xFF050505)
      : const Color(0xFFF7F7F2);
  final surfaceColor = isDark ? const Color(0xFF141414) : Colors.white;
  final textColor = isDark ? const Color(0xFFF5F5F0) : const Color(0xFF111111);
  final mutedTextColor = isDark
      ? const Color(0xFFBEBEB8)
      : const Color(0xFF4A4A4A);

  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
      ).copyWith(
        primary: primaryColor,
        secondary: primaryColor,
        tertiary: primaryColor,
      );

  return ThemeData(
    brightness: brightness,
    colorScheme: colorScheme,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    canvasColor: backgroundColor,
    fontFamily: 'newbo',
    progressIndicatorTheme: ProgressIndicatorThemeData(color: primaryColor),
    appBarTheme: AppBarTheme(
      backgroundColor: backgroundColor,
      foregroundColor: textColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceColor,
      contentTextStyle: TextStyle(
        fontFamily: 'newboT',
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        fontFamily: 'newbo',
        fontWeight: FontWeight.bold,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'newbo',
        fontWeight: FontWeight.bold,
        letterSpacing: 0,
      ),
      bodySmall: TextStyle(
        fontFamily: 'newboT',
        fontWeight: FontWeight.bold,
        letterSpacing: 0,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'newboT',
        fontWeight: FontWeight.bold,
        letterSpacing: 0,
      ),
    ).apply(bodyColor: mutedTextColor, displayColor: textColor),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  log("LOCAL BUILD ${DateTime.now().millisecondsSinceEpoch}");
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // if (kIsWeb) {
  //   try {
  //     await GoogleSignIn.instance.initialize(
  //       clientId:
  //           "395272863504-sbkna0b53pbg3p2t5htcr4oi5v3hs02a.apps.googleusercontent.com",
  //     );
  //   } catch (e) {
  //     debugPrint('[main] GoogleSignIn init: $e');
  //   }
  // }
  await dotenv.load(fileName: ".env");
  final doc = await FirebaseFirestore.instance
      .collection('settings')
      .doc('site')
      .get();
  final settings = doc.data() ?? {};
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => ImageUploadProvider()),
        ChangeNotifierProvider(create: (_) => DeviceInfoProvider()),
      ],
      child: MyApp(settings: settings),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Map<String, dynamic> settings;
  const MyApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    Provider.of<DeviceInfoProvider>(context).init();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('settings')
          .doc('site')
          .snapshots(),
      builder: (context, snapshot) {
        final liveSettings =
            (snapshot.data?.data() as Map<String, dynamic>?) ?? settings;
        final isMaintenance = liveSettings['maintenanceMode'] == true;
        final primaryColor = _parsePrimaryColor(liveSettings['primaryColor']);
        final darkModeForced = _parseBool(
          liveSettings['darkModeForced'],
          fallback: true,
        );

        return MaterialApp(
          title: liveSettings['eventName'] ?? settings['eventName'] ?? 'Event',
          debugShowCheckedModeBanner: false,
          theme: _buildAppTheme(
            primaryColor: primaryColor,
            brightness: Brightness.light,
          ),
          darkTheme: _buildAppTheme(
            primaryColor: primaryColor,
            brightness: Brightness.dark,
          ),
          themeMode: darkModeForced ? ThemeMode.dark : ThemeMode.system,
          home: isMaintenance
              ? _MaintenanceGate(liveSettings: liveSettings)
              : GateWrapper(
                  settings: liveSettings,
                  child: const SplashScreen(),
                ),
        );
      },
    );
  }
}

class _MaintenanceGate extends StatelessWidget {
  final Map<String, dynamic> liveSettings;
  const _MaintenanceGate({required this.liveSettings});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final primaryColor = _parsePrimaryColor(liveSettings['primaryColor']);

    if (uid == null) {
      return const MaintenanceScreen();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('whitelisted_users')
          .doc(uid)
          .get(),
      builder: (context, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: const Color(0xFF0A0A0A),
            body: Center(
              child: CircularProgressIndicator(
                color: primaryColor,
                strokeWidth: 1.5,
              ),
            ),
          );
        }
        final isOwner =
            (userSnap.data?.data() as Map<String, dynamic>?)?['owner'] == true;

        if (isOwner) {
          return GateWrapper(
            settings: liveSettings,
            child: const SplashScreen(),
          );
        }
        return const MaintenanceScreen();
      },
    );
  }
}
