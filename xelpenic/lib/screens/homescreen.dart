import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xelpenic/screens/notificationscreen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;

  // ตัวแปรเก็บข้อมูลหนังและไอเทม
  late Future<List<Map<String, dynamic>>> _nowShowingMovies;
  late Future<List<Map<String, dynamic>>> _comingSoonMovies;
  late Future<List<Map<String, dynamic>>> _redeemItems;

  // ข้อมูลโปรไฟล์และเกณฑ์ Rank
  User? _user;
  Map<String, dynamic>? _profileData;
  List<Map<String, dynamic>> _rankThresholds = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
    // ฟังสถานะการ Login/Logout เพื่ออัปเดต UI ทันที
    _supabase.auth.onAuthStateChange.listen((data) {
      if (mounted) _getUserProfile();
    });
    _getUserProfile();
  }

  // --- ฟังก์ชันดึงข้อมูลโปรไฟล์และเกณฑ์ Rank ---
  Future<void> _getUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        // 1. ดึงข้อมูลโปรไฟล์จากตาราง profiles
        final profileData = await _supabase
            .from('profiles')
            .select()
            .eq('customer_ID', user.id)
            .single();

        // 2. ดึงเกณฑ์ Rank ทั้งหมดมาเก็บไว้เพื่อใช้คำนวณ
        final rankData = await _supabase
            .from('rank')
            .select()
            .order('rank_exp', ascending: false); // เรียงจากมากไปน้อย

        if (mounted) {
          setState(() {
            _user = user;
            _profileData = profileData;
            _rankThresholds = List<Map<String, dynamic>>.from(rankData);
          });
        }
      } catch (e) {
        debugPrint('==== ❌ Error loading profile data ==== $e');
      }
    } else {
      // ถ้าไม่ได้ Login ให้ล้างค่าเป็น null
      if (mounted) {
        setState(() {
          _user = null;
          _profileData = null;
        });
      }
    }
  }

  // --- ฟังก์ชันคำนวณ Rank จาก EXP ปัจจุบัน ---
  Map<String, dynamic> _calculateCurrentRank(int currentExp) {
    for (var rank in _rankThresholds) {
      int threshold = rank['rank_exp'] ?? 0;
      if (currentExp >= threshold) {
        return rank;
      }
    }
    // คืนค่า Rank ล่างสุดถ้าหาไม่เจอ
    return _rankThresholds.isNotEmpty ? _rankThresholds.last : {};
  }

  void _fetchData() {
    _nowShowingMovies = _supabase.from('movies').select().eq('movie_showing', true).order('movie_release', ascending: false);
    _comingSoonMovies = _supabase.from('movies').select().eq('movie_showing', false);
    _redeemItems = _supabase.from('items').select();
  }

  // --- ส่วน Profile Banner ---
  Widget _buildProfileSection() {
    if (_user == null) {
      return Container(
        height: 250,
        width: double.infinity,
        decoration: const BoxDecoration(color: Color(0xFF4A2C2A)),
        child: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.brown),
            child: const Text('เข้าสู่ระบบเพื่อดูโปรไฟล์'),
          ),
        ),
      );
    }

    // เตรียมข้อมูลแสดงผล
    final String name = _profileData?['customer_username'] ?? 'ไม่ทราบชื่อ';
    final int points = _profileData?['customer_points'] ?? 0;
    final int userExp = _profileData?['customer_exp'] ?? 0;
    final String avatar = _profileData?['customer_avatar_url'] ?? 'https://uxwing.com/wp-content/themes/uxwing/download/peoples-avatars/man-user-circle-icon.png';

    // คำนวณ Rank แบบ Dynamic
    final currentRank = _calculateCurrentRank(userExp);
    final String rankName = currentRank['rank_id'] ?? 'Bronze';
    final String rankPic = currentRank['rank_pic_url'] ?? '';

    return Container(
      height: 250,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage('https://media.discordapp.net/attachments/1475457011565985792/1478793043686461651/article_full3x.jpg?ex=69a9b0d8&is=69a85f58&hm=83cfdd582096daf729dd0ac5ab6fa901ef8970597a4b9e851b6baf86bed0ce4c&=&format=webp&width=1404&height=800'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 35, backgroundColor: Colors.white24, backgroundImage: NetworkImage(avatar)),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Xel Pass Student', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                      const Text('exp 31/1/2026', style: TextStyle(color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  const Icon(Icons.movie_filter_outlined, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('ค่าประสบการณ์ (EXP):  $userExp', style: const TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const Icon(Icons.stars, color: Color(0xFFDDAA55), size: 20),
                  const SizedBox(width: 8),
                  Text('คะแนนสะสม  ', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                  Text('$points คะแนน', style: const TextStyle(color: Color(0xFFDDAA55), fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          // แสดงรูป Rank ที่คำนวณได้
          Positioned(
            right: 0,
            top: 60,
            child: Column(
              children: [
                if (rankPic.isNotEmpty) Image.network(rankPic, height: 90) 
                else const Icon(Icons.workspace_premium, color: Colors.amber, size: 60),
                const SizedBox(height: 4),
                Text('อันดับ: $rankName', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- ส่วนแสดงผลหนังและไอเทม (โค้ดเดิมที่ปรับปรุง) ---
  Widget _buildMovieList(Future<List<Map<String, dynamic>>> future) {
    return SizedBox(
      height: 280,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final movies = snapshot.data ?? [];
          if (movies.isEmpty) return const Center(child: Text('ไม่มีข้อมูล'));
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final movie = movies[index];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(movie['movie_post'] ?? '', fit: BoxFit.cover))),
                    const SizedBox(height: 8),
                    Text(movie['movie_title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('XELPENIC', style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.mail_outline, color: Colors.brown), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()))),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(),
            const Padding(padding: EdgeInsets.all(16.0), child: Text('กำลังฉาย', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown))),
            _buildMovieList(_nowShowingMovies),
            const Padding(padding: EdgeInsets.all(16.0), child: Text('โปรแกรมหน้า', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown))),
            _buildMovieList(_comingSoonMovies),
            const Padding(padding: EdgeInsets.all(16.0), child: Text('โปรโมชั่น แลกของสะสม', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown))),
            _buildHorizontalItemList(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // --- ส่วน ของสะสม (Items) ---
  Widget _buildHorizontalItemList() {
    return SizedBox(
      height: 190,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _redeemItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data ?? [];
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(item['items_url'] ?? '', fit: BoxFit.cover))),
                    const SizedBox(height: 8),
                    Text(item['items_name'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cancel, size: 16, color: Color(0xFFDDAA55)),
                        const SizedBox(width: 4),
                        Text('${item['items_cost'] ?? 0}', style: const TextStyle(fontSize: 13, color: Color(0xFFDDAA55), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}