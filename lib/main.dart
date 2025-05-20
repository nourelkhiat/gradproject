import 'package:flutter/material.dart';
import 'pages/LoginPage.dart'; // Make sure the class inside is named LoginPage
import 'pages/resumescreening.dart'; // File and class name should match

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'REBOTA HR App',
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/resume': (context) => const ResumeScreeningPage(),
      },
    );
  }
}