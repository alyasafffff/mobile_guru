import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_guru/screens/edit_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/profile_service.dart'; // Import Service Baru
import 'login_screen.dart';
import 'change_password_screen.dart';
import 'help_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();

  // State Data
  bool _isLoading = true; // Default Loading
  String _nama = "";
  String _nip = "";
  String _jabatan = "Guru";
  String? _fotoUrl;

  String _totalSesi = "0";
  String _totalSiswa = "0";

  @override
  void initState() {
    super.initState();
    _loadProfile(); // <--- Cukup panggil 1 fungsi ini
  }

  Future<void> _loadProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // ---------------------------------------------------------
    // LANGKAH 1: TAMPILKAN DATA CACHE & MATIKAN LOADING SEGERA
    // ---------------------------------------------------------
    setState(() {
      _nama = prefs.getString('user_name') ?? "Guru";
      _nip = prefs.getString('user_nip') ?? "-";
      _fotoUrl = prefs.getString('user_foto');

      // Ambil statistik dari cache jika ada (opsional, biar gak 0)
      _totalSesi = prefs.getString('stats_sesi') ?? "0";
      _totalSiswa = prefs.getString('stats_siswa') ?? "0";

      // KUNCI KEMENANGAN: Matikan loading SEKARANG!
      // Jangan tunggu API. User langsung lihat data (walau data lama).
      _isLoading = false;
    });

    // ---------------------------------------------------------
    // LANGKAH 2: UPDATE DATA DARI SERVER (BACKGROUND PROCESS)
    // ---------------------------------------------------------
    try {
      final data = await _profileService.getProfileData();

      if (mounted) {
        // Update tampilan dengan data BARU dari server
        setState(() {
          _nama = data['nama'];
          _nip = data['nip'];
          _fotoUrl = data['foto_url'];
          _jabatan = data['role'] ?? "Guru";

          if (data['stats'] != null) {
            _totalSesi = data['stats']['total_sesi'].toString();
            _totalSiswa = data['stats']['total_siswa'].toString();
          }
        });

        // Simpan data BARU ke Cache HP
        await prefs.setString('user_name', _nama);
        await prefs.setString('user_nip', _nip);
        await prefs.setString(
          'user_hp',
          data['no_hp'] ?? "",
        ); // Penting buat edit

        // Simpan Stats ke cache
        await prefs.setString('stats_sesi', _totalSesi);
        await prefs.setString('stats_siswa', _totalSiswa);

        if (_fotoUrl != null) {
          await prefs.setString('user_foto', _fotoUrl!);
        }
      }
    } catch (e) {
      print("Gagal update profil (offline/error): $e");
      // Tidak perlu set isLoading false lagi, karena sudah dimatikan di Langkah 1
      // User tidak akan sadar kalau API gagal, karena data cache sudah tampil.
    }
  }

  // ... (Sisa fungsi logout dan build widget tetap sama) ...

  void _loadFromCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _nama = prefs.getString('user_name') ?? "Guru";
      _nip = prefs.getString('user_nip') ?? "-";
      _fotoUrl = prefs.getString('user_foto');
    });
  }

  void _handleLogout() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi"),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Ya, Keluar",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(
          'Profil Saya',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 1. KARTU PROFIL (DYNAMIC DATA)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              height: 80,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF2563EB),
                                    Color(0xFF60A5FA),
                                  ],
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 30),
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                  ),
                                ],
                                // ...
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: _fotoUrl != null
                                      ? CachedNetworkImageProvider(
                                          _fotoUrl!,
                                        ) // Pakai ini biar nge-cache gambar
                                      : const NetworkImage(
                                              "https://ui-avatars.com/api/?name=Guru",
                                            )
                                            as ImageProvider,
                                ),
                                // ...
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          child: Column(
                            children: [
                              Text(
                                _nama,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                _jabatan,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "NIP. $_nip",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. GRID STATISTIK (DYNAMIC DATA)
                  Row(
                    children: [
                      _buildStatCard(
                        icon: Icons.history_edu,
                        color: Colors.blue,
                        label: "Total Sesi",
                        value: _totalSesi, // <--- Data API
                        unit: "x Tatap Muka",
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        icon: Icons.groups_outlined,
                        color: Colors.purple,
                        label: "Total Siswa",
                        value: _totalSiswa, // <--- Data API
                        unit: "Orang",
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 3. MENU LIST (Static)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.manage_accounts_outlined,
                          title: "Edit Data Diri",
                          subtitle: "Foto Profil dan No. HP",
                          onTap: () async {
                            // 1. Pindah ke halaman Edit dan TUNGGU (await) sampai user kembali
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfileScreen(),
                              ),
                            );

                            // 2. Cek apakah ada perubahan data?
                            // (Di EditProfileScreen tadi kita set Navigator.pop(context, true) kalau sukses simpan)
                            if (result == true) {
                              // 3. Kalau ada perubahan, panggil ulang fungsi load data
                              _loadProfile(); // Pastikan fungsi ini ada di ProfileScreen kamu

                              // Tampilkan pesan kecil biar user tau
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Data profil berhasil diperbarui",
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          icon: Icons.lock_outline,
                          title: "Keamanan akun",
                          subtitle: "Ganti Password",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ChangePasswordScreen(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          icon: Icons.help_outline,
                          title: "Bantuan",
                          subtitle: "Panduan aplikasi & FAQ",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HelpScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 4. TOMBOL LOGOUT
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _handleLogout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEF2F2),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.red.shade100),
                        ),
                      ),
                      icon: Icon(Icons.logout, color: Colors.red[600]),
                      label: Text(
                        "Keluar (Logout)",
                        style: GoogleFonts.poppins(
                          color: Colors.red[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Text(
                    "Versi Aplikasi 1.0.0",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  // --- WIDGET HELPER (Sama seperti sebelumnya) ---
  Widget _buildDivider() =>
      Divider(height: 1, thickness: 1, color: Colors.grey[100]);

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.grey[600], size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.grey[800],
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400]),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[300], size: 20),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required MaterialColor color,
    required String label,
    required String value,
    required String unit,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color[600], size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[500],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const TextSpan(text: " "),
                  TextSpan(
                    text: unit,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
