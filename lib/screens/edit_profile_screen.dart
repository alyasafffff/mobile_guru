import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:mobile_guru/config.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Controller
  final TextEditingController _nipController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _hpController = TextEditingController();


  // State
  File? _imageFile;
  String? _fotoUrlServer;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  
  // DEBUG: Munculkan di terminal VS Code
  print("ISI CACHE HP: ${prefs.getString('user_hp')}");

  setState(() {
    _namaController.text = prefs.getString('user_name') ?? "";
    _nipController.text = prefs.getString('user_nip') ?? "";
    _fotoUrlServer = prefs.getString('user_foto');
    
    // Masukkan ke controller
    _hpController.text = prefs.getString('user_hp') ?? "";
  });
}

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85, // Kualitas 85%
      maxWidth: 1000, // Maksimal lebar 1000px (Cukup buat profil)
      maxHeight: 1000, // Maksimal tinggi 1000px
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    try {
      // --- 1. UPLOAD FOTO (Jika Ada) ---
      if (_imageFile != null) {
        print(">> Mulai Upload Foto..."); 
        
        var request = http.MultipartRequest('POST', Uri.parse('${Config.baseUrl}/profile/update-foto'));
        request.headers['Authorization'] = 'Bearer $token';
        request.files.add(await http.MultipartFile.fromPath('foto', _imageFile!.path));
        
        var resFoto = await request.send();
        var respStr = await resFoto.stream.bytesToString(); // Baca respon server
        
        print(">> Status Upload: ${resFoto.statusCode}");
        
        if (resFoto.statusCode == 200) {
           print(">> Upload Berhasil: $respStr");
           var jsonFoto = jsonDecode(respStr);
           await prefs.setString('user_foto', jsonFoto['foto_url']);
        } else {
           // KALAU ERROR, TAMPILKAN DI TERMINAL
           print("!!! ERROR UPLOAD FOTO !!!");
           print(respStr); // <--- Ini pesan panjangnya
           throw Exception("Gagal upload foto (Cek Terminal)");
        }
      }

      // --- 2. UPDATE DATA TEKS ---
      print(">> Mulai Update Data Teks...");
      
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/profile/update-data'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'no_hp': _hpController.text,
          // 'email': _emailController.text,
          // 'alamat': _alamatController.text,
        }),
      );

      print(">> Status Update Data: ${response.statusCode}");

      if (response.statusCode == 200) {
        print(">> Update Data Berhasil: ${response.body}");
        await prefs.setString('user_hp', _hpController.text);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Data berhasil diperbarui!"), 
            backgroundColor: Colors.green
          )
        );
        Navigator.pop(context, true);

      } else {
        // KALAU ERROR, TAMPILKAN DI TERMINAL
        print("!!! ERROR UPDATE DATA !!!");
        print(response.body); // <--- Ini pesan panjangnya (biasanya HTML error Laravel)
        throw Exception("Gagal update data (Cek Terminal)");
      }

    } catch (e) {
      // Error tangkapan terakhir
      print("!!! EXCEPTION !!!");
      print(e.toString()); // Tampilkan error codingan di terminal

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Terjadi kesalahan: ${e.toString().substring(0, 30)}..."), // Tampilkan sedikit aja di HP
          backgroundColor: Colors.red,
        )
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Edit Data Diri",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[100], height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- FOTO PROFIL ---
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.shade100,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                              ),
                            ],
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: _imageFile != null
                                  ? FileImage(_imageFile!) as ImageProvider
                                  : (_fotoUrlServer != null
                                        ? NetworkImage(_fotoUrlServer!)
                                        : const NetworkImage(
                                            "https://ui-avatars.com/api/?name=Guru",
                                          )),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickImage,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB), // Blue-600
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- WARNING BOX (KUNING) ---
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEFCE8), // Yellow-50
                      border: Border.all(
                        color: const Color(0xFFFEF08A),
                      ), // Yellow-200
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lock,
                          color: Color(0xFFCA8A04),
                          size: 18,
                        ), // Yellow-600
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Data Terkunci",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF854D0E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Nama dan NIP dikelola oleh Administrator. Hubungi Tata Usaha jika ada kesalahan.",
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: const Color(0xFFA16207),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- FORM FIELDS ---
                  _buildLabel("NOMOR INDUK PEGAWAI (NIP)"),
                  _buildReadOnlyField(_nipController),
                  const SizedBox(height: 16),

                  _buildLabel("NAMA LENGKAP"),
                  _buildReadOnlyField(_namaController),
                  const SizedBox(height: 24),

                  const Divider(),
                  const SizedBox(height: 24),

                  _buildLabel("NO. WHATSAPP / HP", isBlue: true),
                  _buildEditableField(
                    _hpController,
                    Icons.phone_android,
                    "Contoh: 0812...",
                  ),
                  const SizedBox(height: 4),

                  const SizedBox(height: 20), // Space bawah
                ],
              ),
            ),
          ),

          // --- TOMBOL SIMPAN (FIXED BOTTOM) ---
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
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB), // Blue-600
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save, color: Colors.white, size: 20),
                label: Text(
                  "SIMPAN PERUBAHAN",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildLabel(String text, {bool isBlue = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isBlue ? const Color(0xFF2563EB) : Colors.grey[500],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(TextEditingController controller) {
    return TextField(
      controller: controller,
      readOnly: true,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.grey[600],
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildEditableField(
    TextEditingController controller,
    IconData icon,
    String hint,
  ) {
    return TextField(
      controller: controller,
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[900]),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2563EB)),
        ),
      ),
    );
  }
}
