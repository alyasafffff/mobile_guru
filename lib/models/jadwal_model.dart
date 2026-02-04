class Jadwal {
  final int id;
  final String mapel;
  final String kelas;
  final String jamMulai;
  final String jamSelesai;
  
  // Status Jurnal: 'belum_mulai', 'proses', atau 'selesai'
  // Ini penting buat nentuin warna tombol (Biru/Hijau/Abu)
  final String statusJurnal; 
  
  // ID Jurnal (Nullable / Bisa null)
  // Kalau status 'belum_mulai', ini pasti null.
  // Kalau 'proses'/'selesai', ini ada isinya (buat lanjut ngajar).
  final int? jurnalId;

  Jadwal({
    required this.id,
    required this.mapel,
    required this.kelas,
    required this.jamMulai,
    required this.jamSelesai,
    required this.statusJurnal,
    this.jurnalId,
  });

  // Factory method untuk mengubah JSON dari API menjadi Object Jadwal
  factory Jadwal.fromJson(Map<String, dynamic> json) {
    return Jadwal(
      id: json['id'],
      // Pastikan key ini ('nama_mapel') SAMA PERSIS dengan respon API Laravel
      mapel: json['nama_mapel'] ?? 'Mapel Tanpa Nama', 
      kelas: json['nama_kelas'] ?? '-',
      
      // Ambil 5 karakter pertama saja (07:00:00 -> 07:00) biar rapi
      jamMulai: (json['jam_mulai'] != null && json['jam_mulai'].toString().length >= 5)
          ? json['jam_mulai'].toString().substring(0, 5)
          : '00:00',
          
      jamSelesai: (json['jam_selesai'] != null && json['jam_selesai'].toString().length >= 5)
          ? json['jam_selesai'].toString().substring(0, 5)
          : '00:00',
          
      statusJurnal: json['status_jurnal'] ?? 'belum_mulai',
      jurnalId: json['jurnal_id'],
    );
  }
}