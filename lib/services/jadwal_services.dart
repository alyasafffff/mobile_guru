import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_guru/config.dart'; // Pastikan path ini benar sesuai projectmu
import 'package:shared_preferences/shared_preferences.dart';
import '../models/jadwal_model.dart';
import '../models/riwayat_model.dart'; // Pastikan punya model ini (jika pakai fitur riwayat)
import '../models/presensi_model.dart';

class JadwalService {

  // Helper untuk ambil Token & Header standar
  Future<Map<String, String>> _getHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  // 1. GET JADWAL HARI INI (Home)
  Future<List<Jadwal>> getJadwalHariIni() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('${Config.baseUrl}/jadwal-hari-ini'), headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<dynamic> listJson = data['data'];
      return listJson.map((json) => Jadwal.fromJson(json)).toList();
    } else {
      throw Exception('Gagal memuat jadwal: ${response.statusCode}');
    }
  }

  // 2. GET RIWAYAT MENGAJAR (Tab Riwayat)
  Future<List<Riwayat>> getRiwayat() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('${Config.baseUrl}/riwayat-mengajar'), headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<dynamic> listJson = data['data'];
      return listJson.map((json) => Riwayat.fromJson(json)).toList();
    } else {
      throw Exception('Gagal memuat riwayat');
    }
  }

  // 3. GET DETAIL SISWA (Halaman Absensi)
  Future<List<PresensiDetail>> getDetailSiswa(int jurnalId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${Config.baseUrl}/jurnal/$jurnalId/presensi');
    
    // Debugging (Bisa dihapus kalau sudah release)
    print("Request ke: $url"); 

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        List<dynamic> listJson = data['data']; 
        return listJson.map((json) => PresensiDetail.fromJson(json)).toList();
      } catch (e) {
        print("Error Parsing JSON: $e");
        throw Exception('Error parsing data siswa: $e');
      }
    } else {
      throw Exception('Gagal memuat detail siswa (Code: ${response.statusCode})');
    }
  }

  // 4. MULAI KELAS (POST)
  Future<int> mulaiKelas(int jadwalId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${Config.baseUrl}/mulai-kelas'),
      headers: headers,
      body: jsonEncode({'jadwal_id': jadwalId}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['data']['id']; // Kembalikan ID Jurnal yang baru dibuat
    } else {
      // Tangkap pesan error dari server jika ada
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Gagal memulai kelas');
    }
  }

  // 5. UPDATE ABSENSI & SIMPAN JURNAL (POST) -> INI YANG BERUBAH BANYAK
  Future<void> updatePresensi(
      int jurnalId, 
      String materi, 
      String catatan, // <--- TAMBAHAN PARAMETER BARU
      List<Map<String, dynamic>> listSiswa
  ) async {
    final headers = await _getHeaders();
    
    final response = await http.post(
      Uri.parse('${Config.baseUrl}/jurnal/$jurnalId/update'),
      headers: headers,
      body: jsonEncode({
        'materi': materi,
        'catatan': catatan, // <--- DIKIRIM KE BACKEND
        'siswa': listSiswa,
        'status_guru': 'Hadir',
      }),
    );

    if (response.statusCode != 200) {
      // Jika gagal, lempar exception biar ditangkap UI
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Gagal menyimpan presensi');
    }
  }
}