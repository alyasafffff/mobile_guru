import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'izin_form_page.dart';
import 'izin_riwayat_page.dart';

class IzinTabController extends StatelessWidget {
  const IzinTabController({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        // Gunakan AppBar asli agar Status Bar otomatis Biru
        appBar: AppBar(
          title: Text(
            "Pusat Izin Siswa",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF2563EB),
          elevation: 0, // Hilangkan bayangan agar menyatu dengan TabBar nanti
          
        ),
        body: Column(
          children: [
            // TAB BAR (Putih) ditaruh di dalam Column body
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                ],
              ),
              child: TabBar(
                labelColor: const Color(0xFF2563EB),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF2563EB),
                indicatorWeight: 3,
                labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [
                  Tab(text: "Formulir"),
                  Tab(text: "Riwayat"),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  IzinFormPage(),
                  RiwayatIzinPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}