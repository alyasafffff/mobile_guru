import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_guru/services/jadwal_services.dart';
import '../models/riwayat_model.dart';
import '../models/presensi_model.dart';


class DetailRiwayatScreen extends StatefulWidget {
  final Riwayat riwayat; // Data dikirim dari halaman sebelumnya

  const DetailRiwayatScreen({super.key, required this.riwayat});

  @override
  State<DetailRiwayatScreen> createState() => _DetailRiwayatScreenState();
}

class _DetailRiwayatScreenState extends State<DetailRiwayatScreen> {
  final JadwalService _service = JadwalService();
  late Future<List<PresensiDetail>> _futureSiswa;

  @override
  void initState() {
    super.initState();
    // Ambil data siswa dari API berdasarkan ID Jurnal
    _futureSiswa = _service.getDetailSiswa(widget.riwayat.id);
  }

  // Helper Warna Status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Hadir': return Colors.green;
      case 'Sakit': return Colors.orange;
      case 'Izin': return Colors.blue;
      case 'Alpha': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Detail Pertemuan', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black, // Warna tombol back hitam
      ),
      body: Column(
        children: [
          // INFO HEADER
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.riwayat.tanggal, style: GoogleFonts.poppins(color: Colors.grey)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[50], 
                        borderRadius: BorderRadius.circular(4)
                      ),
                      child: Text(
                        widget.riwayat.kelas, 
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.blue)
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text(widget.riwayat.mapel, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Materi:", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                Text(
                  widget.riwayat.materi,
                  style: GoogleFonts.poppins(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // LIST SISWA
          Expanded(
            child: FutureBuilder<List<PresensiDetail>>(
              future: _futureSiswa,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Data siswa tidak ditemukan"));
                }

                final listSiswa = snapshot.data!;
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: listSiswa.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final siswa = listSiswa[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        child: Text(siswa.namaSiswa[0], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black54)),
                      ),
                      title: Text(siswa.namaSiswa, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(siswa.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _getStatusColor(siswa.status).withOpacity(0.5))
                        ),
                        child: Text(
                          siswa.status, 
                          style: GoogleFonts.poppins(
                            color: _getStatusColor(siswa.status), 
                            fontWeight: FontWeight.bold, 
                            fontSize: 12
                          )
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}