import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/presensi_model.dart';

class QRScannerPage extends StatefulWidget {
  final List<PresensiDetail> listSiswa;
  const QRScannerPage({super.key, required this.listSiswa});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.unrestricted,
  );

  // Simpan log nama yang berhasil discan
  List<String> scanLog = [];
  // Simpan log pesan error untuk siswa luar kelas
  List<String> errorLog = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Scanner Presensi", style: GoogleFonts.poppins()),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // 1. KAMERA (Full Screen)
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              for (final barcode in capture.barcodes) {
                if (barcode.rawValue != null) {
                  _handleAttendance(barcode.rawValue!);
                }
              }
            },
          ),

          // 2. OVERLAY KOTAK SCANNER (Static tapi membantu guru membidik)
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // 3. LOG NOTIFIKASI DI BAWAH (Ini yang kamu minta)
          // 3. LOG NOTIFIKASI DI BAWAH
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Notif Merah (Error Salah Kelas)
                ...errorLog
                    .map(
                      (pesan) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.9), // Warna Merah
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              pesan,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),

                // Notif Hijau (Berhasil Hadir)
                ...scanLog.reversed
                    .take(3)
                    .map(
                      (nama) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "$nama Hadir!",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ],
            ),
          ),

          // 4. INSTRUKSI
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Arahkan QR Code ke Kotak Tengah",
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAttendance(String token) {
    final index = widget.listSiswa.indexWhere((s) => s.qrToken == token);

    if (index != -1) {
      final siswa = widget.listSiswa[index];

      if (siswa.status != 'Hadir') {
        setState(() {
          siswa.status = 'Hadir';
          siswa.isLocked = false;
          scanLog.add(siswa.namaSiswa);
        });

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => scanLog.remove(siswa.namaSiswa));
        });
      }
    } else {
      // --- LOGIKA SISWA SALAH KELAS ---
      // Jika token tidak ada di listSiswa kelas ini
      if (!errorLog.contains("Siswa bukan anggota kelas ini!")) {
        setState(() {
          errorLog.add("Siswa bukan anggota kelas ini!");
        });

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted)
            setState(() => errorLog.remove("Siswa bukan anggota kelas ini!"));
        });
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
