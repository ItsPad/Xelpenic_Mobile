import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xelpenic/screens/notificationscreen.dart';
import 'login_screen.dart';
import 'movie_detail.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'my_tickets_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;

  late Future<List<Map<String, dynamic>>> _nowShowingMovies;
  late Future<List<Map<String, dynamic>>> _comingSoonMovies;
  late Future<List<Map<String, dynamic>>> _redeemItems;

  User? _user;
  Map<String, dynamic>? _profileData;
  List<Map<String, dynamic>> _rankThresholds = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
    _supabase.auth.onAuthStateChange.listen((data) {
      if (mounted) _getUserProfile();
    });
    _getUserProfile();
  }

  // --- ฟังก์ชันสำหรับ Pull-to-Refresh ---
  Future<void> _refreshData() async {
    // โหลดข้อมูลหนัง ไอเทม และโปรไฟล์ใหม่ทั้งหมด
    setState(() {
      _fetchData();
    });
    await _getUserProfile();
  }

  // --- เพิ่มตัวแปรสำหรับเก็บข้อมูล Xelpass ใน _HomeScreenState ---
  Map<String, dynamic>? _xelpassData;

  Future<void> _getUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        // 1. ดึงข้อมูล Profile ตามปกติ
        final profileData = await _supabase
            .from('profiles')
            .select()
            .eq('customer_ID', user.id)
            .single();

        // 2. ดึงข้อมูล Xelpass ที่ยังไม่หมดอายุล่าสุด
        final xelData = await _supabase
            .from('xelpass')
            .select()
            .eq('xel_user_id', user.id)
            .gte(
              'xel_exp',
              DateTime.now().toIso8601String(),
            ) // เช็คใบที่ยังไม่หมดอายุ
            .maybeSingle(); // ใช้ maybeSingle เพราะผู้ใช้อาจจะยังไม่มีบัตร

        final rankData = await _supabase
            .from('rank')
            .select()
            .order('rank_exp', ascending: false);

        if (mounted) {
          setState(() {
            _user = user;
            _profileData = profileData;
            _xelpassData = xelData; // 💡 เก็บข้อมูลลงตัวแปร
            _rankThresholds = List<Map<String, dynamic>>.from(rankData);
          });
        }
      } catch (e) {
        debugPrint('==== ❌ Error loading data ==== $e');
      }
    } else {
      if (mounted) {
        setState(() {
          _user = null;
          _profileData = null;
          _xelpassData = null;
        });
      }
    }
  }

  Map<String, dynamic> _calculateCurrentRank(int currentExp) {
    for (var rank in _rankThresholds) {
      int threshold = rank['rank_exp'] ?? 0;
      if (currentExp >= threshold) {
        return rank;
      }
    }
    return _rankThresholds.isNotEmpty ? _rankThresholds.last : {};
  }

  void _fetchData() {
    _nowShowingMovies = _supabase
        .from('movies')
        .select()
        .eq('movie_showing', true)
        .order('movie_release', ascending: false);
    _comingSoonMovies = _supabase
        .from('movies')
        .select()
        .eq('movie_showing', false);
    _redeemItems = _supabase.from('items').select();
  }

  // --- ส่วน Profile Banner ---
  Widget _buildProfileSection() {
    // 1. กรณีที่ยังไม่ได้ล็อกอิน
    if (_user == null) {
      return Container(
        height: 220,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF4A2C2A),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.brown,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'เข้าสู่ระบบเพื่อดูโปรไฟล์',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }

    // 2. เตรียมข้อมูลสำหรับกรณีล็อกอินแล้ว
    final String name = _profileData?['customer_username'] ?? 'ไม่ทราบชื่อ';
    final int points = _profileData?['customer_points'] ?? 0;
    final int userExp = _profileData?['customer_exp'] ?? 0;
    final String avatar =
        _profileData?['customer_avatar_url'] ??
        'https://i.ibb.co/1fBHkp1B/icon-7797704-640.png';

    final currentRank = _calculateCurrentRank(userExp);
    final String rankName = currentRank['rank_id'] ?? 'Bronze';
    final String rankPic = currentRank['rank_pic_url'] ?? '';
    final String xelType = _xelpassData?['xel_type'] ?? 'NORMAL MEMBER';

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        image: const DecorationImage(
          image: NetworkImage('https://i.ibb.co/B2ZvHFL3/article-full3x.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        // เลเยอร์สำหรับทำสีมืดทับรูปเพื่อให้ตัวหนังสือเด่น
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.black.withOpacity(0.3),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                //Avatar สวยๆ พร้อมขอบขาว
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundImage: NetworkImage(avatar),
                  ),
                ),
                const SizedBox(width: 16),
                // ข้อมูลชื่อและระดับ
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _xelpassData != null
                              ? const Color(0xFFDDAA55)
                              : Colors.grey.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          xelType.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // ส่วนของ Rank (Badge)
                Column(
                  children: [
                    rankPic.isNotEmpty
                        ? Image.network(rankPic, height: 50)
                        : const Icon(
                            Icons.workspace_premium,
                            color: Color(0xFFDDAA55),
                            size: 40,
                          ),
                    Text(
                      rankName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 25),
            // ส่วนสรุป EXP และ คะแนน (จัดกลุ่มใน Glass Box)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    Icons.military_tech,
                    'EXP',
                    userExp.toString(),
                  ),
                  Container(width: 1, height: 30, color: Colors.white24),
                  _buildStatItem(
                    Icons.stars,
                    'POINTS',
                    points.toString(),
                    valueColor: const Color(0xFFDDAA55),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            // ปุ่มดูรายละเอียดโปรไฟล์
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  // 💡 จุดที่อยู่ใน HomeScreen ตอนสั่งเปลี่ยนหน้า
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                        profileData: _profileData,
                        currentRank: currentRank,
                        xelpassData:
                            _xelpassData, // ส่งข้อมูลที่ดึงมาจาก table xelpass ไปด้วย
                      ),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'VIEW PROFILE DETAILS',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.white60, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget ตัวย่อยสำหรับสร้างช่อง EXP และ Points
  Widget _buildStatItem(
    IconData icon,
    String label,
    String value, {
    Color valueColor = Colors.white,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.white60),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildMovieList(Future<List<Map<String, dynamic>>> future) {
    return SizedBox(
      height: 280,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.brown),
            );
          }

          final movies = snapshot.data ?? [];
          if (movies.isEmpty) return const Center(child: Text('ไม่มีข้อมูล'));

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final movie = movies[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MovieDetailScreen(movie: movie),
                    ),
                  );
                },
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: movie['movie_post'] ?? '',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey.shade300,
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        movie['movie_title'] ?? 'ไม่ทราบชื่อ',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        movie['movie_genre'] ?? 'Action',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHorizontalItemList() {
    return SizedBox(
      height: 190,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _redeemItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
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
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          item['items_url'] ?? '',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['items_name'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.cancel,
                          size: 16,
                          color: Color(0xFFDDAA55),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item['items_cost'] ?? 0}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFDDAA55),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'XELPENIC',
          style: TextStyle(
            color: Colors.brown,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.local_activity_outlined,
              color: Color(0xFFDDAA55),
              size: 28,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyTicketsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.mail_outline, color: Colors.brown),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationScreen(),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      // --- เพิ่ม RefreshIndicator ตรงนี้ ---
      body: RefreshIndicator(
        onRefresh: _refreshData, // เรียกฟังก์ชันดึงข้อมูลใหม่
        color: const Color(0xFFDDAA55), // เปลี่ยนสีวงกลมโหลดเป็นสีทองให้เข้าธีม
        backgroundColor: Colors.black87, // พื้นหลังวงกลมสีดำ
        child: SingleChildScrollView(
          // จำียบเป็นต้องมี physics นี้เพื่อให้ดึงลงสุดแล้วเด้งรีเฟรชได้เสมอแม้ข้อมูลจะน้อย
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileSection(),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'กำลังฉาย',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFCFB994),
                  ),
                ),
              ),
              _buildMovieList(_nowShowingMovies),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'โปรแกรมหน้า',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFCFB994),
                  ),
                ),
              ),
              _buildMovieList(_comingSoonMovies),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'โปรโมชั่น แลกของสะสม',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFCFB994),
                  ),
                ),
              ),
              _buildHorizontalItemList(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
