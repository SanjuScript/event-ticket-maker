import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_ticket_maker/firebase_options.dart';
import 'package:event_ticket_maker/provider/device_info_provider.dart';
import 'package:event_ticket_maker/provider/select_image.dart';
import 'package:event_ticket_maker/provider/verification_state.dart';
import 'package:event_ticket_maker/screens/home_page.dart';
import 'package:event_ticket_maker/screens/maintainance_screen.dart';
import 'package:event_ticket_maker/screens/splash_screen.dart';
import 'package:event_ticket_maker/screens/success_screen.dart';
import 'package:event_ticket_maker/widgets/gate_wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

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

        return MaterialApp(
          title: liveSettings['eventName'] ?? settings['eventName'] ?? 'Event',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            fontFamily: 'newbo',
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
            ),
          ),
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
          return const Scaffold(
            backgroundColor: Color(0xFF0A0A0A),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE8FF47),
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
