import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IzinScreen extends StatelessWidget {
  const IzinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Izin Siswa', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.note_alt_outlined, size: 80, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              'Fitur Wali Kelas',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Disini Anda bisa menginput izin/sakit untuk siswa di kelas Anda sebelum pelajaran dimulai.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}