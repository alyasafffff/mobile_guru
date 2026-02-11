import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class ProfileService {
  
  // Ambil Data Profil Lengkap dari API
  Future<Map<String, dynamic>> getProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('${Config.baseUrl}/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data']; // Mengembalikan Map data user + stats
    } else {
      throw Exception('Gagal memuat profil');
    }
  }
}