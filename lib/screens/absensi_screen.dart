import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/presensi_model.dart';
import '../services/jadwal_services.dart';
import 'qr_scanner_page.dart';

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

class _AbsensiScreenState extends State<AbsensiScreen>
    with SingleTickerProviderStateMixin {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _bukaScanner() async {
    var status = await Permission.camera.request();
    if (status.isDenied) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Izin kamera ditolak")));
      return;
    }

    if (!mounted) return;

    // Panggil QRScannerPage dan kirim list siswa
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerPage(listSiswa: _listSiswa),
      ),
    );

    // KUNCI: Setelah kembali dari scanner, cukup panggil setState.
    // JANGAN panggil _loadData() lagi di sini agar data 'Hadir' hasil scan tidak tertimpa data lama dari database.
    if (mounted) {
      setState(() {});
    }
  }

  void _simpanAbsensi() async {
    if (_materiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Materi wajib diisi!"),
          backgroundColor: Colors.red,
        ),
      );
      _tabController.animateTo(1);
      return;
    }

    List<Map<String, dynamic>> listData = _listSiswa
        .map((s) => s.toJson())
        .toList();

    try {
      await _service.updatePresensi(
        widget.jurnalId,
        _materiController.text,
        _catatanController.text,
        listData,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kelas Berhasil Diakhiri!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal simpan: $e")));
    }
  }

  int _countStatus(String status) =>
      _listSiswa.where((s) => s.status == status).length;

  @override
  Widget build(BuildContext context) {
    int totalHadir = _countStatus('Hadir');
    int totalSiswa = _listSiswa.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.namaMapel,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${widget.namaKelas} • Live Session",
                          style: GoogleFonts.poppins(
                            color: Colors.blue.shade100,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // TAB BAR
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF2563EB),
                indicatorColor: const Color(0xFF2563EB),
                tabs: [
                  Tab(text: "Presensi ($totalHadir/$totalSiswa)"),
                  const Tab(text: "Jurnal Kelas"),
                ],
              ),
            ),

            // CONTENT
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [_buildTabPresensi(), _buildTabJurnal()],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPresensi() {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  _buildStatCard(
                    "Hadir",
                    _countStatus('Hadir'),
                    Colors.green.shade50,
                    Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  _buildStatCard(
                    "Alpha",
                    _countStatus('Alpha'),
                    Colors.red.shade50,
                    Colors.red.shade700,
                  ),
                  const SizedBox(width: 8),
                  _buildStatCard(
                    "Sakit",
                    _countStatus('Sakit'),
                    Colors.orange.shade50,
                    Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  _buildStatCard(
                    "Izin",
                    _countStatus('Izin'),
                    Colors.blue.shade50,
                    Colors.blue.shade700,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _listSiswa.length,
                separatorBuilder: (c, i) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final siswa = _listSiswa[index];
                  Color statusColor = Colors.grey;
                  if (siswa.status == 'Hadir')
                    statusColor = Colors.green;
                  else if (siswa.status == 'Alpha')
                    statusColor = Colors.red;
                  else if (siswa.status == 'Sakit')
                    statusColor = Colors.orange;
                  else if (siswa.status == 'Izin')
                    statusColor = Colors.blue;

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left: BorderSide(color: statusColor, width: 5),
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          child: Text(siswa.namaSiswa[0]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                siswa.namaSiswa,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                siswa.isLocked
                                    ? "🔒 Izin dari Wali Kelas"
                                    : (siswa.status == 'Hadir'
                                          ? "Terverifikasi"
                                          : "Belum Scan"),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: siswa.status == 'Hadir'
                                      ? Colors.green
                                      : (siswa.isLocked
                                            ? Colors.orange
                                            : Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // --- REVISI BAGIAN STATUS DI SINI ---
                        InkWell(
                          onTap: () => _showStatusPicker(siswa),
                          child: siswa.status == 'Hadir'
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size:
                                      28, // Ukuran ikon diperbesar dikit biar jelas
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        siswa.status,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.edit,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Center(
            child: InkWell(
              onTap: _bukaScanner,
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent,
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showStatusPicker(PresensiDetail siswa) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Ubah Status: ${siswa.namaSiswa}",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Divider(),
            // Guru mapel bisa mengubah status ke apa saja, termasuk Hadir
            ...['Hadir', 'Alpha', 'Sakit', 'Izin'].map(
              (s) => ListTile(
                leading: Icon(
                  s == 'Hadir' ? Icons.check_circle : Icons.info_outline,
                  color: s == 'Hadir' ? Colors.green : const Color(0xFF2563EB),
                ),
                title: Text(s),
                onTap: () {
                  setState(() {
                    siswa.status = s;
                    if (s == 'Hadir')
                      siswa.isLocked = false; // Buka gembok jika diset Hadir
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabJurnal() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CARD UTAMA FORM
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LABEL MATERI
                Row(
                  children: [
                    const Icon(Icons.book_outlined, color: Color(0xFF2563EB), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Materi Ajar",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(" *", style: TextStyle(color: Colors.red[600])),
                  ],
                ),
                const SizedBox(height: 12),
                // INPUT MATERI
                TextField(
                  controller: _materiController,
                  maxLines: 4,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Contoh: Pengenalan Aljabar Linear...",
                    hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),

                // LABEL CATATAN
                Row(
                  children: [
                    const Icon(Icons.notes_rounded, color: Color(0xFF2563EB), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Catatan Tambahan",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // INPUT CATATAN
                TextField(
                  controller: _catatanController,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Misal: Siswa A izin ke UKS di tengah jam...",
                    hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),

          // TOMBOL SIMPAN MODERN
          Container(
            width: double.infinity,
            height: 55,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF16A34A).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _simpanAbsensi,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_upload_outlined, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    "SIMPAN & AKHIRI KELAS",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 40), // Spacer bawah
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    int count,
    Color bgColor,
    Color textColor,
  ) {
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
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 10, color: textColor),
            ),
            Text(
              count.toString(),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
