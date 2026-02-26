import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_guru/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // UBAH TIPE RETURN JADI Future<String?>
  // return null = Sukses
  // return "Teks..." = Gagal (Isinya pesan error dari server)
  Future<String?> login(String nip, String password) async {
    final url = Uri.parse('${Config.baseUrl}/login');
    
    try {
      final response = await http.post(
        url,
        body: {
          'nip': nip,
          'password': password,
        },
        headers: {
          'Accept': 'application/json', 
        }
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // --- SUKSES ---
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['access_token']);
        await prefs.setString('user_name', data['user']['name']);
        await prefs.setString('user_role', data['user']['role']);
        await prefs.setString('user_hp', data['user']['no_hp'] ?? "");
        
        bool isWalikelas = data['user']['is_walikelas'] ?? false;
        await prefs.setBool('is_walikelas', isWalikelas);

        if (isWalikelas) {
           await prefs.setInt('kelas_id', data['user']['kelas_id']);
           await prefs.setString('nama_kelas', data['user']['nama_kelas']);
        }

        return null; // null artinya TIDAK ADA ERROR (Berhasil)
      } else {
        // --- GAGAL ---
        // Ambil pesan dari Laravel ("Akses Ditolak..." atau "NIP salah...")
        return data['message'] ?? 'Login Gagal';
      }
    } catch (e) {
      return 'Kesalahan Koneksi: $e';
    }
  }

  // ... fungsi logout dan isLoggedIn tetap sama ...
  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('token');
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
  }
}