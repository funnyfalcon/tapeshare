import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'features/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase (for Firestore database)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Supabase (for audio file storage)
  await Supabase.initialize(
    url: 'https://mugkjfievdtigzgpbggm.supabase.co',        // ← paste your URL here
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im11Z2tqZmlldmR0aWd6Z3BiZ2dtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExNTczNTksImV4cCI6MjA4NjczMzM1OX0.XE9t2msX-evkdVWXrTeNwbn6E7wV40jRUVadGfJbOW4', // ← paste your anon key here
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TapeShare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}