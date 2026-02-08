import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/presensi_model.dart';
import '../services/jadwal_services.dart';

class AbsensiScreen extends StatefulWidget {
  final int jurnalId;
  final String namaMapel;
  final String namaKelas;

  const AbsensiScreen({
    super.key,
    required this.jurnalId,
    required this.namaMapel,
    required this.namaKelas,
  });

  @override
  State<AbsensiScreen> createState() => _AbsensiScreenState();
}

class _AbsensiScreenState extends State<AbsensiScreen> with SingleTickerProviderStateMixin {
  final JadwalService _service = JadwalService();
  
  // Data State
  List<PresensiDetail> _listSiswa = [];
  bool _isLoading = true;
  
  // Controllers
  late TabController _tabController;
  final TextEditingController _materiController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _materiController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  void _loadData() async {
    try {
      final data = await _service.getDetailSiswa(widget.jurnalId);
      setState(() {
        _listSiswa = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --- LOGIKA SCANNER ---
  // --- LOGIKA SCANNER YANG SUDAH DIOPTIMASI ---
  // --- LOGIKA SCANNER TERBARU (FIX ERROR MERAH) ---
  void _bukaScanner() async {
    // 1. Cek Izin Kamera
    var status = await Permission.camera.request();
    if (status.isDenied) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Izin kamera ditolak")));
      return;
    }

    if (!mounted) return;

    // 2. Siapkan Controller
    final MobileScannerController cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates, // Biar gak spam scan
      returnImage: false, 
      torchEnabled: false, 
      autoStart: true,
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text("Scan QR Siswa"), 
            backgroundColor: Colors.black, 
            foregroundColor: Colors.white,
            actions: [
              // TOMBOL SENTER / FLASH (UPDATED)
              ValueListenableBuilder(
                valueListenable: cameraController, // <--- Listen ke Controller langsung
                builder: (context, state, child) {
                  // Ambil status torch dari state
                  final isTorchOn = state.torchState == TorchState.on;
                  return IconButton(
                    icon: Icon(
                      isTorchOn ? Icons.flash_on : Icons.flash_off, 
                      color: isTorchOn ? Colors.yellow : Colors.grey
                    ),
                    onPressed: () => cameraController.toggleTorch(),
                  );
                },
              ),
              // TOMBOL GANTI KAMERA (UPDATED)
              ValueListenableBuilder(
                valueListenable: cameraController, // <--- Listen ke Controller langsung
                builder: (context, state, child) {
                  // Ambil arah kamera dari state
                  final isFront = state.cameraDirection == CameraFacing.front;
                  return IconButton(
                    icon: Icon(isFront ? Icons.camera_front : Icons.camera_rear),
                    onPressed: () => cameraController.switchCamera(),
                  );
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              MobileScanner(
                controller: cameraController,
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      _prosesHasilScan(barcode.rawValue!);
                    }
                  }
                },
              ),
              // OVERLAY KOTAK FOKUS
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.greenAccent, width: 3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const Positioned(
                bottom: 50,
                left: 0, right: 0,
                child: Text(
                  "Arahkan QR Code ke dalam kotak",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 14, backgroundColor: Colors.black54),
                ),
              )
            ],
          ),
        ),
      ),
    );
    
    // Matikan kamera saat kembali agar hemat baterai
    cameraController.dispose();
  }

  void _prosesHasilScan(String code) {
    final index = _listSiswa.indexWhere((siswa) => siswa.qrToken == code);

    if (index != -1) {
      final siswa = _listSiswa[index];

      // Cek Locked
      if (siswa.isLocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⛔ ${siswa.namaSiswa} sedang ${siswa.status} (Dikunci)!"), backgroundColor: Colors.red)
        );
        return;
      }

      if (siswa.status == 'Hadir') return;

      setState(() {
        _listSiswa[index].status = 'Hadir'; 
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ ${siswa.namaSiswa} Hadir!"), backgroundColor: Colors.green, duration: const Duration(seconds: 1))
      );
    } 
  }

  void _simpanAbsensi() async {
    if (_materiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Materi wajib diisi!"), backgroundColor: Colors.red));
      // Pindah ke tab Jurnal otomatis jika lupa isi
      _tabController.animateTo(1); 
      return;
    }
    
    // Siapkan List Data Siswa
    List<Map<String, dynamic>> listData = _listSiswa.map((s) => s.toJson()).toList();

    try {
      // Panggil service dengan parameter TERPISAH (materi, catatan, listData)
      await _service.updatePresensi(
        widget.jurnalId, 
        _materiController.text, 
        _catatanController.text, 
        listData
      );
      
      if(!mounted) return;
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kelas Berhasil Diakhiri!"), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal simpan: $e")));
    }
  }

  // --- HELPER UNTUK HITUNG JUMLAH ---
  int _countStatus(String status) => _listSiswa.where((s) => s.status == status).length;

  @override
  Widget build(BuildContext context) {
    // Hitung total hadir
    int totalHadir = _countStatus('Hadir');
    int totalSiswa = _listSiswa.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Abu-abu terang background
      body: SafeArea(
        child: Column(
          children: [
            // 1. HEADER (Biru)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB), // Blue-600
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.namaMapel, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, height: 1.2)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.people, color: Colors.blueAccent, size: 14), // Icon user agak tricky di bg biru, ganti warna dikit
                                Text(" ${widget.namaKelas} • Live Session", style: GoogleFonts.poppins(color: Colors.blue.shade100, fontSize: 12)),
                              ],
                            )
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: Colors.greenAccent.shade700, borderRadius: BorderRadius.circular(20)),
                        child: const Text("LIVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                      )
                    ],
                  ),
                ],
              ),
            ),

            // 2. TAB BAR (Sticky)
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF2563EB),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF2563EB),
                indicatorWeight: 3,
                labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: "Presensi ($totalHadir/$totalSiswa)"),
                  const Tab(text: "Jurnal Kelas"),
                ],
              ),
            ),

            // 3. ISI KONTEN (TAB VIEW)
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTabPresensi(), // Konten Tab 1
                      _buildTabJurnal(),   // Konten Tab 2
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // === TAB 1: DAFTAR SISWA ===
  Widget _buildTabPresensi() {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // STATISTIK GRID
              Row(
                children: [
                  _buildStatCard("Hadir", _countStatus('Hadir'), Colors.green.shade50, Colors.green.shade700),
                  const SizedBox(width: 8),
                  _buildStatCard("Alpha", _countStatus('Alpha'), Colors.red.shade50, Colors.red.shade700),
                  const SizedBox(width: 8),
                  _buildStatCard("Sakit", _countStatus('Sakit'), Colors.orange.shade50, Colors.orange.shade700),
                  const SizedBox(width: 8),
                  _buildStatCard("Izin", _countStatus('Izin'), Colors.blue.shade50, Colors.blue.shade700),
                ],
              ),
              const SizedBox(height: 16),

              // LIST SISWA
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _listSiswa.length,
                separatorBuilder: (c, i) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final siswa = _listSiswa[index];
                  
                  // Tentukan Warna Border Kiri & Icon
                  Color statusColor = Colors.grey; // Default
                  if (siswa.status == 'Hadir') statusColor = Colors.green;
                  if (siswa.status == 'Alpha') statusColor = Colors.red;
                  if (siswa.status == 'Sakit') statusColor = Colors.orange;
                  if (siswa.status == 'Izin') statusColor = Colors.blue;

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(left: BorderSide(color: statusColor, width: 5)),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // AVATAR
                            CircleAvatar(
                              backgroundColor: Colors.grey.shade200,
                              radius: 20,
                              child: Text(
                                siswa.namaSiswa.isNotEmpty ? siswa.namaSiswa[0] : "?",
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // NAMA & INFO
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(siswa.namaSiswa, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                                  if (siswa.isLocked)
                                    Text("🔒 Izin dari Wali Kelas", style: GoogleFonts.poppins(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.w600))
                                  else if (siswa.status == 'Hadir')
                                    Text("Terverifikasi QR Code", style: GoogleFonts.poppins(fontSize: 10, color: Colors.green))
                                  else
                                    Text("Belum Scan", style: GoogleFonts.poppins(fontSize: 10, color: Colors.red)),
                                ],
                              ),
                            ),

                            // ACTION / STATUS
                            if (siswa.isLocked)
                              // Kalau dikunci, tampilkan text saja
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                child: Text(siswa.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
                              )
                            else if (siswa.status == 'Hadir')
                              // Kalau hadir, tampilkan checklist (gabisa diubah manual)
                              const Icon(Icons.check_circle, color: Colors.green, size: 24)
                            else
                              // Kalau belum, kasih tombol ubah manual (Dropdown mini)
                              SizedBox(
                                height: 30,
                                child: DropdownButton<String>(
                                  value: siswa.status,
                                  underline: const SizedBox(),
                                  icon: const Icon(Icons.edit, size: 16, color: Colors.grey),
                                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.black),
                                  onChanged: (val) {
                                    setState(() => siswa.status = val!);
                                  },
                                  // LOGIKA PENTING:
                                  // "Hadir" hanya muncul jika status siswa == 'Hadir' (sudah scan).
                                  // Jika status != 'Hadir', opsi 'Hadir' TIDAK MUNCUL.
                                  items: [
                                    'Alpha', 'Sakit', 'Izin',
                                    if (siswa.status == 'Hadir') 'Hadir' 
                                  ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                ),
                              )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 80), // Space buat FAB
            ],
          ),
        ),

        // FAB SCANNER
        Positioned(
          bottom: 24,
          right: 0, left: 0,
          child: Center(
            child: InkWell(
              onTap: _bukaScanner,
              child: Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
                ),
                child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
              ),
            ),
          ),
        )
      ],
    );
  }

  // === TAB 2: INPUT JURNAL ===
  Widget _buildTabJurnal() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ALERT WARNING
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB), // Yellow-50
              border: Border.all(color: const Color(0xFFFCD34D)), // Yellow-200
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info, color: Color(0xFFD97706), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Peringatan Smart Alert", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF92400E), fontSize: 12)),
                      Text("Harap isi materi & simpan jurnal agar kehadiran siswa terekam di sistem.", style: GoogleFonts.poppins(color: const Color(0xFFB45309), fontSize: 10)),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // FORM MATERI
          Text("Materi Ajar *", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey[700])),
          const SizedBox(height: 8),
          TextField(
            controller: _materiController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Contoh: Logaritma Dasar dan Sifat-sifatnya...",
              hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.blue)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),

          // FORM CATATAN
          Text("Catatan Tambahan (Opsional)", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey[700])),
          const SizedBox(height: 8),
          TextField(
            controller: _catatanController,
            decoration: InputDecoration(
              hintText: "Misal: Proyektor di kelas ini rusak...",
              hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.blue)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),

          const SizedBox(height: 32),

          // TOMBOL SIMPAN
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _simpanAbsensi,
              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
              label: Text("SIMPAN & AKHIRI KELAS", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A), // Green-600
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 4,
              ),
            ),
          )
        ],
      ),
    );
  }

  // Helper Widget Stat Card
  Widget _buildStatCard(String label, int count, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: textColor.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(label, style: GoogleFonts.poppins(fontSize: 10, color: textColor)),
            Text(count.toString(), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          ],
        ),
      ),
    );
  }
}