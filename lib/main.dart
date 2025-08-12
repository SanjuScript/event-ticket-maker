import 'package:event_ticket_maker/firebase_options.dart';
import 'package:event_ticket_maker/provider/select_image.dart';
import 'package:event_ticket_maker/provider/verification_state.dart';
import 'package:event_ticket_maker/screens/home_screen.dart';
import 'package:event_ticket_maker/screens/success_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: ".env");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => ImageUploadProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Event',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        fontFamily: 'Quicksand', 
        textTheme: TextTheme(
          headlineSmall: TextStyle(
            fontFamily: 'Quicksanju',
            fontWeight: FontWeight.bold,
            letterSpacing: 0,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'Quicksanju',
            fontWeight: FontWeight.bold,
            letterSpacing: 0,
          ),
          bodySmall: TextStyle(
            fontFamily: 'Quicksand',
            fontWeight: FontWeight.bold,
            letterSpacing: 0,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Quicksand',
            fontWeight: FontWeight.bold,
            letterSpacing: 0,
          ),
        ),
      ),
      // home: const SuccessScreen(ticketId: "Hiid"),
      home: HomeScreen(),
    );
  }
}
