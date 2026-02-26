import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/izin_service.dart';
import '../models/riwayat_izin_model.dart';

class RiwayatIzinPage extends StatefulWidget {
  const RiwayatIzinPage({super.key});

  @override
  State<RiwayatIzinPage> createState() => _RiwayatIzinPageState();
}

class _RiwayatIzinPageState extends State<RiwayatIzinPage> {
  final IzinService _service = IzinService();
  List<RiwayatIzin> _listRiwayat = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRiwayat();
  }

  // Pastikan ada Future<void> agar RefreshIndicator tahu kapan loading selesai
  Future<void> _fetchRiwayat() async {
    try {
      final data = await _service.getRiwayatIzin();
      if (mounted) {
        setState(() {
          _listRiwayat = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memperbarui data: $e"))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchRiwayat,
      color: const Color.fromARGB(255, 139, 139, 139), // Warna panah putar
      backgroundColor: const Color.fromARGB(255, 255, 255, 255), // Warna lingkaran background (biru)
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _listRiwayat.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  // physics ini PENTING agar layar bisa ditarik meski data sedikit
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: _listRiwayat.length,
                  itemBuilder: (context, index) {
                    final item = _listRiwayat[index];
                    
                    // Logika Header Tanggal (Grouping)
                    bool showHeader = true;
                    if (index > 0 && _listRiwayat[index - 1].tanggalMulai == item.tanggalMulai) {
                      showHeader = false;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showHeader) _buildDateHeader(item.tanggalMulai),
                        _buildIzinCard(item),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _buildDateHeader(String tanggal) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
      child: Text(
        DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.parse(tanggal)),
        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildIzinCard(RiwayatIzin item) {
    Color statusColor = item.status == 'Sakit' ? Colors.orange : Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(item.status == 'Sakit' ? Icons.medical_services_outlined : Icons.info_outline, color: statusColor, size: 24),
        ),
        title: Text(item.namaSiswa, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.jenisIzin == 'full' ? "Izin Seharian" : "Jam ke-${item.jamKeMulai} s/d ${item.jamKeSelesai}",
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
            if (item.keterangan != null && item.keterangan!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text("\"${item.keterangan}\"", style: GoogleFonts.poppins(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey[400])),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8)),
          child: Text(item.status, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Belum ada riwayat izin siswa", style: GoogleFonts.poppins(color: Colors.grey)),
        ],
      ),
    );
  }
}