class Kelas {
  final int id;
  final String namaKelas;

  Kelas({required this.id, required this.namaKelas});

  factory Kelas.fromJson(Map<String, dynamic> json) {
    return Kelas(
      id: json['id'],
      namaKelas: json['nama_kelas'],
    );
  }
}