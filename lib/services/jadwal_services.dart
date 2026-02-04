import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/jadwal_model.dart';
import '../models/riwayat_model.dart';
import '../models/presensi_model.dart';

class JadwalService {
  // GANTI IP INI SESUAI IP LAPTOP KAMU (Cek 'ipconfig')
  final String baseUrl = 'http://192.168.1.10:8000/api'; 

  // Helper untuk ambil Token
  Future<Map<String, String>> _getHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  // 1. GET JADWAL HARI INI (Untuk Home)
  Future<List<Jadwal>> getJadwalHariIni() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/jadwal-hari-ini'), headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<dynamic> listJson = data['data'];
      return listJson.map((json) => Jadwal.fromJson(json)).toList();
    } else {
      throw Exception('Gagal memuat jadwal');
    }
  }

  // 2. GET RIWAYAT MENGAJAR (Untuk Tab Riwayat)
  Future<List<Riwayat>> getRiwayat() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/riwayat-mengajar'), headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<dynamic> listJson = data['data'];
      return listJson.map((json) => Riwayat.fromJson(json)).toList();
    } else {
      throw Exception('Gagal memuat riwayat');
    }
  }

  // 3. GET DETAIL SISWA (Untuk Detail Riwayat)
  Future<List<PresensiDetail>> getDetailSiswa(int jurnalId) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/jurnal/$jurnalId/presensi'), headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Cek apakah data dibungkus key 'data' atau langsung array
      List<dynamic> listJson = data['data'] ?? data; 
      return listJson.map((json) => PresensiDetail.fromJson(json)).toList();
    } else {
      throw Exception('Gagal memuat detail siswa');
    }
  }
}