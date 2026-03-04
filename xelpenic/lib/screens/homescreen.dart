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
  // สร้าง Instance สำหรับเรียกใช้ Supabase
  final _supabase = Supabase.instance.client;

  // สร้างตัวแปรเก็บ Future ของข้อมูลแต่ละส่วน
  late Future<List<Map<String, dynamic>>> _nowShowingMovies;
  late Future<List<Map<String, dynamic>>> _comingSoonMovies;
  late Future<List<Map<String, dynamic>>> _redeemItems;

  User? _user;
  Map<String, dynamic>? _profileData;

  Future<void> _getUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('customer_ID', user.id)
          .single();
      setState(() {
        _user = user;
        _profileData = data;
      });
    }
  }

  

  @override
  void initState() {
    super.initState();
    // สั่งดึงข้อมูลตั้งแต่ตอนที่หน้านี้ถูกสร้างขึ้นมา
    _fetchData();
  }

  void _fetchData() {
    // 1. ดึงหนังที่กำลังฉาย (movie_showing = true)
    _nowShowingMovies = _supabase
        .from('movies')
        .select()
        .eq('movie_showing', true)
        .order('movie_release', ascending: false)
        .then((data) {
          return data;
        })
        .catchError((error) {
          print('==== ❌ Error หนังกำลังฉาย ====');
          print(error); // ปริ้นท์แจ้งเตือนถ้ามีปัญหา (เช่น ติด RLS)
          throw error;
        });

    // 2. ดึงโปรแกรมหน้า (movie_showing = false) ดึงมาแค่เรื่องเดียวตามดีไซน์
    _comingSoonMovies = _supabase
        .from('movies')
        .select()
        .eq('movie_showing', false)
        .then((data) {
          return data;
        })
        .catchError((error) {
          throw error;
        });

    // 3. ดึงรายการของสะสม
    _redeemItems = _supabase
        .from('items')
        .select()
        .then((data) {
          return data;
        })
        .catchError((error) {
          throw error;
        });
  }

  Widget _buildComingSoonSection() {
    return SizedBox(
      height: 280, // กำหนดความสูงให้พอดีกับรูปและตัวหนังสือ
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _comingSoonMovies,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final movies = snapshot.data ?? [];
          if (movies.isEmpty) {
            return const Center(child: Text('ยังไม่มีโปรแกรมหน้า'));
          }

          // เปลี่ยนมาใช้ ListView.builder เพื่อให้เลื่อนซ้าย-ขวาได้
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final movie = movies[index];
              return Container(
                width: 140, // ปรับความกว้างให้เท่ากับหมวดกำลังฉาย
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          movie['movie_post'] ?? '',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.image),
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      movie['movie_title'] ?? 'ไม่ทราบชื่อเรื่อง',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
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

  // --- ส่วน Profile ---
  Widget _buildProfileSection() {
  // เช็คว่าถ้ายังไม่ได้ Login ให้โชว์ Banner แบบ Guest หรือปุ่ม Login ก่อน
  if (_user == null) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF4A2C2A),
        borderRadius: BorderRadius.circular(0),
      ),
      child: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          ).then((_) => _getUserProfile()), // กลับมาแล้วดึงข้อมูลใหม่
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.brown),
          child: const Text('เข้าสู่ระบบเพื่อดูโปรไฟล์'),
        ),
      ),
    );
  }

  // ดึงค่าจริงจาก profileData
  final String name = _profileData?['customer_username'] ?? 'ไม่ทราบชื่อ';
  final int points = _profileData?['customer_points'] ?? 0;
  final int exp = _profileData?['customer_exp'] ?? 0;
  final String rank = _profileData?['customer_rank_user'] ?? 'Bronze';
  final String avatar = _profileData?['customer_avatar_url'] ?? 'https://uxwing.com/wp-content/themes/uxwing/download/peoples-avatars/man-user-circle-icon.png';

  return Container(
    height: 250,
    width: double.infinity,
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: NetworkImage(
          'https://media.discordapp.net/attachments/1475457011565985792/1478793043686461651/article_full3x.jpg?ex=69a9b0d8&is=69a85f58&hm=83cfdd582096daf729dd0ac5ab6fa901ef8970597a4b9e851b6baf86bed0ce4c&=&format=webp&width=1404&height=800',
        ),
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(
          Colors.black45,
          BlendMode.darken,
        ),
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
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white24,
                  backgroundImage: NetworkImage(avatar),
                ),
                const SizedBox(width: 15),
                Column(
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
                    Text(
                      'Xel Pass Student',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const Text(
                      'exp 31/1/2026',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 25),
            // หลอดจำนวนการดู
            Row(
              children: const [
                Icon(Icons.movie_filter_outlined, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'จำนวนการดู    263 ครั้ง / max',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: const LinearProgressIndicator(
                value: 0.7, 
                backgroundColor: Colors.white24,
                color: Colors.red,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
            // คะแนนสะสม
            Row(
              children: [
                const Icon(Icons.stars, color: Color(0xFFDDAA55), size: 20),
                const SizedBox(width: 8),
                Text(
                  'คะแนนสะสม  ',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                  ),
                ),
                Text(
                  '$points คะแนน',
                  style: const TextStyle(
                    color: Color(0xFFDDAA55),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        // รูปตรา Rank มุมขวา
        Positioned(
          right: 0,
          top: 10,
          child: Column(
            children: [
              Image.network(
                'https://cdn-icons-png.flaticon.com/512/610/610333.png', 
                height: 70,
              ),
              const SizedBox(height: 4),
              Text(
                'อันดับ: $rank',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const Text(
                'ป๊อบคอร์น จักรพรรดิ',
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
        ),

        // ปุ่ม Logout เล็กๆ มุมขวาบนสุด
        
      ],
    ),
  );
}

  // --- ส่วน หนังกำลังฉาย ---
  Widget _buildHorizontalMovieList() {
    return SizedBox(
      height: 280, // เพิ่มความสูงนิดหน่อยเผื่อแสดงชื่อหนัง
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _nowShowingMovies,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
          }
          final movies = snapshot.data ?? [];
          if (movies.isEmpty) {
            return const Center(child: Text('ไม่มีภาพยนตร์กำลังฉาย'));
          }

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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // แสดงรูปภาพจาก URL ที่เก็บใน DB (movie_post)
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          movie['movie_post'] ?? '',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.image_not_supported),
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      movie['movie_title'] ?? 'ไม่ทราบชื่อเรื่อง',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
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
            icon: const Icon(Icons.mail_outline, color: Colors.brown),
            onPressed: () => {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()))
            }
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Profile Banner Section
            _buildProfileSection(),

            // 2. Now Showing Section
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'กำลังฉาย',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
            ),
            _buildHorizontalMovieList(),

            // 3. Coming Soon Section
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'โปรแกรมหน้า',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
            ),
            _buildComingSoonSection(),

            // 4. Promotions & Redeem Section
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'โปรโมชั่น แลกของสะสม',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
            ),
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
      height:
          190, // เพิ่มความสูงจาก 150 เป็น 190 ให้มีพื้นที่วางข้อความและไอคอนไม่ให้ล้น
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _redeemItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('ไม่มีของสะสมในขณะนี้'));
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                width: 140, // ปรับความกว้างให้เท่ากับปกหนัง
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. รูปภาพของสะสม
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          12,
                        ), // ปรับมุมให้โค้งมนขึ้นนิดนึงตามดีไซน์
                        child: Image.network(
                          item['items_url'] ?? '',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.shopping_bag),
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 2. ชื่อไอเทม
                    Text(
                      item['items_name'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // 3. ไอคอนและราคา (สีทอง)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons
                              .cancel, // ใช้ไอคอนนี้เพราะหน้าตาคล้ายเหรียญตัว X ในดีไซน์ที่สุดครับ
                          size: 16,
                          color: Color(
                            0xFFDDAA55,
                          ), // สีทอง/เหลืองหม่นๆ แบบในดีไซน์
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item['items_cost'] ?? 0}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFDDAA55), // สีเดียวกับไอคอน
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
}
