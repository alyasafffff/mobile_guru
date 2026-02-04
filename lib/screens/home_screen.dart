import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Jangan lupa: flutter pub add intl
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile_guru/models/jadwal_model.dart';
import 'package:mobile_guru/services/jadwal_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _namaGuru = "";
  final JadwalService _jadwalService = JadwalService();
  late Future<List<Jadwal>> _futureJadwal;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null); // Set format tanggal Indo
    _loadUser();
    _futureJadwal = _jadwalService.getJadwalHariIni();
  }

  void _loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _namaGuru = prefs.getString('user_name') ?? "Bapak/Ibu Guru";
    });
  }

  @override
  Widget build(BuildContext context) {
    String hariIni = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        toolbarHeight: 0, // Sembunyikan AppBar default
        elevation: 0,
      ),
      body: Column(
        children: [
          // HEADER DASHBOARD
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Selamat Datang,", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Text(_namaGuru, style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(hariIni, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              ],
            ),
          ),

          // JUDUL SECTION
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Jadwal Hari Ini", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),

          // LIST JADWAL
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _futureJadwal = _jadwalService.getJadwalHariIni();
                });
              },
              child: FutureBuilder<List<Jadwal>>(
                future: _futureJadwal,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error koneksi"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.event_busy, size: 60, color: Colors.grey),
                          const SizedBox(height: 10),
                          Text("Tidak ada jadwal mengajar hari ini.", style: GoogleFonts.poppins(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return _buildJadwalCard(snapshot.data![index]);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJadwalCard(Jadwal jadwal) {
    // ... Gunakan kode card jadwal yang sudah saya berikan sebelumnya di step sebelumnya ...
    // (Copy paste widget _buildJadwalCard dari jawaban sebelumnya kesini)
    // Pastikan tombol "Mulai" tetap ada logikanya
    return Card(
       // ... isi card jadwal ...
       child: Padding(
         padding: const EdgeInsets.all(16.0),
         child: Column(
           children: [
             Text(jadwal.mapel), // Contoh simpel
             // Tombol Mulai Kelas
             ElevatedButton(onPressed: (){}, child: Text("Mulai"))
           ]
         )
       )
    );
  }
}