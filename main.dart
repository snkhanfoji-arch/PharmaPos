import 'package:flutter/material.dart';
import 'database/db_helper.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  // Ensure Flutter engine integrations are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Eagerly trigger SQLite database opening and default seed loading
  await DBHelper.instance.database;

  runApp(const PharmaPOSProApp());
}

class PharmaPOSProApp extends StatelessWidget {
  const PharmaPOSProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PharmaPOS Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          primary: Colors.indigo,
          secondary: Colors.teal,
        ),
        scaffoldBackgroundColor: const Color(0xFFF9FAFC),
        cardTheme: const CardTheme(
          color: Colors.white,
          elevation: 1,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.indigo,
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.indigo),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}
