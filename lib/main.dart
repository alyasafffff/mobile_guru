import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Sesuaikan import ini dengan struktur folder kamu
import 'screens/login_screen.dart'; 
import 'screens/main_layout.dart'; // ATAU MainScreen jika kamu pakai Bottom Navigation Bar

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart School',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      // Jadikan SplashScreen sebagai halaman pertama yang dibuka
      home: const SplashScreen(), 
    );
  }
}

// --- WIDGET SATPAM (SPLASH SCREEN) ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // Jalankan pengecekan saat aplikasi dibuka
  }

  Future<void> _checkLoginStatus() async {
    // Beri jeda 2 detik biar logo aplikasi terlihat (Animasi Splash)
    await Future.delayed(const Duration(seconds: 2));

    // Buka memori HP
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Cek apakah ada token yang tersimpan?
    String? token = prefs.getString('token');

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      // JIKA PUNYA TOKEN -> Langsung lompat ke HomeScreen
      // Ganti HomeScreen() dengan MainScreen() jika kamu pakai Bottom Nav Bar
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainLayout()), 
      );
    } else {
      // JIKA TIDAK PUNYA TOKEN -> Lempar ke LoginScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2563EB), // Warna Biru Khas Aplikasi Kamu
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ganti icon ini dengan Logo Sekolah kamu kalau ada
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)
                ]
              ),
              child: const Icon(Icons.school, size: 60, color: Color(0xFF2563EB)),
            ),
            const SizedBox(height: 24),
            Text("Smart School", style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            Text("Aplikasi Presensi Guru", style: GoogleFonts.poppins(fontSize: 14, color: Colors.blue[100])),
            const SizedBox(height: 40),
            // Animasi Loading
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}