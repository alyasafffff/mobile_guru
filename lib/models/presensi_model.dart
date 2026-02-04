class PresensiDetail {
  final String namaSiswa;
  final String status; // Hadir, Alpha, Sakit, Izin

  PresensiDetail({
    required this.namaSiswa,
    required this.status,
  });

  factory PresensiDetail.fromJson(Map<String, dynamic> json) {
    return PresensiDetail(
      namaSiswa: json['nama_siswa'], 
      status: json['status'],
    );
  }
}