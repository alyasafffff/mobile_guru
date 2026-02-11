import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_guru/models/jadwal_model.dart';
import 'package:mobile_guru/services/jadwal_services.dart';
import 'package:mobile_guru/services/profile_service.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Pastikan import ini ada
import 'absensi_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- STATE USER ---
  String _namaGuru = "Memuat...";
  String _nipGuru = "-";
  String? _fotoUrl;
  String _totalSesi = "0";
  String _totalSiswa = "0";

  // --- STATE JADWAL (Ganti FutureBuilder dengan List manual) ---
  List<Jadwal> _jadwalList = [];
  bool _isFirstLoad = true; // Untuk loading pertama kali buka aplikasi
  bool _isError = false;

  final JadwalService _jadwalService = JadwalService();
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _initData(); // Load data awal
  }

  // Fungsi gabungan untuk load awal
  void _initData() async {
    _loadUserFromCache(); // Tampil cache dulu biar cepat
    await Future.wait([
      _fetchJadwalData(), // Ambil Jadwal API
      _fetchUserData(),   // Ambil Profil API
    ]);
  }

  // 1. Load User dari Cache (Instant)
  void _loadUserFromCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _namaGuru = prefs.getString('user_name') ?? "Guru";
      _nipGuru = prefs.getString('user_nip') ?? "-";
      _fotoUrl = prefs.getString('user_foto');
    });
  }

  // 2. Fetch User dari API (Background Update)
  Future<void> _fetchUserData() async {
    try {
      final data = await _profileService.getProfileData();
      if (mounted) {
        setState(() {
          _namaGuru = data['nama'];
          _nipGuru = data['nip'];
          _fotoUrl = data['foto_url'];
          _totalSesi = data['stats']['total_sesi'].toString();
          _totalSiswa = data['stats']['total_siswa'].toString();
        });

        // Update Cache
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', _namaGuru);
        await prefs.setString('user_nip', _nipGuru);
        if (_fotoUrl != null) await prefs.setString('user_foto', _fotoUrl!);
      }
    } catch (e) {
      print("Gagal update profil: $e");
    }
  }

  // 3. Fetch Jadwal dari API (Tanpa menghapus list lama saat refresh)
  Future<void> _fetchJadwalData() async {
    try {
      final data = await _jadwalService.getJadwalHariIni();
      if (mounted) {
        setState(() {
          _jadwalList = data;
          _isFirstLoad = false; // Matikan loading tengah
          _isError = false;
        });
      }
    } catch (e) {
      print("Gagal ambil jadwal: $e");
      if (mounted) {
        setState(() {
          _isError = true;
          _isFirstLoad = false;
        });
      }
    }
  }

  // --- LOGIKA ON REFRESH (TARIK KE BAWAH) ---
  Future<void> _onRefresh() async {
    // Panggil kedua fungsi API dan tunggu keduanya selesai
    // List tidak akan hilang (jadi tidak ada loading tengah), hanya loading atas.
    await Future.wait([
      _fetchJadwalData(),
      _fetchUserData(),
    ]);
  }

  // --- LOGIKA MULAI KELAS ---
  void _onMulaiKelas(Jadwal jadwal) async {
    try {
      int jurnalId;
      if (jadwal.statusJurnal == 'proses' && jadwal.jurnalId != null) {
        jurnalId = jadwal.jurnalId!;
      } else {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (c) => const Center(child: CircularProgressIndicator()),
        );
        jurnalId = await _jadwalService.mulaiKelas(jadwal.id);
        if (!mounted) return;
        Navigator.pop(context);
      }

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AbsensiScreen(
            jurnalId: jurnalId,
            namaMapel: jadwal.mapel,
            namaKelas: jadwal.kelas,
          ),
        ),
      );

      _fetchJadwalData(); // Refresh setelah kembali
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Column(
        children: [
          // 1. HEADER (Sudah diedit: Tidak bisa diklik)
          _buildHeader(),

          // 2. KONTEN JADWAL
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh, // Panggil fungsi refresh gabungan
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tanggal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Jadwal Hari Ini",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, d MMM', 'id_ID').format(DateTime.now()),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // LIST JADWAL (Manual Logic pengganti FutureBuilder)
                    if (_isFirstLoad)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 50),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_isError)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 30),
                          child: Text("Gagal memuat jadwal", style: GoogleFonts.poppins()),
                        ),
                      )
                    else if (_jadwalList.isEmpty)
                      _buildEmptyState()
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _jadwalList.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          return _buildJadwalCard(_jadwalList[index]);
                        },
                      ),
                    
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HEADER (FIXED: Tidak bisa diklik) ---
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 50, 24, 30),
      decoration: const BoxDecoration(
        color: Color(0xFF2563EB),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          // Profil Row (HAPUS INKWELL AGAR TIDAK KLIK)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Selamat Pagi,",
                    style: GoogleFonts.poppins(color: Colors.blue[100], fontSize: 12),
                  ),
                  Text(
                    _namaGuru,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[500],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "NIP. $_nipGuru",
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 10),
                    ),
                  )
                ],
              ),
              // FOTO PROFIL
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  image: _fotoUrl != null
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(_fotoUrl!), // Pakai Cached biar smooth
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _fotoUrl == null
                    ? const Icon(Icons.person, color: Colors.white, size: 28)
                    : null,
              )
            ],
          ),

          const SizedBox(height: 24),

          // Statistik Row
          Row(
            children: [
              _buildStatBox("Total Sesi", "$_totalSesi Sesi"),
              const SizedBox(width: 8),
              _buildStatBox("Total Siswa", _totalSiswa),
              const SizedBox(width: 8),
              _buildStatBox("Status", "Aktif", isGreen: true),
            ],
          )
        ],
      ),
    );
  }

  // ... (Sisa Widget: _buildStatBox, _buildJadwalCard, _buildTimeBox, _buildEmptyState SAMA SEPERTI SEBELUMNYA)
  Widget _buildStatBox(String label, String value, {bool isGreen = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label, style: GoogleFonts.poppins(color: Colors.blue[100], fontSize: 10)),
            const SizedBox(height: 2),
            Text(value, style: GoogleFonts.poppins(color: isGreen ? Colors.greenAccent : Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildJadwalCard(Jadwal jadwal) {
    bool isSelesai = jadwal.statusJurnal == 'selesai';
    bool isProses = jadwal.statusJurnal == 'proses';

    if (isSelesai) {
      return Opacity(
        opacity: 0.7,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTimeBox(jadwal.jamMulai, jadwal.jamSelesai, isActive: false),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(jadwal.mapel, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey[800])),
                        Text("${jadwal.kelas}", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(6)),
                    child: Text("SELESAI", style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                  )
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (isProses) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: Colors.blue[600]!, width: 5)),
          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTimeBox(jadwal.jamMulai, jadwal.jamSelesai, isActive: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(jadwal.mapel, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey[900])),
                      Text("${jadwal.kelas} • Lab Komputer", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.circle, color: Colors.green, size: 8),
                        const SizedBox(width: 4),
                        Text("LIVE", style: GoogleFonts.poppins(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _onMulaiKelas(jadwal),
                icon: const Icon(Icons.qr_code_scanner, size: 18, color: Colors.white),
                label: Text("LANJUT MENGAJAR", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            )
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimeBox(jadwal.jamMulai, jadwal.jamSelesai, isActive: false),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(jadwal.mapel, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey[900])),
                    Text("${jadwal.kelas} • Ruang Teori", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(6)),
                child: Text("AKAN DATANG", style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue[600])),
              )
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _onMulaiKelas(jadwal),
              style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.blue.shade200), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: Text("Mulai Kelas", style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue[700])),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTimeBox(String start, String end, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(start.substring(0, 5), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: isActive ? Colors.blue[700] : Colors.grey[800])),
          Text(end.substring(0, 5), style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.event_busy, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text("Tidak ada jadwal hari ini", style: GoogleFonts.poppins(color: Colors.grey)),
        ],
      ),
    );
  }
}