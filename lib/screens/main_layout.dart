import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

// Import semua halaman
import 'home_screen.dart';
import 'riwayat_screen.dart';
import 'profile_screen.dart';
import 'izin_tab_controller.dart'; // Tab Khusus Wali Kelas


class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  bool _isLoading = true;
  
  // List halaman & menu yang dinamis
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
      if (isWalikelas) {
        // --- MENU WALI KELAS (4 Tab) ---
        _pages = [
          const HomeScreen(),
          const RiwayatScreen(),
          const IzinTabController(), // <--- Tab Spesial
          const ProfileScreen(),
        ];
        _navItems = const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_ind), label: 'Izin'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ];
      } else {
        // --- MENU GURU BIASA (3 Tab) ---
        _pages = [
          const HomeScreen(),
          const RiwayatScreen(),
          const ProfileScreen(),
        ];
        _navItems = const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ];
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: IndexedStack( // Pakai IndexedStack biar halaman gak reload pas ganti tab
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed, // Wajib fixed kalau item > 3
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        items: _navItems,
      ),
    );
  }
}