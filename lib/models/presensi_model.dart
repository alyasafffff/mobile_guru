class PresensiDetail {
  final int id;
  final int siswaId;
  String status;
  final String namaSiswa;
  final String jenisKelamin;
  final String? qrToken;
  final bool isLocked; // <--- TAMBAHAN BARU

  PresensiDetail({
    required this.id,
    required this.siswaId,
    required this.status,
    required this.namaSiswa,
    required this.jenisKelamin,
    this.qrToken,
    required this.isLocked, // <--- Wajib diisi
  });

  factory PresensiDetail.fromJson(Map<String, dynamic> json) {
    return PresensiDetail(
      id: json['id'],
      siswaId: json['siswa_id'],
      status: json['status'],
      namaSiswa: json['nama_siswa'],
      jenisKelamin: json['jenis_kelamin'] ?? 'L',
      qrToken: json['qr_token'],
      // Konversi integer 1/0 dari API jadi boolean true/false
      isLocked: json['is_locked'] == 1, 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
    };
  }
}