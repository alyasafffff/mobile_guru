import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_guru/services/jadwal_services.dart';
import '../models/riwayat_model.dart';
import 'detail_riwayat_screen.dart'; // Pastikan file ini dibuat setelah ini

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final JadwalService _jadwalService = JadwalService();
  late Future<List<Riwayat>> _futureRiwayat;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Fungsi memuat data (dipisah biar bisa dipanggil saat refresh)
  void _loadData() {
    setState(() {
      _futureRiwayat = _jadwalService.getRiwayat();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Background agak abu sedikit biar kontras
      appBar: AppBar(
        title: Text(
          'Riwayat Mengajar',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false, // Hilangkan tombol back default
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        color: Colors.blueAccent,
        child: FutureBuilder<List<Riwayat>>(
          future: _futureRiwayat,
          builder: (context, snapshot) {
            // 1. KONDISI LOADING
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } 
            
            // 2. KONDISI ERROR
            else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      "Gagal memuat data",
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: _loadData,
                      child: const Text("Coba Lagi"),
                    )
                  ],
                ),
              );
            } 
            
            // 3. KONDISI DATA KOSONG
            else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_toggle_off, size: 60, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      "Belum ada riwayat mengajar.",
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            // 4. KONDISI ADA DATA (List View)
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final riwayat = snapshot.data![index];
                return _buildRiwayatCard(riwayat);
              },
            );
          },
        ),
      ),
    );
  }

  // WIDGET KARTU RIWAYAT
  Widget _buildRiwayatCard(Riwayat item) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigasi ke Halaman Detail
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailRiwayatScreen(riwayat: item),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BARIS 1: Tanggal & Jam
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        item.tanggal, // Contoh: 2026-02-04
                        style: GoogleFonts.poppins(
                          fontSize: 12, 
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade300)
                    ),
                    child: Text(
                      item.jam, // Contoh: 07:00 - 08:20
                      style: GoogleFonts.poppins(
                        fontSize: 11, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.black54
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // BARIS 2: Kelas & Mapel
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.kelas,
                      style: GoogleFonts.poppins(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.mapel,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // BARIS 3: Materi
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Materi Pembelajaran:",
                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.materi.isEmpty ? "-" : item.materi,
                    style: GoogleFonts.poppins(
                      fontSize: 13, 
                      color: Colors.black87,
                      fontStyle: item.materi.isEmpty ? FontStyle.italic : FontStyle.normal
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}