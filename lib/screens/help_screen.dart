import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // DATA FAQ (Disesuaikan dengan Sistem Smart School kita)
  final List<Map<String, String>> _allFaqs = [
    {
      "question": "Bagaimana cara mengganti Foto Profil?",
      "answer": "Masuk ke menu Profil > Pilih 'Edit Data Diri'. Klik ikon kamera pada foto profil Anda, pilih foto dari galeri, lalu tekan tombol 'Simpan Perubahan'."
    },
    {
      "question": "Kenapa Jadwal Mengajar tidak muncul?",
      "answer": "Jadwal akan muncul otomatis sesuai hari ini. Jika kosong, pastikan Anda memiliki koneksi internet dan coba tarik layar ke bawah (Refresh) di Halaman Utama."
    },
    {
      "question": "Saya lupa password akun, bagaimana solusinya?",
      "answer": "Untuk keamanan data sekolah, fitur reset password mandiri dinonaktifkan. Silakan hubungi Administrator IT Sekolah untuk meminta reset password manual."
    },
    {
      "question": "Data NIP atau Nama saya salah",
      "answer": "Data NIP dan Nama dikelola terpusat oleh Admin. Anda tidak bisa mengubahnya sendiri. Silakan lapor ke Tata Usaha untuk perbaikan data di database pusat."
    },
    {
      "question": "Apakah aplikasi bisa berjalan tanpa internet?",
      "answer": "Aplikasi membutuhkan koneksi internet untuk mengambil jadwal terbaru dan menyimpan foto profil. Namun, data yang sudah dimuat sebelumnya (Cache) tetap bisa dilihat tanpa internet."
    },
    {
      "question": "Nomor HP sudah diganti tapi belum berubah?",
      "answer": "Pastikan Anda menekan tombol 'Simpan Perubahan' setelah mengetik nomor baru. Jika masih belum berubah, coba tutup aplikasi dan buka kembali."
    },
  ];

  // List untuk menampung hasil pencarian
  List<Map<String, String>> _filteredFaqs = [];

  @override
  void initState() {
    super.initState();
    _filteredFaqs = _allFaqs; // Awalnya tampilkan semua
  }

  // Logika Pencarian
  void _runFilter(String keyword) {
    List<Map<String, String>> results = [];
    if (keyword.isEmpty) {
      results = _allFaqs;
    } else {
      results = _allFaqs
          .where((item) =>
              item["question"]!.toLowerCase().contains(keyword.toLowerCase()))
          .toList();
    }

    setState(() {
      _filteredFaqs = results;
    });
  }

  // Fungsi Buka WA (Opsional)
  // Fungsi Buka WA
  Future<void> _launchWA() async {
    // Ganti nomor ini (Format: kode negara tanpa +, contoh 628...)
    final Uri url = Uri.parse('https://wa.me/6281234567890'); 

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Stack(
        children: [
          // --- 1. HEADER BIRU ---
          Container(
            height: 240, // Tinggi header
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB), // Blue-600
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tombol Back & Judul
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text("Pusat Bantuan", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),
                Text("Halo,", style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text("Ada kendala apa hari ini?", style: GoogleFonts.poppins(color: Colors.blue[100], fontSize: 14)),
              ],
            ),
          ),

          // --- 2. LIST KONTEN (Tumpuk di atas Header) ---
          Padding(
            padding: const EdgeInsets.only(top: 225), // Turunkan supaya Search Bar muat
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Topik Populer (FAQ)", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                  const SizedBox(height: 12),

                  // LIST FAQ
                  if (_filteredFaqs.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text("Tidak ada hasil ditemukan.", style: GoogleFonts.poppins(color: Colors.grey)),
                      ),
                    )
                  else
                    ..._filteredFaqs.map((faq) => _buildAccordion(faq["question"]!, faq["answer"]!)),

                  const SizedBox(height: 24),

                  // KONTAK ADMIN BOX
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.blue.shade100),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.blue[100], shape: BoxShape.circle),
                          child: const Icon(Icons.headset_mic, color: Color(0xFF2563EB), size: 24),
                        ),
                        const SizedBox(height: 12),
                        Text("Masih butuh bantuan?", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey[800])),
                        Text("Tim IT Sekolah siap membantu Anda.", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
                        const SizedBox(height: 16),
                        
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                                                            _launchWA(); // Aktifkan jika sudah pasang package url_launcher
                            },
                            icon: const Icon(Icons.chat, color: Colors.white, size: 18),
                            label: Text("Chat Administrator", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              elevation: 2,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  Center(child: Text("Smart School App v1.0.0", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[400]))),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // --- 3. SEARCH BAR (Melayang) ---
          Positioned(
            top: 185, // Posisi agar setengah di biru, setengah di putih
            left: 20,
            right: 20,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => _runFilter(value),
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Cari masalah (misal: login, foto)...",
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget Accordion (Mirip <details> HTML)
  Widget _buildAccordion(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent), // Hilangkan garis bawaan
        child: ExpansionTile(
          title: Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[800])),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedAlignment: Alignment.centerLeft,
          iconColor: Colors.grey[400],
          collapsedIconColor: Colors.grey[400],
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade100))
              ),
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                content,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600], height: 1.5),
              ),
            )
          ],
        ),
      ),
    );
  }
}