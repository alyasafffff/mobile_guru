import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/izin_service.dart';
import '../models/siswa_wali_model.dart';

class IzinFormPage extends StatefulWidget {
  const IzinFormPage({super.key});

  @override
  State<IzinFormPage> createState() => _IzinFormScreenState();
}

class _IzinFormScreenState extends State<IzinFormPage> {
  final IzinService _izinService = IzinService();
  final _formKey = GlobalKey<FormState>();

  // State Loading
  bool _isInitialLoading = true;
  bool _isSubmitting = false;

  // Controller
  final TextEditingController _keteranganController = TextEditingController();

  // Data
  List<SiswaWali> _listSiswa = [];
  String _namaKelas = "...";
  String? _selectedSiswaNama; // Tambahkan ini di bawah _selectedSiswaId

  // Form State
  int? _selectedSiswaId;
  String? _selectedStatus;
  bool _isFullDay = true;
  int? _jamKeMulai;
  int? _jamKeSelesai;
  DateTimeRange? _selectedDateRange;

  final List<String> _opsiStatus = ['Sakit', 'Izin'];
  final List<int> _listJamKe = List.generate(10, (index) => index + 1);

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
    if (mounted)
      setState(() => _namaKelas = prefs.getString('nama_kelas') ?? "-");

    try {
      final data = await _izinService.getSiswaBinaan();
      if (mounted) {
        setState(() {
          _listSiswa = data;
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isInitialLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _onRefresh() async {
    try {
      final data = await _izinService.getSiswaBinaan();
      if (mounted) setState(() => _listSiswa = data);
    } catch (e) {
      print("Refresh gagal: $e");
    }
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF2563EB),
            colorScheme: const ColorScheme.light(primary: Color(0xFF2563EB)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDateRange = picked);
  }

  String _formatDateApi(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
  String _formatDateDisplay(DateTime date) =>
      DateFormat('d MMM yyyy', 'id_ID').format(date);

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDateRange == null) return;

    if (!_isFullDay) {
      if (_jamKeMulai == null || _jamKeSelesai == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pilih sesi mulai & selesai")),
        );
        return;
      }
      if (_jamKeSelesai! < _jamKeMulai!) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sesi selesai tidak boleh kurang dari sesi mulai"),
          ),
        );
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
        jamKeMulai: _isFullDay ? null : _jamKeMulai,
        jamKeSelesai: _isFullDay ? null : _jamKeSelesai,
        keterangan: _keteranganController.text,
      );

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Pengajuan Berhasil",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Izin untuk siswa berhasil dikirim ke sistem sekolah.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Menutup BottomSheet saja
                  _resetForm(); // Form jadi bersih kembali
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Selesai",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _selectedSiswaId = null;
      _selectedSiswaNama = null; // Tambahkan ini
      _selectedStatus = null;
      _isFullDay = true;
      _jamKeMulai = null;
      _jamKeSelesai = null;
      _keteranganController.clear();
      final now = DateTime.now();
      _selectedDateRange = DateTimeRange(start: now, end: now);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color.fromARGB(255, 139, 139, 139), // Warna panah putar
      backgroundColor: const Color.fromARGB(
        255,
        255,
        255,
        255,
      ), // Warna lingkaran background (biru)
      child: _isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoBox(),
                    const SizedBox(height: 24),
                    _buildLabel("Nama Siswa", true),
                    _buildSiswaDropdown(),
                    const SizedBox(height: 16),
                    _buildLabel("Jenis Halangan", true),
                    _buildStatusDropdown(),
                    const SizedBox(height: 16),
                    _buildLabel("Tanggal Izin", true),
                    _buildDateInput(),
                    if (_selectedDateRange != null &&
                        _selectedDateRange!.duration.inDays > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: Text(
                          "Total Izin: ${_selectedDateRange!.duration.inDays + 1} Hari",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    _buildFullDayToggle(),
                    if (!_isFullDay) _buildTimeInputs(),
                    const SizedBox(height: 16),
                    _buildLabel("Keterangan Tambahan", false),
                    _buildKeteranganField(),
                    const SizedBox(height: 30),
                    _buildSubmitButton(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTimeInputs() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Mulai Jam Ke-", true),
                  _buildContainerInput(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<int>(
                        value: _jamKeMulai,
                        isExpanded: true,
                        hint: Text(
                          "Pilih...",
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        items: _listJamKe
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text("Jam-$e"),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _jamKeMulai = v),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                      ),
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
                  _buildLabel("Sampai Jam Ke-", true),
                  _buildContainerInput(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<int>(
                        value: _jamKeSelesai,
                        isExpanded: true,
                        hint: Text(
                          "Pilih...",
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        items: _listJamKe
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text("Jam-$e"),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _jamKeSelesai = v),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: Colors.blue[700], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Kelas Binaan: $_namaKelas",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSiswaDropdown() {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Pilih Siswa Binaan",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: _listSiswa.length,
                    itemBuilder: (context, i) => ListTile(
                      leading: const Icon(
                        Icons.person_outline,
                        color: Color(0xFF2563EB),
                      ),
                      title: Text(
                        _listSiswa[i].nama,
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedSiswaId = _listSiswa[i].id;
                          _selectedSiswaNama = _listSiswa[i].nama;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: _buildContainerInput(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedSiswaNama ?? "Pilih Siswa...",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: _selectedSiswaNama == null
                      ? Colors.grey
                      : Colors.black87,
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Text(
                "Jenis Halangan",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Divider(),
              ..._opsiStatus.map(
                (s) => ListTile(
                  leading: Icon(
                    s == 'Sakit'
                        ? Icons.medical_services_outlined
                        : Icons.info_outline,
                    color: const Color(0xFF2563EB),
                  ),
                  title: Text(s, style: GoogleFonts.poppins(fontSize: 14)),
                  onTap: () {
                    setState(() => _selectedStatus = s);
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
      child: _buildContainerInput(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedStatus ?? "Pilih Alasan...",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: _selectedStatus == null ? Colors.grey : Colors.black87,
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateInput() {
    return InkWell(
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
    );
  }

  Widget _buildFullDayToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Izin Seharian (Full Day)?",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.grey[800],
          ),
        ),
        Switch(
          value: _isFullDay,
          activeTrackColor: const Color(0xFF2563EB),
          onChanged: (v) => setState(() => _isFullDay = v),
        ),
      ],
    );
  }

  Widget _buildKeteranganField() {
    return _buildContainerInput(
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
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isSubmitting
              ? Colors.orange[300]
              : Colors.orange[600],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.send_rounded, color: Colors.white),
        label: Text(
          _isSubmitting ? "MENGIRIM..." : "KIRIM PENGAJUAN",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          text: text.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
          children: [
            if (isRequired)
              const TextSpan(
                text: " *",
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContainerInput({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: child,
    );
  }
}
