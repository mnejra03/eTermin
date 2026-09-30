import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';

void main() {
  runApp(const ETerminApp());
}

class ETerminApp extends StatelessWidget {
  const ETerminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'eTermin',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9C27B0)),
        useMaterial3: true,
      ),
      onGenerateRoute: (settings) {
        if (settings.name != null && settings.name!.startsWith('/?token=')) {
          return MaterialPageRoute(builder: (_) => const SizedBox.shrink());
        }

        return null;
      },
      home: const WelcomeScreen(),
    );
  }
}
