import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/movie_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rdzkcfkxxtzsqxmyyqxh.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJkemtjZmt4eHR6c3F4bXl5cXhoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxMTc0MTEsImV4cCI6MjA4NzY5MzQxMX0.yv2OU2PoqDNFEe7iSE95gJF3Nyi4bCua-S-dzNwMfmE',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Xelpenic',
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.black,
        brightness: Brightness.dark,
      ),
      home: const AuthGate(),
    );
  }
}

/// ตรวจสอบว่า login หรือยัง
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      return const MovieListScreen();
    } else {
      return const LoginScreen();
    }
  }
}