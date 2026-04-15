class Jadwal {
  final int id;
  final String mapel;
  final String kelas;
  final String jamMulai;
  final String jamSelesai;
  final String statusJurnal; 
  final int? jurnalId;
  final String tipe; 
  // TAMBAHKAN INI: Nama guru asli yang digantikan (untuk fitur Piket)
  final String? namaGuruAsli; 

  Jadwal({
    required this.id,
    required this.mapel,
    required this.kelas,
    required this.jamMulai,
    required this.jamSelesai,
    required this.statusJurnal,
    required this.tipe,
    this.jurnalId,
    this.namaGuruAsli, // Tambahkan di constructor
  });

  factory Jadwal.fromJson(Map<String, dynamic> json) {
    return Jadwal(
      id: json['id'],
      mapel: json['nama_mapel'] ?? 'Tanpa Nama', 
      kelas: json['nama_kelas'] ?? '-',
      // Logika substring yang aman untuk format jam HH:mm:ss
      jamMulai: (json['jam_mulai'] != null && json['jam_mulai'].toString().length >= 5)
          ? json['jam_mulai'].toString().substring(0, 5)
          : '00:00',
      jamSelesai: (json['jam_selesai'] != null && json['jam_selesai'].toString().length >= 5)
          ? json['jam_selesai'].toString().substring(0, 5)
          : '00:00',
      statusJurnal: json['status_jurnal'] ?? 'belum_mulai',
      jurnalId: json['jurnal_id'],
      tipe: json['tipe'] ?? 'mapel',
      // TAMBAHKAN INI: Pastikan key-nya sama dengan 'nama_guru_asli' di API Laravel
      namaGuruAsli: json['nama_guru_asli'], 
    );
  }
}