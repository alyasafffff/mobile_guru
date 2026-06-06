import 'dart:convert';
import 'dart:io'; // TAMBAHKAN INI untuk File
import 'package:http/http.dart' as http;
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
    };
  }

  // 1. AMBIL LIST SISWA (Tetap sama)
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

  // 2. KIRIM IZIN (REVISI PAKAI MULTIPART)
  Future<bool> kirimIzin({
    required int siswaId,
    required String status,
    required String jenisIzin,
    required String tanggalMulai,
    required String tanggalSelesai,
    int? jamKeMulai,
    int? jamKeSelesai,
    String? keterangan,
    File? foto, // <--- TAMBAHAN: Parameter Foto
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    // Gunakan MultipartRequest bukannya http.post
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${Config.baseUrl}/walikelas/izin'),
    );

    // Tambahkan Headers
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    // Tambahkan Fields (Semua harus di-convert ke String)
    request.fields['siswa_id'] = siswaId.toString();
    request.fields['status'] = status;
    request.fields['jenis_izin'] = jenisIzin;
    request.fields['tanggal_mulai'] = tanggalMulai;
    request.fields['tanggal_selesai'] = tanggalSelesai;
    request.fields['keterangan'] = keterangan ?? "";

    if (jamKeMulai != null) {
      request.fields['jam_ke_mulai'] = jamKeMulai.toString();
    }
    if (jamKeSelesai != null) {
      request.fields['jam_ke_selesai'] = jamKeSelesai.toString();
    }

    // Tambahkan File Foto jika ada
    if (foto != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'foto', // Nama field harus sama dengan di Controller Laravel ($request->file('foto'))
          foto.path,
        ),
      );
    }

    // Kirim Request
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return true;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Gagal mengirim izin');
    }
  }

  // 3. AMBIL RIWAYAT IZIN (Tetap sama)
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