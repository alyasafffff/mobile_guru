import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../services/jadwal_services.dart';
import '../models/riwayat_model.dart';
import 'detail_riwayat_screen.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final JadwalService _service = JadwalService();

  // Ganti FutureBuilder dengan manajemen list manual agar refresh lebih mulus
  List<Riwayat> _listRiwayat = [];
  List<Riwayat> _groupRiwayat(List<Riwayat> rawRiwayat) {
    if (rawRiwayat.isEmpty) return [];

    List<Riwayat> grouped = [];

    for (var current in rawRiwayat) {
      if (grouped.isEmpty) {
        grouped.add(current);
      } else {
        var last = grouped.last;

        // Syarat Gabung: Tanggal sama, Mapel sama, Kelas sama, dan Jam Nempel
        if (last.tanggal == current.tanggal &&
            last.namaMapel == current.namaMapel &&
            last.namaKelas == current.namaKelas &&
            last.jamMulai == current.jamSelesai) {
          // Gabungkan: Ambil jam mulai dari yang paling awal (current)
          // karena data Riwayat biasanya di-order DESC (terbaru di atas)
          grouped[grouped.length - 1] = Riwayat(
            id: last.id,
            tanggal: last.tanggal,
            materi: last.materi,
            catatan: last.catatan,
            statusPengisian: last.statusPengisian,
            namaKelas: last.namaKelas,
            namaMapel: last.namaMapel,
            jamMulai:
                current.jamMulai, // Jam mulai ditarik ke jam sesi sebelumnya
            jamSelesai: last.jamSelesai,
            // Statistik TIDAK BOLEH dijumlahkan karena siswanya orang yang sama
            hadir: last.hadir,
            sakit: last.sakit,
            izin: last.izin,
            alpha: last.alpha,
          );
        } else {
          grouped.add(current);
        }
      }
    }
    return grouped;
  }

  bool _isLoading = true;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _fetchRiwayat(); // Ambil data saat pertama kali buka
  }

  // Fungsi ambil data dari API
  Future<void> _fetchRiwayat() async {
    try {
      final data = await _service.getRiwayat();
      if (mounted) {
        setState(() {
          _listRiwayat = _groupRiwayat(data);
          _isLoading = false;
          _isError = false;
        });
      }
    } catch (e) {
      print("Gagal ambil riwayat: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isError = true;
        });
      }
    }
  }

  // Fungsi yang dipanggil saat user Pull to Refresh
  Future<void> _onRefresh() async {
    // Jangan set _isLoading = true di sini agar list lama tetap tampil saat loading tarik
    await _fetchRiwayat();
  }

  String _formatTanggal(String dateString) {
    DateTime date = DateTime.parse(dateString);
    DateTime now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return "Hari Ini, ${DateFormat('d MMM', 'id_ID').format(date)}";
    }
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return "Kemarin, ${DateFormat('d MMM', 'id_ID').format(date)}";
    }
    return DateFormat('EEEE, d MMM yyyy', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    // Hitung Ringkasan
    int totalSesi = _listRiwayat.length;
    int totalSiswaHadir = _listRiwayat.fold(0, (sum, item) => sum + item.hadir);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(
          'Riwayat Mengajar',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2563EB),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      // Gunakan RefreshIndicator membungkus body
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: const Color.fromARGB(255, 139, 139, 139), 
        backgroundColor: const Color.fromARGB(
          255,
          255,
          255,
          255,
        ), 
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              ) // Loading tengah hanya untuk pertama kali
            : _isError
            ? _buildErrorState()
            : _listRiwayat.isEmpty
            ? _buildEmptyState()
            : ListView(
                padding: const EdgeInsets.all(16),
                physics:
                    const AlwaysScrollableScrollPhysics(), // Wajib agar bisa ditarik walau item dikit
                children: [
                  // 1. STATISTIK RINGKAS
                  Row(
                    children: [
                      _buildSummaryCard(
                        icon: Icons.check_circle,
                        iconColor: Colors.blue.shade700,
                        bgColor: Colors.blue.shade50,
                        label: "Total Sesi",
                        value: "$totalSesi Kelas",
                      ),
                      const SizedBox(width: 12),
                      _buildSummaryCard(
                        icon: Icons.groups,
                        iconColor: Colors.green.shade700,
                        bgColor: Colors.green.shade50,
                        label: "Siswa Hadir",
                        value: "$totalSiswaHadir Siswa",
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 2. LIST RIWAYAT
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _listRiwayat.length,
                    itemBuilder: (context, index) {
                      final item = _listRiwayat[index];
                      bool showHeader = true;
                      if (index > 0 &&
                          _listRiwayat[index - 1].tanggal == item.tanggal) {
                        showHeader = false;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showHeader)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: 8,
                                top: 8,
                                left: 4,
                              ),
                              child: Text(
                                _formatTanggal(item.tanggal),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[500],
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          _buildTimelineCard(item),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
      ),
    );
  }

  // WIDGET: Error State
  Widget _buildErrorState() {
    return ListView(
      // Pakai ListView agar bisa di-pull refresh
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        const Center(
          child: Text("Gagal memuat data. Tarik ke bawah untuk coba lagi."),
        ),
      ],
    );
  }

  // WIDGET: Empty State (Diubah jadi ListView agar bisa di-pull refresh)
  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              Icon(Icons.history_toggle_off, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                "Belum ada riwayat mengajar",
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Widget Helper (_buildSummaryCard, _buildTimelineCard, _buildMiniBadge tetap sama seperti kodemu) ---
  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: bgColor.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
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

  Widget _buildTimelineCard(Riwayat item) {
    Color statusColor = item.statusPengisian == 'selesai'
        ? Colors.green
        : Colors.orange;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => DetailRiwayatScreen(riwayat: item)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              Container(
                width: 70,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Colors.grey.shade100),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.jamMulai.substring(0, 5),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      item.jamSelesai.substring(0, 5),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.namaMapel,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              item.statusPengisian == 'selesai'
                                  ? "Selesai"
                                  : "Proses",
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${item.namaKelas} • Materi: ${item.materi}",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildMiniBadge(
                            "H",
                            item.hadir,
                            Colors.grey.shade100,
                            Colors.grey.shade700,
                          ),
                          const SizedBox(width: 4),
                          if (item.sakit > 0) ...[
                            _buildMiniBadge(
                              "S",
                              item.sakit,
                              Colors.orange.shade50,
                              Colors.orange.shade700,
                            ),
                            const SizedBox(width: 4),
                          ],
                          if (item.izin > 0) ...[
                            _buildMiniBadge(
                              "I",
                              item.izin,
                              Colors.blue.shade50,
                              Colors.blue.shade700,
                            ),
                            const SizedBox(width: 4),
                          ],
                          if (item.alpha > 0) ...[
                            _buildMiniBadge(
                              "A",
                              item.alpha,
                              Colors.red.shade50,
                              Colors.red.shade700,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String label, int count, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        "$label: $count",
        style: GoogleFonts.poppins(
          fontSize: 10,
          color: text,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
