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
  final String? urlFoto;

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
    this.urlFoto,
  });

  factory RiwayatIzin.fromJson(Map<String, dynamic> json) {
    return RiwayatIzin(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      namaSiswa: json['nama_siswa'],
      status: json['status'],
      jenisIzin: json['jenis_izin'],
      tanggalMulai: json['tanggal_mulai'],
      tanggalSelesai: json['tanggal_selesai'],
      // Handle null untuk jam_ke
      jamKeMulai: json['jam_ke_mulai'] != null
          ? int.parse(json['jam_ke_mulai'].toString())
          : null,
      jamKeSelesai: json['jam_ke_selesai'] != null
          ? int.parse(json['jam_ke_selesai'].toString())
          : null,
      keterangan: json['keterangan'],
      urlFoto: json['url_foto'],
    );
  }
}
