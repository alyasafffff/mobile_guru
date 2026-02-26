class RiwayatIzin {
  final int id;
  final String namaSiswa;
  final String status;
  final String jenisIzin;
  final String tanggalMulai;
  final String tanggalSelesai;
  final int? jamKeMulai;
  final int? jamKeSelesai;
  final String? keterangan;

  RiwayatIzin({
    required this.id,
    required this.namaSiswa,
    required this.status,
    required this.jenisIzin,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    this.jamKeMulai,
    this.jamKeSelesai,
    this.keterangan,
  });

  factory RiwayatIzin.fromJson(Map<String, dynamic> json) {
    return RiwayatIzin(
      id: json['id'],
      namaSiswa: json['nama_siswa'], // Sesuai dengan alias 'nama_siswa' di Laravel
      status: json['status'],
      jenisIzin: json['jenis_izin'],
      tanggalMulai: json['tanggal_mulai'],
      tanggalSelesai: json['tanggal_selesai'],
      jamKeMulai: json['jam_ke_mulai'], // Pastikan key-nya sama dengan JSON dari Laravel
      jamKeSelesai: json['jam_ke_selesai'],
      keterangan: json['keterangan'],
    );
  }
}