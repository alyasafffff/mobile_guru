import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/izin_service.dart';
import '../models/siswa_wali_model.dart';

class IzinScreen extends StatefulWidget {
  const IzinScreen({super.key});

  @override
  State<IzinScreen> createState() => _IzinScreenState();
}

class _IzinScreenState extends State<IzinScreen> {
  final IzinService _izinService = IzinService();
  final _formKey = GlobalKey<FormState>();
  
  // Controller untuk Keterangan (Sesuai referensi HTML ada input text area)
  final TextEditingController _keteranganController = TextEditingController();

  // Data
  List<SiswaWali> _listSiswa = [];
  bool _isLoadingSiswa = true;
  String _namaKelas = "...";
  
  // Form State
  int? _selectedSiswaId;
  String? _selectedStatus;
  bool _isFullDay = true;
  TimeOfDay? _jamMulai;
  TimeOfDay? _jamSelesai;
  DateTimeRange? _selectedDateRange; 

  bool _isSubmitting = false;
  final List<String> _opsiStatus = ['Sakit', 'Izin', 'Dispensasi'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(start: now, end: now);
    _loadData();
  }

  @override
  void dispose() {
    _keteranganController.dispose();
    super.dispose();
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => _namaKelas = prefs.getString('nama_kelas') ?? "-");
    try {
      final data = await _izinService.getSiswaBinaan();
      setState(() {
        _listSiswa = data;
        _isLoadingSiswa = false;
      });
    } catch (e) {
      setState(() => _isLoadingSiswa = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --- LOGIC HELPERS ---
  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue[600],
            colorScheme: ColorScheme.light(primary: Colors.blue[600]!),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  Future<void> _pickTime(bool isMulai) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isMulai) _jamMulai = picked;
        else _jamSelesai = picked;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDateApi(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
  String _formatDateDisplay(DateTime date) => DateFormat('d MMM yyyy', 'id_ID').format(date);

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDateRange == null) return;

    if (!_isFullDay) {
      if (_jamMulai == null || _jamSelesai == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Isi jam mulai & selesai")));
        return;
      }
      final start = _jamMulai!.hour * 60 + _jamMulai!.minute;
      final end = _jamSelesai!.hour * 60 + _jamSelesai!.minute;
      if (end <= start) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jam selesai harus lebih akhir")));
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      await _izinService.kirimIzin(
        siswaId: _selectedSiswaId!,
        status: _selectedStatus!,
        jenisIzin: _isFullDay ? 'full' : 'jam',
        tanggalMulai: _formatDateApi(_selectedDateRange!.start),
        tanggalSelesai: _formatDateApi(_selectedDateRange!.end),
        jamMulai: _isFullDay ? null : _formatTime(_jamMulai!),
        jamSelesai: _isFullDay ? null : _formatTime(_jamSelesai!),
        keterangan: _keteranganController.text, // Pastikan service menerima parameter ini
      );
      
      if (!mounted) return;
      
      // Tampilkan Toast/Dialog Sukses seperti di HTML
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text("Berhasil")]),
          content: Text("Izin untuk siswa berhasil dikirim ke sistem sekolah."),
          actions: [
            TextButton(
              onPressed: (){
                Navigator.pop(c);
                Navigator.pop(context); // Kembali ke halaman sebelumnya
              }, 
              child: const Text("OK", style: TextStyle(color: Colors.blue))
            )
          ],
        )
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background putih bersih sesuai referensi HTML
      // 1. APP BAR BIRU
      appBar: AppBar(
        backgroundColor: Colors.blue[600],
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text("Formulir Izin Siswa", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoadingSiswa 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // 2. INFO BOX (Seperti di HTML)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Kelas Binaan: $_namaKelas", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.blue[800], fontSize: 12)),
                              const SizedBox(height: 4),
                              Text("Pastikan data izin yang diinput valid dan memiliki bukti (surat dokter/ortu).", style: GoogleFonts.poppins(color: Colors.blue[800], fontSize: 11)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. PILIH SISWA
                  _buildLabel("Nama Siswa", true),
                  _buildContainerInput(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<int>(
                        value: _selectedSiswaId,
                        isExpanded: true,
                        hint: Text("Pilih Siswa...", style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
                        items: _listSiswa.map((s) => DropdownMenuItem(value: s.id, child: Text(s.nama, style: GoogleFonts.poppins(fontSize: 14)))).toList(),
                        onChanged: (v) => setState(() => _selectedSiswaId = v),
                        decoration: const InputDecoration(border: InputBorder.none),
                        validator: (v) => v == null ? "Wajib dipilih" : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. PILIH STATUS
                  _buildLabel("Jenis Halangan", true),
                  _buildContainerInput(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        isExpanded: true,
                        hint: Text("Pilih Alasan...", style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
                        items: _opsiStatus.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.poppins(fontSize: 14)))).toList(),
                        onChanged: (v) => setState(() => _selectedStatus = v),
                        decoration: const InputDecoration(border: InputBorder.none),
                        validator: (v) => v == null ? "Wajib dipilih" : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 5. TANGGAL IZIN
                  _buildLabel("Tanggal Izin", true),
                  InkWell(
                    onTap: _pickDateRange,
                    child: _buildContainerInput(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDateRange == null 
                            ? "Pilih Rentang Tanggal" 
                            : "${_formatDateDisplay(_selectedDateRange!.start)} - ${_formatDateDisplay(_selectedDateRange!.end)}",
                            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                          ),
                          const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  if (_selectedDateRange != null && _selectedDateRange!.duration.inDays > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Text("Total Izin: ${_selectedDateRange!.duration.inDays + 1} Hari", style: GoogleFonts.poppins(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
                  
                  const SizedBox(height: 16),

                  // 6. TOGGLE FULL DAY
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Izin Seharian (Full Day)?", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey[800])),
                      Switch(
                        value: _isFullDay, 
                        activeColor: Colors.white,
                        activeTrackColor: Colors.blue[600],
                        onChanged: (v) => setState(() => _isFullDay = v)
                      ),
                    ],
                  ),

                  // 7. INPUT JAM (Jika tidak Full Day)
                  if (!_isFullDay) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Mulai Jam", true),
                              InkWell(
                                onTap: () => _pickTime(true),
                                child: _buildContainerInput(
                                  child: Text(_jamMulai != null ? _formatTime(_jamMulai!) : "--:--", style: GoogleFonts.poppins(fontSize: 14)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Sampai Jam", true),
                              InkWell(
                                onTap: () => _pickTime(false),
                                child: _buildContainerInput(
                                  child: Text(_jamSelesai != null ? _formatTime(_jamSelesai!) : "--:--", style: GoogleFonts.poppins(fontSize: 14)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  // 8. KETERANGAN (Sesuai HTML "Materi Ajar/Keterangan")
                  _buildLabel("Keterangan Tambahan", false),
                  _buildContainerInput(
                    child: TextFormField(
                      controller: _keteranganController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Contoh: Demam tinggi sejak semalam...",
                        hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
                        border: InputBorder.none,
                      ),
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 9. TOMBOL KIRIM (Orange Style)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600], // Orange sesuai referensi HTML
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      icon: _isSubmitting 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: Colors.white),
                      label: Text(
                        _isSubmitting ? "MENGIRIM..." : "KIRIM PENGAJUAN", 
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }

  // UI HELPERS (Agar mirip Style HTML)
  Widget _buildLabel(String text, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          text: text.toUpperCase(),
          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          children: [
            if (isRequired) const TextSpan(text: " *", style: TextStyle(color: Colors.red))
          ]
        ),
      ),
    );
  }

  Widget _buildContainerInput({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4), // Padding dalam input
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10), // Rounded corners
        border: Border.all(color: Colors.grey.shade300), // Border abu-abu
      ),
      child: child,
    );
  }
}