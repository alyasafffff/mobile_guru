import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_guru/screens/main_layout.dart';
import '../services/auth_service.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nipController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  // Di dalam class _LoginScreenState ...

  void _handleLogin() async {
  // 1. VALIDASI FORM KOSONG DI SISI MOBILE
  if (_nipController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('NIP dan Password wajib diisi!'),
        backgroundColor: Colors.orange, // Menggunakan warna orange sebagai penanda warning validasi
      ),
    );
    return; // Hentikan proses, jangan kirim ke server
  }

  // 2. JIKA AMAN, LANJUTKAN PROSES LOGIN KE SERVER
  setState(() => _isLoading = true);

  String? errorMessage = await _authService.login(
    _nipController.text,
    _passwordController.text,
  );

  setState(() => _isLoading = false);

  if (errorMessage == null) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainLayout()),
    );
  } else {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Image(
                image: AssetImage('assets/images/logo.png'),
                height: 100,
              ),
              const SizedBox(height: 16),
              Text(
                'SIMONS',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sistem Informasi Monitoring Sekolah',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              
              // INPUT NIP
              TextField(
                controller: _nipController,
                decoration: InputDecoration(
                  labelText: 'NIP',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              
              // INPUT PASSWORD
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 24),
              
              // TOMBOL LOGIN
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'MASUK',
                        style: GoogleFonts.poppins(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}