import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // FIXED: Remove complex builder that breaks Material context
     theme: ThemeData(
  visualDensity: VisualDensity.standard,
  useMaterial3: true,

  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,

    border: OutlineInputBorder(),

    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: Colors.grey,
      ),
    ),

    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: Color(0xff06275B),
        width: 2,
      ),
    ),
  ),
),

      // HOME must be a Scaffold under MaterialApp
      home: const SplashScreen(),
    );
  }
}