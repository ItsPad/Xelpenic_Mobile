import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'my_tickets_screen.dart';
import 'my_coupons_screen.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic>? profileData;
  final Map<String, dynamic> currentRank;
  // 💡 เพิ่มตัวแปรรับข้อมูล Xelpass จากฐานข้อมูล
  final Map<String, dynamic>? xelpassData;

  const ProfileScreen({
    super.key,
    required this.profileData,
    required this.currentRank,
    this.xelpassData, // รับค่าแบบ optional
  });

  @override
  Widget build(BuildContext context) {
    // 1. เตรียมข้อมูลโปรไฟล์
    final String name = profileData?['customer_username'] ?? 'ไม่ทราบชื่อ';
    final int points = profileData?['customer_points'] ?? 0;
    final String avatarUrl = profileData?['customer_avatar_url'] ?? 
        'https://i.ibb.co/1fBHkp1B/icon-7797704-640.png';
    
    // 2. เตรียมข้อมูล Rank
    final String rankName = currentRank['rank_id'] ?? 'Bronze';
    final String rankPic = currentRank['rank_pic_url'] ?? '';

    // 💡 3. เตรียมข้อมูล Xelpass จริงจากฐานข้อมูล
    final String xelType = xelpassData?['xel_type'] ?? 'Normal Member';
    final String rawExpDate = xelpassData?['xel_exp'] ?? '';
    
    // จัดรูปแบบวันที่หมดอายุ (ถ้ามี)
    String xelExpDisplay = 'No Active Pass';
    if (rawExpDate.isNotEmpty) {
      try {
        DateTime date = DateTime.parse(rawExpDate);
        xelExpDisplay = 'exp ${DateFormat('d/M/yyyy').format(date)}';
      } catch (e) {
        xelExpDisplay = 'exp $rawExpDate';
      }
    }

    final Color goldColor = const Color(0xFFDDAA55);
    final Color darkBgColor = const Color(0xFF2B2B2B);

    return Scaffold(
      backgroundColor: darkBgColor,
      body: Stack(
        children: [
          // พื้นหลังสีขาวส่วนบน
          ClipPath(
            clipper: CurvedBottomClipper(),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.55,
              color: Colors.white,
            ),
          ),

          // 💡 4. ป้ายบอกวันหมดอายุ (ดึงค่าจริง)
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD0B894),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                xelExpDisplay, // ใช้ตัวแปรวันที่จริง
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          // ปุ่มย้อนกลับ
          Positioned(
            top: 50,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // โลโก้
                Column(
                  children: [
                    Text('X', style: TextStyle(fontSize: 50, fontWeight: FontWeight.w300, color: goldColor, height: 1.0)),
                    const Text('XELPENIC', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 20),

                // รูปโปรไฟล์
                Container(
                  width: 140,
                  height: 140,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: goldColor, width: 3),
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: avatarUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => const Icon(Icons.person, size: 60),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ชื่อผู้ใช้
                Text(
                  name,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFFBCA67F)),
                ),
                
                // 💡 5. ระดับ Xel Pass (ดึงค่าจริง)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      xelType, // แสดงประเภทบัตรจริง เช่น Student Pass, Premium Pass
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (xelpassData != null)
                      Icon(Icons.workspace_premium, color: goldColor, size: 20),
                  ],
                ),

                const SizedBox(height: 40),

                // การ์ด Points & Status
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [Color(0xFFD4C1A0), Color(0xFFBCA67F)]),
                            borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('POINTS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: 1)),
                              const Text('คะแนนสะสม', style: TextStyle(fontSize: 10, color: Colors.black54)),
                              const SizedBox(height: 4),
                              Text(NumberFormat('#,###').format(points), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black)),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('STATUS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300, color: Color(0xFFDDAA55), letterSpacing: 2)),
                              const SizedBox(height: 4),
                              if (rankPic.isNotEmpty)
                                Image.network(rankPic, height: 50)
                              else
                                Icon(Icons.stars, color: goldColor, size: 40),
                              const SizedBox(height: 4),
                              Text(rankName, style: const TextStyle(fontSize: 10, color: Colors.white70)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // ปุ่มเมนู
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: [
                      _buildMenuButton(
                        context,
                        title: 'My Tickets',
                        subtitle: 'ตั๋วหนังของฉัน',
                        icon: Icons.confirmation_num,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyTicketsScreen())),
                      ),
                      const SizedBox(height: 16),
                      _buildMenuButton(
                        context,
                        title: 'My Rewards',
                        subtitle: 'คูปองและของรางวัล',
                        icon: Icons.card_giftcard,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyCouponsScreen())),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDAA55), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFEFECE5), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: const Color(0xFFDDAA55), size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
            const Icon(Icons.settings, color: Color(0xFFDDAA55)),
          ],
        ),
      ),
    );
  }
}

class CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(size.width / 2, size.height + 50, size.width, size.height - 50);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}