import 'package:flutter/material.dart';
import 'package:xelpenic/screens/nowshowing.dart';
import 'screens/homescreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  // 2. ต้องมีบรรทัดนี้เสมอเมื่อเราจะเรียกใช้ Async ก่อน runApp
  WidgetsFlutterBinding.ensureInitialized();
  
  // 3. ตั้งค่าการเชื่อมต่อ Supabase
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
      title: 'Xelpenic',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
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
  int _selectedIndex = 2; // กำหนดให้เริ่มต้นที่หน้า HOME (Index 2)

  // รายการหน้าจอตาม Tab
  final List<Widget> _screens = [
    const NowShowingScreen(), // Index 0
    const Center(child: Text('COINS')),       // Index 1
    const HomeScreen(),                       // Index 2 (HOME)
    const Center(child: Text('CINEMA')),      // Index 3
    const Center(child: Text('MORE')),        // Index 4
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      // สร้างปุ่ม HOME ตรงกลาง
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _selectedIndex = 2),
        backgroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(8.0), // ปรับตัวเลขเพื่อขยาย/ลดระยะห่างจากขอบปุ่ม
          child: Image.network(
            'https://media.discordapp.net/attachments/1475457011565985792/1476608848415428669/Xelpenic_Logo_2.png?ex=69a8fee7&is=69a7ad67&hm=2920f5eb8db5bbc31c6b6b1ebe0640782f9af7dd0a7a79728e9e093d5bd7df47&=&format=webp&quality=lossless&width=930&height=930', // <-- นำ URL โลโก้ X ของแพทมาใส่ในเครื่องหมายคำพูดนี้ได้เลยครับ
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.broken_image, 
              color: Colors.brown,
            ),
          ),
        ),
      ), // เปลี่ยนเป็นโลโก้ X ได้ภายหลัง
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(icon: Icons.movie, label: 'NOW SHOWING', index: 0),
            _buildNavItem(icon: Icons.card_giftcard, label: 'COINS', index: 1),
            const SizedBox(width: 40), // เว้นที่ให้ปุ่ม HOME ตรงกลาง
            _buildNavItem(icon: Icons.location_on, label: 'CINEMA', index: 3),
            _buildNavItem(icon: Icons.menu, label: 'MORE', index: 4),
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
          Icon(icon, color: isSelected ? Colors.brown : Colors.grey),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? Colors.brown : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}