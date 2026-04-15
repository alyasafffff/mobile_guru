class Riwayat {
  final int id;
  final String tanggal;
  final String materi;
  final String? catatan;
  final String statusPengisian;
  final String namaKelas;
  final String namaMapel;
  final String jamMulai;
  final String jamSelesai;
  final int hadir;
  final int sakit;
  final int izin;
  final int alpha;
  final String tipeMengajar; // 'asli' atau 'piket'
  final String? namaGuruAsli;
  final String namaPengisi;

  Riwayat({
    required this.id,
    required this.tanggal,
    required this.materi,
    this.catatan,
    required this.statusPengisian,
    required this.namaKelas,
    required this.namaMapel,
    required this.jamMulai,
    required this.jamSelesai,
    required this.hadir,
    required this.sakit,
    required this.izin,
    required this.alpha,
    required this.tipeMengajar, 
    this.namaGuruAsli,
    required this.namaPengisi,
    
  });

  factory Riwayat.fromJson(Map<String, dynamic> json) {
    return Riwayat(
      id: json['id'],
      tanggal: json['tanggal'],
      materi: json['materi'] ?? "-",
      catatan: json['catatan'],
      statusPengisian: json['status_pengisian'],
      namaKelas: json['nama_kelas'],
      namaMapel: json['nama_mapel'],
      jamMulai: json['jam_mulai'],
      jamSelesai: json['jam_selesai'],
      hadir: json['hadir'],
      sakit: json['sakit'],
      izin: json['izin'],
      alpha: json['alpha'],
      tipeMengajar: json['tipe_mengajar'] ?? 'asli',
      namaGuruAsli: json['nama_guru_asli'],
      namaPengisi: json['nama_pengisi'],
    );
  }
}