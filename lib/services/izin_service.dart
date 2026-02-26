import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_guru/screens/izin_riwayat_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../models/siswa_wali_model.dart';
import '../models/riwayat_izin_model.dart';

class IzinService {
  Future<Map<String, String>> _getHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  // 1. AMBIL LIST SISWA
  Future<List<SiswaWali>> getSiswaBinaan() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${Config.baseUrl}/walikelas/siswa'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<dynamic> listJson = data['data'];
      return listJson.map((json) => SiswaWali.fromJson(json)).toList();
    } else {
      throw Exception('Gagal memuat data siswa');
    }
  }

  // 2. KIRIM IZIN (SUDAH DIPERBAIKI)
  // Menambahkan parameter keterangan agar error merah hilang
  Future<bool> kirimIzin({
    required int siswaId,
    required String status,
    required String jenisIzin,
    required String tanggalMulai, // Format YYYY-MM-DD
    required String tanggalSelesai, // Format YYYY-MM-DD
    int? jamKeMulai, // <--- Pastikan pakai tanda tanya (?)
    int? jamKeSelesai,
    String? keterangan, // <--- TAMBAHAN: Parameter Keterangan (Nullable)
  }) async {
    final headers = await _getHeaders();

    final body = {
      'siswa_id': siswaId,
      'status': status,
      'jenis_izin': jenisIzin,
      'tanggal_mulai': tanggalMulai,
      'tanggal_selesai': tanggalSelesai,
      'jam_ke_mulai': jamKeMulai,
      'jam_ke_selesai': jamKeSelesai,
      'keterangan': keterangan, // <--- TAMBAHAN: Masukkan ke body request
    };

    final response = await http.post(
      Uri.parse('${Config.baseUrl}/walikelas/izin'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Gagal mengirim izin');
    }
  }

  // 3. AMBIL RIWAYAT IZIN
  // 3. AMBIL RIWAYAT IZIN
  Future<List<RiwayatIzin>> getRiwayatIzin() async {
    final headers = await _getHeaders();

    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/walikelas/riwayat-izin'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> listJson = data['data'];
        // GANTI RiwayatIzinPage.fromJson MENJADI RiwayatIzin.fromJson
        return listJson.map((json) => RiwayatIzin.fromJson(json)).toList();
      } else {
        throw Exception('Gagal memuat riwayat izin');
      }
    } catch (e) {
      print("Error Service Riwayat: $e");
      throw Exception('Terjadi kesalahan jaringan');
    }
  }
}
