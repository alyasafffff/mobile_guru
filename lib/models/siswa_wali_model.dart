class SiswaWali {
  final int id;
  final String nama;
  final String nis;

  SiswaWali({required this.id, required this.nama, required this.nis});

  factory SiswaWali.fromJson(Map<String, dynamic> json) {
    return SiswaWali(
      id: json['id'],
      nama: json['nama_siswa'], // Harus sama dengan JSON Laravel
      nis: json['nis'] ?? '-',
    );
  }
}