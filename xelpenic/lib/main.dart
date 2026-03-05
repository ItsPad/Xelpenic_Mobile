import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xelpenic/screens/cinemascreen.dart';
import 'package:cached_network_image/cached_network_image.dart';
// อย่าลืมเช็คชื่อไฟล์ import ให้ตรงกับของแพทนะครับ
import 'screens/homescreen.dart';
import 'screens/more_screen.dart';
import 'package:xelpenic/screens/nowshowing.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ตั้งค่าการเชื่อมต่อ Supabase
  await Supabase.initialize(
    url: 'https://dnaqqxfyjeuhvudynnze.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRuYXFxeGZ5amV1aHZ1ZHlubnplIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2MDg0MTgsImV4cCI6MjA4ODE4NDQxOH0.5RO7vBY38b4IeN0o-gCqh2knNNa3lwZ_OfhTWmZIEec',
  );

  runApp(const XelpenicApp());
}

class XelpenicApp extends StatelessWidget {
  const XelpenicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // เอาแถบ Debug ออกเพื่อให้สวยเหมือนเครื่องจริง
      title: 'Xelpenic',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 2; // เริ่มต้นที่หน้า HOME
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // ดักฟังสถานะการเปลี่ยน Auth (Login/Logout)
    _supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut) {
        if (mounted) {
          setState(() {
            _selectedIndex = 2; // กลับมาหน้า Home เมื่อ Logout
          });
        }
      }
    });
  }

  // --- ฟังก์ชัน Logout ส่วนกลางที่ส่งไปให้ MoreScreen ใช้ ---
  Future<void> onLogout() async {
    try {
      await _supabase.auth.signOut(); // คำสั่ง Logout หลัก
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // รายการหน้าจอ โดยใช้ IndexedStack เพื่อรักษา State ข้อมูล (แต้ม/ชื่อ) ไม่ให้หาย
    final List<Widget> _screens = [
      const NowShowingScreen(), 
      const Center(child: Text('COINS')),      
      const HomeScreen(),                       
      const CinemaScreen(),      
      MoreScreen(onLogout: onLogout), // ส่งฟังก์ชันไปให้หน้า More
    ];

    return Scaffold(
      // ใช้ IndexedStack เพื่อให้หน้า Home ไม่ถูกทำลายเมื่อสลับไปหน้าอื่น
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      
      // ปุ่ม HOME โลโก้ X ตรงกลาง
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _selectedIndex = 2),
        backgroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CachedNetworkImage(
            imageUrl: 'https://i.ibb.co/LXwqk0bH/Xelpenic-Logo-2.png',
            fit: BoxFit.contain,
            errorWidget: (context, url, error) => const Icon(Icons.home, color: Colors.brown),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(icon: Icons.movie_filter_outlined, label: 'NOW SHOWING', index: 0),
            _buildNavItem(icon: Icons.monetization_on_outlined, label: 'COINS', index: 1),
            const SizedBox(width: 40), // เว้นที่ให้ปุ่ม X
            _buildNavItem(icon: Icons.location_on_outlined, label: 'CINEMA', index: 3),
            _buildNavItem(icon: Icons.grid_view_rounded, label: 'MORE', index: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? Colors.brown : Colors.grey, size: 24),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.brown : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}