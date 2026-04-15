import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_guru/models/jadwal_model.dart';
import 'package:mobile_guru/models/kelas_model.dart';
import 'package:mobile_guru/services/jadwal_services.dart';
import 'absensi_screen.dart';

class PiketScreen extends StatefulWidget {
  const PiketScreen({super.key});

  @override
  State<PiketScreen> createState() => _PiketScreenState();
}

class _PiketScreenState extends State<PiketScreen> {
  final JadwalService _jadwalService = JadwalService();
  bool _isLoading = true;
  List<Jadwal> _jadwalPiket = [];
  List<Kelas> _listKelas = [];
  int? _selectedKelasId;
  String? _selectedKelasNama;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  // Load data awal (Daftar Kelas + Jadwal)
  Future<void> _initData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _jadwalService.getDaftarKelas(),
        _jadwalService.getJadwalPiket(kelasId: _selectedKelasId),
      ]);

      setState(() {
        _listKelas = results[0] as List<Kelas>;
        _jadwalPiket = results[1] as List<Jadwal>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Gagal memuat data: $e", Colors.red);
    }
  }

  // Refresh list saat filter berubah
  Future<void> _fetchJadwalOnly() async {
    setState(() => _isLoading = true);
    try {
      final data = await _jadwalService.getJadwalPiket(
        kelasId: _selectedKelasId,
      );
      setState(() {
        _jadwalPiket = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Gagal memuat jadwal: $e", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  void _onAmbilAlih(Jadwal jadwal) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      final response = await _jadwalService.mulaiKelas(jadwal.id);
      if (!mounted) return;
      Navigator.pop(context);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AbsensiScreen(
            jurnalId: response,
            namaMapel: jadwal.mapel,
            namaKelas: jadwal.kelas,
          ),
        ),
      );
      _fetchJadwalOnly();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnackBar("Gagal ambil alih: $e", Colors.red);
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(
          "Guru Piket",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2563EB),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterKelas(), // <--- Panggil di sini
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchJadwalOnly,
                    color: Colors.orange,
                    child: _jadwalPiket.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                              20,
                              0,
                              20,
                              80,
                            ), // Beri padding bawah agar tidak tertutup nav bar
                            physics:
                                const AlwaysScrollableScrollPhysics(), // Penting agar RefreshIndicator jalan meski list sedikit
                            itemCount: _jadwalPiket.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              return _buildPiketCard(_jadwalPiket[index]);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterKelas() {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled:
              true, // Biar bisa menyesuaikan tinggi jika list banyak
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(context).size.height *
                  0.6, // Maksimal 60% layar
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Pilih Kelas",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    children: [
                      // Pilihan untuk menampilkan semua kelas
                      ListTile(
                        leading: const Icon(Icons.apps, color: Colors.orange),
                        title: Text(
                          "Semua Kelas",
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedKelasId = null;
                            _selectedKelasNama = "Semua Kelas";
                          });
                          Navigator.pop(context);
                          _fetchJadwalOnly(); // Panggil fungsi refresh API
                        },
                      ),
                      // List kelas dari API
                      ..._listKelas
                          .map(
                            (k) => ListTile(
                              leading: const Icon(
                                Icons.door_front_door_outlined,
                                color: Colors.orange,
                              ),
                              title: Text(
                                k.namaKelas,
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedKelasId = k.id;
                                  _selectedKelasNama = k.namaKelas;
                                });
                                Navigator.pop(context);
                                _fetchJadwalOnly(); // Panggil fungsi refresh API
                              },
                            ),
                          )
                          .toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.filter_list, color: Colors.orange, size: 20),
                const SizedBox(width: 12),
                Text(
                  _selectedKelasNama ?? "Filter Berdasarkan Kelas",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: _selectedKelasNama == null
                        ? Colors.grey
                        : Colors.black87,
                    fontWeight: _selectedKelasNama == null
                        ? FontWeight.normal
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // --- CARD YANG DISINKRONKAN DENGAN DASHBOARD ---
  Widget _buildPiketCard(Jadwal jadwal) {
    bool isSelesai = jadwal.statusJurnal == 'selesai';

    // Logika Live: Jika sekarang berada di antara jam mulai dan selesai
    // (Bisa dikirim dari API 'is_now' atau cek manual)
    bool isLive = true; // Untuk testing, kita anggap live jika belum selesai

    if (isSelesai) {
      return Opacity(
        opacity: 0.6,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              _buildTimeBox(
                jadwal.jamMulai,
                jadwal.jamSelesai,
                isActive: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jadwal.mapel,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      "${jadwal.kelas} • Selesai Diabsen",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.check_circle, color: Colors.green),
            ],
          ),
        ),
      );
    }

    // Tampilan Aktif (Orange Theme)
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: Colors.orange[600]!, width: 5)),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                    Text(
                      jadwal.mapel,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey[900],
                      ),
                    ),
                    Text(
                      "${jadwal.kelas} • Guru: ${jadwal.namaGuruAsli ?? '-'}",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _onAmbilAlih(jadwal),
              icon: const Icon(Icons.swap_horiz, size: 18, color: Colors.white),
              label: Text(
                "AMBIL ALIH KELAS",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBox(String start, String end, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive ? Colors.orange[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            start,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isActive ? Colors.orange[700] : Colors.grey[800],
            ),
          ),
          Text(
            end,
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fact_check_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Tidak ada jadwal untuk kelas ini.",
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
