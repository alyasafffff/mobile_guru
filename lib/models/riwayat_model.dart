class Riwayat {
  final int id;
  final String tanggal;
  final String materi;
  final String mapel;
  final String kelas;
  final String jam; // Gabungan jam mulai - selesai

  Riwayat({
    required this.id,
    required this.tanggal,
    required this.materi,
    required this.mapel,
    required this.kelas,
    required this.jam,
  });

  factory Riwayat.fromJson(Map<String, dynamic> json) {
    return Riwayat(
      id: json['id'],
      tanggal: json['tanggal'],
      materi: json['materi'] ?? '-', // Kalau materi kosong, isi strip
      mapel: json['nama_mapel'],
      kelas: json['nama_kelas'],
      jam: "${json['jam_mulai']} - ${json['jam_selesai']}",
    );
  }
}