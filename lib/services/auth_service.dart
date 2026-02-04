import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // GANTI IP INI SESUAI KONDISI:
  // Pakai '10.0.2.2' jika pakai Android Emulator
  // Pakai IP Laptop (misal '192.168.1.5') jika pakai HP Asli (Satu Wifi)
  final String baseUrl = 'http://192.168.0.103:8000/api'; 

  // Fungsi Login
  Future<bool> login(String nip, String password) async {
    final url = Uri.parse('$baseUrl/login');
    
    try {
      final response = await http.post(
        url,
        body: {
          'nip': nip,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Simpan Token & Data User ke HP
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['access_token']);
        await prefs.setString('user_name', data['user']['name']);
        await prefs.setString('user_role', data['user']['role']);
        
        // Cek apakah dia wali kelas?
        bool isWalikelas = data['user']['is_walikelas'] ?? false;
        await prefs.setBool('is_walikelas', isWalikelas);

        if (isWalikelas) {
           await prefs.setInt('kelas_id', data['user']['kelas_id']);
           await prefs.setString('nama_kelas', data['user']['nama_kelas']);
        }

        return true; // Login Sukses
      } else {
        print('Gagal Login: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error Koneksi: $e');
      return false;
    }
  }

  // Fungsi Cek Apakah Sedang Login
  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('token');
  }

  // Fungsi Logout
  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Panggil API Logout disini jika perlu (optional)
    await prefs.clear(); // Hapus semua data di HP
  }
}