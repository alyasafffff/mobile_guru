import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  // Controller
  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  // Visibility Toggles
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Validation State
  bool _hasMinLength = false;
  bool _hasNumber = false;
  bool _isMatch = false;
  bool _isLoading = false;

  // Fungsi Cek Kekuatan Password (Real-time)
  void _checkStrength(String value) {
    setState(() {
      _hasMinLength = value.length >= 8;
      _hasNumber = RegExp(r'\d').hasMatch(value); // Cek apakah ada angka
      _checkMatch(); // Cek ulang kecocokan
    });
  }

  // Fungsi Cek Kecocokan Password
  void _checkMatch() {
    setState(() {
      _isMatch = _newPassController.text == _confirmPassController.text && 
                 _newPassController.text.isNotEmpty;
    });
  }

  // Fungsi Submit ke Server
  Future<void> _updatePassword() async {
    setState(() => _isLoading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/profile/change-password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'current_password': _currentPassController.text,
          'new_password': _newPassController.text,
          'new_password_confirmation': _confirmPassController.text,
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;
        // SUKSES
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [Icon(Icons.lock, color: Colors.white), SizedBox(width: 10), Text("Password berhasil diubah!")]),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          )
        );
        Navigator.pop(context); // Kembali ke profil
      } else {
        // GAGAL (Validasi Laravel / Salah Password Lama)
        String errorMsg = body['message'] ?? "Gagal mengganti password";
        if(body['errors'] != null) {
           errorMsg = body['errors'].values.first[0]; // Ambil error pertama
        }
        throw Exception(errorMsg);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red)
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Helper untuk Tombol "Aktif/Tidak"
  bool get _isFormValid {
    return _hasMinLength && _hasNumber && _isMatch && _currentPassController.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Keamanan Akun", style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: Colors.grey[100], height: 1)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // --- HERO ICON ---
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
                    child: const Icon(Icons.security, size: 40, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(height: 16),
                  Text("Ganti Password", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                  const SizedBox(height: 8),
                  Text("Buat password yang kuat untuk mengamankan akun dan data presensi Anda.", 
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])
                  ),
                  const SizedBox(height: 32),

                  // --- FORM ---
                  _buildInputLabel("Password Saat Ini"),
                  _buildPasswordField(_currentPassController, "Masukkan password lama", _obscureCurrent, () {
                    setState(() => _obscureCurrent = !_obscureCurrent);
                  }),
                  
                  const SizedBox(height: 20),

                  _buildInputLabel("Password Baru"),
                  _buildPasswordField(_newPassController, "Minimal 8 karakter", _obscureNew, () {
                    setState(() => _obscureNew = !_obscureNew);
                  }, onChanged: _checkStrength),
                  
                  // Validasi Rules
                  const SizedBox(height: 8),
                  _buildValidationRule("Minimal 8 karakter", _hasMinLength),
                  _buildValidationRule("Mengandung angka", _hasNumber),

                  const SizedBox(height: 20),

                  _buildInputLabel("Ulangi Password Baru"),
                  _buildPasswordField(_confirmPassController, "Ketik ulang password baru", _obscureConfirm, () {
                    setState(() => _obscureConfirm = !_obscureConfirm);
                  }, onChanged: (val) => _checkMatch()),
                  
                  // Error Text Kecocokan
                  if (_confirmPassController.text.isNotEmpty && !_isMatch)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 14, color: Colors.red),
                          const SizedBox(width: 4),
                          Text("Password tidak cocok!", style: GoogleFonts.poppins(fontSize: 11, color: Colors.red)),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Silakan hubungi Administrator Sekolah.")));
                      },
                      child: Text("Lupa Password Lama?", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // --- TOMBOL SAVE (FIXED BOTTOM) ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: (_isFormValid && !_isLoading) ? _updatePassword : null,
                style: ElevatedButton.styleFrom(
                  // Jika Valid: Biru, Jika Tidak: Abu-abu
                  backgroundColor: _isFormValid ? const Color(0xFF2563EB) : Colors.grey[300],
                  foregroundColor: Colors.white,
                  elevation: _isFormValid ? 2 : 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle_outline, size: 20),
                label: Text("UPDATE PASSWORD", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700])),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String hint, bool isObscure, VoidCallback onToggle, {Function(String)? onChanged}) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      onChanged: onChanged,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2563EB))),
        suffixIcon: IconButton(
          icon: Icon(isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey[400]),
          onPressed: onToggle,
        ),
      ),
    );
  }

  Widget _buildValidationRule(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 4),
      child: Row(
        children: [
          Icon(isValid ? Icons.check_circle : Icons.circle, size: 12, 
            color: isValid ? Colors.green : Colors.grey[400]),
          const SizedBox(width: 8),
          Text(text, style: GoogleFonts.poppins(fontSize: 11, 
            color: isValid ? Colors.green : Colors.grey[400])),
        ],
      ),
    );
  }
}