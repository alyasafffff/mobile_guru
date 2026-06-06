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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal memperbarui data: $e")));
      }
    }
  }

  // Fungsi untuk menampilkan foto secara Full Screen saat diklik
  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchRiwayat,
      color: const Color.fromARGB(255, 139, 139, 139),
      backgroundColor: Colors.white,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _listRiwayat.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _listRiwayat.length,
              itemBuilder: (context, index) {
                final item = _listRiwayat[index];
                bool showHeader = true;
                if (index > 0 &&
                    _listRiwayat[index - 1].tanggalMulai == item.tanggalMulai) {
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
        DateFormat(
          'EEEE, d MMMM yyyy',
          'id_ID',
        ).format(DateTime.parse(tanggal)),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.status == 'Sakit'
                        ? Icons.medical_services_outlined
                        : Icons.info_outline,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.namaSiswa,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // TAMPILKAN RENTANG TANGGAL DI SINI
                      Text(
                        _formatDateRange(
                          item.tanggalMulai,
                          item.tanggalSelesai,
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                      Text(
                        item.jenisIzin == 'full'
                            ? "Izin Seharian"
                            : "Sesi: Jam ke-${item.jamKeMulai} s/d ${item.jamKeSelesai}",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // Tampilkan Keterangan jika ada
            if (item.keterangan != null && item.keterangan!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                "\"${item.keterangan}\"",
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[500],
                ),
              ),
            ],

            // Tampilkan Foto jika ada
            if (item.urlFoto != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => _showFullImage(item.urlFoto!),
                  child: Stack(
                    children: [
                      Image.network(
                        item.urlFoto!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 150,
                          width: double.infinity,
                          color: Colors.grey[100],
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      // Overlay label "Lihat Bukti"
                      Positioned(
                        bottom: 0,
                        right: 0,
                        left: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          color: Colors.black45,
                          child: const Text(
                            "Klik untuk memperbesar",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
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
          Text(
            "Belum ada riwayat izin siswa",
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _formatDateRange(String start, String end) {
    DateTime dtStart = DateTime.parse(start);
    DateTime dtEnd = DateTime.parse(end);

    var formatter = DateFormat('d MMM yyyy', 'id_ID');

    if (start == end) {
      return formatter.format(dtStart); // Jika cuma 1 hari
    } else {
      return "${formatter.format(dtStart)} s/d ${formatter.format(dtEnd)}"; // Jika rentang
    }
  }
}
