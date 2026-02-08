import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_guru/models/jadwal_model.dart';
import 'package:mobile_guru/services/jadwal_services.dart';
import 'absensi_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _namaGuru = "Guru";
  String _nipGuru = "-"; // Default NIP
  final JadwalService _jadwalService = JadwalService();
  late Future<List<Jadwal>> _futureJadwal;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null); 
    _loadUser();
    _refreshJadwal();
  }

  void _loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _namaGuru = prefs.getString('user_name') ?? "Budi Santoso";
      _nipGuru = prefs.getString('user_nip') ?? "19820312 200501"; // Contoh jika ada
    });
  }

  void _refreshJadwal() {
    setState(() {
      _futureJadwal = _jadwalService.getJadwalHariIni();
    });
  }

  // --- LOGIKA MULAI KELAS ---
  void _onMulaiKelas(Jadwal jadwal) async {
    try {
      int jurnalId;
      // Cek apakah sudah proses (lanjutkan) atau baru mulai
      if (jadwal.statusJurnal == 'proses' && jadwal.jurnalId != null) {
        jurnalId = jadwal.jurnalId!;
      } else {
        showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
        jurnalId = await _jadwalService.mulaiKelas(jadwal.id);
        if (!mounted) return;
        Navigator.pop(context); // Tutup loading
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

      _refreshJadwal(); // Refresh data setelah kembali dari absen
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Background abu terang
      body: Column(
        children: [
          // 1. HEADER BIRU (Dashboard Style)
          _buildHeader(),

          // 2. KONTEN JADWAL
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _refreshJadwal(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tanggal Hari Ini
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Jadwal Hari Ini", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                        Text(
                          DateFormat('EEEE, d MMM', 'id_ID').format(DateTime.now()), 
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Future Builder List Jadwal
                    FutureBuilder<List<Jadwal>>(
                      future: _futureJadwal,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                        } else if (snapshot.hasError) {
                          return Center(child: Text("Gagal memuat jadwal", style: GoogleFonts.poppins()));
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return _buildEmptyState();
                        }

                        // Kirim data ke widget statistik header (opsional, butuh state management yg lebih kompleks, 
                        // disini kita hardcode statistik atau hitung simpel)
                        
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: snapshot.data!.length,
                          separatorBuilder: (c, i) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final jadwal = snapshot.data![index];
                            return _buildJadwalCard(jadwal);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 80), // Space bawah agar tidak ketutup FAB
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HEADER ---
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 50, 24, 30),
      decoration: const BoxDecoration(
        color: Color(0xFF2563EB), // Blue-600
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))]
      ),
      child: Column(
        children: [
          // Profil Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Selamat Pagi,", style: GoogleFonts.poppins(color: Colors.blue[100], fontSize: 12)),
                  Text(_namaGuru, style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.blue[500], borderRadius: BorderRadius.circular(12)),
                    child: Text("NIP. $_nipGuru", style: GoogleFonts.poppins(color: Colors.white, fontSize: 10)),
                  )
                ],
              ),
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2)
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 28),
              )
            ],
          ),
          const SizedBox(height: 24),
          
          // Statistik Row (Transparent Boxes)
          Row(
            children: [
              _buildStatBox("Total Jam", "6 Jam"), // Bisa didinamiskan nanti
              const SizedBox(width: 8),
              _buildStatBox("Kelas", "3 Kelas"),
              const SizedBox(width: 8),
              _buildStatBox("Status", "Aktif", isGreen: true),
            ],
          )
        ],
      ),
    );
  }

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

  // --- WIDGET CARD JADWAL (ADAPTIF SESUAI STATUS) ---
  Widget _buildJadwalCard(Jadwal jadwal) {
    bool isSelesai = jadwal.statusJurnal == 'selesai';
    bool isProses = jadwal.statusJurnal == 'proses';
    
    // Tampilan jika SELESAI (Abu-abu, Opacity rendah)
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

    // Tampilan jika BERLANGSUNG / PROSES (Card Putih, Border Biru, Shadow, Tombol)
    if (isProses) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: Colors.blue[600]!, width: 5)),
          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
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
                // Indikator Berlangsung
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
                )
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
                  padding: const EdgeInsets.symmetric(vertical: 12)
                ),
              ),
            )
          ],
        ),
      );
    }

    // Tampilan AKAN DATANG (Default)
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
          // Tombol Mulai (Hanya Text Button kecil biar tidak terlalu dominan)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _onMulaiKelas(jadwal),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.blue.shade200),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
              ),
              child: Text("Mulai Kelas", style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue[700])),
            ),
          )
        ],
      ),
    );
  }

  // Widget Kotak Jam (Kiri Card)
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

  // Widget Empty State
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