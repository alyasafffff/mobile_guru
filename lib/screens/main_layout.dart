import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

// Import halaman
import 'home_screen.dart';
import 'riwayat_screen.dart';
import 'profile_screen.dart';
import 'izin_tab_controller.dart'; 
import 'piket_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  bool _isLoading = true;
  
  List<Widget> _pages = [];
  List<BottomNavigationBarItem> _navItems = [];

  @override
  void initState() {
    super.initState();
    _setupMenu();
  }

  void _setupMenu() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isWalikelas = prefs.getBool('is_walikelas') ?? false;

    setState(() {
      // Kita susun list halaman secara modular agar lebih rapi
      _pages = [
        const HomeScreen(),
        const PiketScreen(), // <--- Tab Baru (Semua Guru Bisa Akses)
        const RiwayatScreen(),
      ];

      _navItems = [
        const BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Beranda'),
        const BottomNavigationBarItem(icon: Icon(Icons. find_in_page), label: 'Piket'), // Icon pengganti
        const BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
      ];

      // Jika dia wali kelas, sisipkan tab Izin sebelum tab Profil
      if (isWalikelas) {
        _pages.add(const IzinTabController());
        _navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.assignment_ind), label: 'Izin'));
      }

      // Selalu tutup dengan Profil
      _pages.add(const ProfileScreen());
      _navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'));

      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 15, // Ditinggikan biar lebih cakep
        items: _navItems,
      ),
    );
  }
}