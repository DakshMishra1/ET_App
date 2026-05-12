// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const ExpenseTrackerApp());
}

// ── Theme colours (mirrors the web app) ──────────────────────────────────────
const kBg     = Color(0xFF0D1117);
const kBg2    = Color(0xFF161B22);
const kCard   = Color(0xFF1E2736);
const kCard2  = Color(0xFF242F42);
const kGold   = Color(0xFFF0B429);
const kGreen  = Color(0xFF3FB950);
const kRed    = Color(0xFFF85149);
const kBlue   = Color(0xFF58A6FF);
const kPurple = Color(0xFFBC8CFF);
const kTeal   = Color(0xFF39D0D8);
const kMuted  = Color(0xFF8B949E);
const kSubtle = Color(0xFF484F58);

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark();
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: kBg,
        colorScheme: const ColorScheme.dark(
          primary:   kGold,
          surface:   kCard,
          secondary: kBlue,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kBg2,
          elevation: 0,
          iconTheme: IconThemeData(color: kMuted),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
          bodyColor:    Colors.white,
          displayColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const _SplashScreen(),
    );
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => token != null ? const MainScreen() : const AuthScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: kBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_rounded, color: kGold, size: 72),
            SizedBox(height: 20),
            Text(
              'ExpenseTracker',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: kGold,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 8),
            Text('Loading…', style: TextStyle(color: kMuted, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
