import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Wajib: flutter pub add intl
import 'package:intl/date_symbol_data_local.dart';
import '../services/jadwal_services.dart';
import '../models/riwayat_model.dart';
import 'detail_riwayat_screen.dart'; // Pastikan import halaman detail yg km buat di awal

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final JadwalService _service = JadwalService();
  late Future<List<Riwayat>> _futureRiwayat;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _futureRiwayat = _service.getRiwayat();
  }

  // Fungsi Refresh Tarik ke Bawah
  Future<void> _refreshData() async {
    setState(() {
      _futureRiwayat = _service.getRiwayat();
    });
  }

  // Helper Format Tanggal (Contoh: Senin, 24 Okt)
  String _formatTanggal(String dateString) {
    DateTime date = DateTime.parse(dateString);
    DateTime now = DateTime.now();
    
    // Cek Hari Ini / Kemarin
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return "Hari Ini, ${DateFormat('d MMM', 'id_ID').format(date)}";
    }
    if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      return "Kemarin, ${DateFormat('d MMM', 'id_ID').format(date)}";
    }
    
    return DateFormat('EEEE, d MMM yyyy', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text('Riwayat Mengajar', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF2563EB),
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false, // Hilangkan back button kalau ini di navbar
      ),
      body: FutureBuilder<List<Riwayat>>(
        future: _futureRiwayat,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final List<Riwayat> data = snapshot.data!;
          
          // Hitung Ringkasan untuk Header
          int totalSesi = data.length;
          int totalSiswaHadir = data.fold(0, (sum, item) => sum + item.hadir);

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. STATISTIK RINGKAS
                Row(
                  children: [
                    _buildSummaryCard(
                      icon: Icons.check_circle, 
                      iconColor: Colors.blue.shade700, 
                      bgColor: Colors.blue.shade50, 
                      label: "Total Sesi", 
                      value: "$totalSesi Kelas"
                    ),
                    const SizedBox(width: 12),
                    _buildSummaryCard(
                      icon: Icons.groups, 
                      iconColor: Colors.green.shade700, 
                      bgColor: Colors.green.shade50, 
                      label: "Siswa Hadir", 
                      value: "$totalSiswaHadir Siswa"
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. LIST RIWAYAT
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final item = data[index];
                    
                    // Cek apakah tanggal ini sama dengan sebelumnya (Grouping Logic)
                    bool showHeader = true;
                    if (index > 0 && data[index - 1].tanggal == item.tanggal) {
                      showHeader = false;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showHeader) 
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, top: 8, left: 4),
                            child: Text(
                              _formatTanggal(item.tanggal),
                              style: GoogleFonts.poppins(
                                fontSize: 12, 
                                fontWeight: FontWeight.bold, 
                                color: Colors.grey[500],
                                letterSpacing: 1
                              ),
                            ),
                          ),
                        _buildTimelineCard(item),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 80), // Padding bawah
              ],
            ),
          );
        },
      ),
    );
  }

  // WIDGET: Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Belum ada riwayat mengajar", style: GoogleFonts.poppins(color: Colors.grey)),
        ],
      ),
    );
  }

  // WIDGET: Kartu Ringkasan Atas
  Widget _buildSummaryCard({required IconData icon, required Color iconColor, required Color bgColor, required String label, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: bgColor.withOpacity(0.5)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))]
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
                  Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                  Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // WIDGET: Kartu Utama (Timeline Style)
  Widget _buildTimelineCard(Riwayat item) {
    // Tentukan warna garis samping berdasarkan status
    // Jika masih proses (lupa diakhiri) warnanya Orange, kalau Selesai Hijau
    Color statusColor = item.statusPengisian == 'selesai' ? Colors.green : Colors.orange;

    return GestureDetector(
      onTap: () {
        // Navigasi ke Detail (Menggunakan halaman yg km buat di awal)
        Navigator.push(context, MaterialPageRoute(builder: (c) => DetailRiwayatScreen(riwayat: item)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: IntrinsicHeight( // Supaya garis samping tingginya ngikutin konten
          child: Row(
            children: [
              // 1. Garis Warna Indikator
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                ),
              ),
              
              // 2. Jam (Kiri)
              Container(
                width: 70,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: Colors.grey.shade100))
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.jamMulai.substring(0, 5), style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                    Text(item.jamSelesai.substring(0, 5), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
              ),

              // 3. Konten (Kanan)
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
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              item.statusPengisian == 'selesai' ? "Selesai" : "Proses",
                              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${item.namaKelas} • Materi: ${item.materi}", 
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis
                      ),
                      const SizedBox(height: 8),
                      
                      // Badge Jumlah Siswa (H, S, I, A)
                      Row(
                        children: [
                          _buildMiniBadge("H", item.hadir, Colors.grey.shade100, Colors.grey.shade700),
                          const SizedBox(width: 4),
                          if (item.sakit > 0) ...[
                            _buildMiniBadge("S", item.sakit, Colors.orange.shade50, Colors.orange.shade700),
                            const SizedBox(width: 4),
                          ],
                          if (item.izin > 0) ...[
                            _buildMiniBadge("I", item.izin, Colors.blue.shade50, Colors.blue.shade700),
                            const SizedBox(width: 4),
                          ],
                          if (item.alpha > 0) ...[
                            _buildMiniBadge("A", item.alpha, Colors.red.shade50, Colors.red.shade700),
                          ],
                        ],
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Helper Badge Kecil (H: 28)
  Widget _buildMiniBadge(String label, int count, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text("$label: $count", style: GoogleFonts.poppins(fontSize: 10, color: text, fontWeight: FontWeight.w600)),
    );
  }
}