import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final darkMode = prefs.getBool("darkMode") ?? false;

  runApp(MyApp(isDark: darkMode));
}

class MyApp extends StatefulWidget {
  final bool isDark;

  const MyApp({
    super.key,
    required this.isDark,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool darkMode;

  @override
  void initState() {
    super.initState();
    darkMode = widget.isDark;
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      darkMode = !darkMode;
    });

    await prefs.setBool(
      "darkMode",
      darkMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: darkMode
          ? ThemeData.dark()
          : ThemeData.light(),
      home: HomeScreen(
        onToggleTheme: toggleTheme,
      ),
    );
  }
}