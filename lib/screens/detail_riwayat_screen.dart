import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_guru/services/jadwal_services.dart';
import '../models/riwayat_model.dart';
import '../models/presensi_model.dart';

class DetailRiwayatScreen extends StatefulWidget {
  final Riwayat riwayat;

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
    _futureSiswa = _service.getDetailSiswa(widget.riwayat.id);
  }

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
    // Format Jam (ambil 5 karakter pertama: 07:00:00 -> 07:00)
    String jamMulai = widget.riwayat.jamMulai.substring(0, 5);
    String jamSelesai = widget.riwayat.jamSelesai.substring(0, 5);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Laporan Kelas', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // 1. HEADER INFORMASI (Warna Abu Lembut)
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris 1: Tanggal & Jam
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(widget.riwayat.tanggal, style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 12)),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text("$jamMulai - $jamSelesai", style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Baris 2: Mapel & Kelas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.riwayat.namaMapel, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue.shade100)
                      ),
                      child: Text(
                        widget.riwayat.namaKelas, 
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.blue.shade700, fontSize: 12)
                      ),
                    )
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Baris 3: Materi & Catatan
                Text("Materi Ajar:", style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
                Text(
                  widget.riwayat.materi, 
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                ),
                
                // Tampilkan Catatan HANYA JIKA ADA
                if (widget.riwayat.catatan != null && widget.riwayat.catatan!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200)
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.note, size: 14, color: Colors.orange.shade800),
                            const SizedBox(width: 6),
                            Text("Catatan:", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.riwayat.catatan!, 
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87)
                        ),
                      ],
                    ),
                  )
                ],
              ],
            ),
          ),

          // 2. DAFTAR KEHADIRAN SISWA
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
                return Column(
                  children: [
                    // Judul Kecil List
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.grey[100],
                      child: Text("Daftar Kehadiran Siswa (${listSiswa.length})", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                    ),
                    
                    // Listview
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: listSiswa.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final siswa = listSiswa[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey[200],
                              child: Text(
                                siswa.namaSiswa.isNotEmpty ? siswa.namaSiswa[0] : "?", 
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black54)
                              ),
                            ),
                            title: Text(siswa.namaSiswa, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(siswa.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
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
                      ),
                    ),
                  ],
                );
              },
            ),
          )
        ],
      ),
    );
  }
}