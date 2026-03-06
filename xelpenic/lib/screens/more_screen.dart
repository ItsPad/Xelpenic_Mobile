import 'package:flutter/material.dart';
import 'edit_profile_screen.dart'; // เตรียมเชื่อมต่อไฟล์
import 'booking_history_screen.dart'; // เตรียมเชื่อมต่อไฟล์
import 'my_coupons_screen.dart'; // เตรียมเชื่อมต่อไฟล์
import 'redeem_screen.dart'; // เตรียมเชื่อมต่อไฟล์

class MoreScreen extends StatelessWidget {
  final VoidCallback onLogout;
  const MoreScreen({super.key, required this.onLogout});

  final Color goldColor = const Color(0xFFDDAA55);
  final Color blackColor = const Color(0xFF141414);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'MORE', 
          style: TextStyle(color: blackColor, fontWeight: FontWeight.w800, letterSpacing: 2)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _buildMenuTile(
            context, 
            Icons.person_outline,
            'แก้ไขโปรไฟล์', 
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())),
          ),
          _buildMenuTile(
            context, 
            Icons.history, 
            'ประวัติการจอง', 
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingHistoryScreen())),
          ),
          _buildMenuTile(
            context, 
            Icons.card_membership, 
            'XELPASS (ระบบสมาชิก)', 
            () {
              // TODO: สำหรับทำหน้าจัดการสมาชิกในอนาคต
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('เตรียมพบกับ XELPASS เร็วๆ นี้!'),
                backgroundColor: goldColor,
              ));
            },
          ),
          _buildMenuTile(
            context, 
            Icons.confirmation_number_outlined, 
            'คูปองของฉัน', 
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyCouponsScreen())),
          ),
          _buildMenuTile(
            context, 
            Icons.qr_code_scanner, 
            'Redeem Code (กรอกโค้ดรับสิทธิ์)', 
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RedeemScreen())),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.black12),
          ),

          // ปุ่มออกจากระบบ (ดีไซน์แยกให้ชัดเจน)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.red.shade100),
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.logout, color: Colors.red),
            ),
            title: const Text('ออกจากระบบ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: onLogout, 
            tileColor: Colors.white,
          ),
        ],
      ),
    );
  }

  // ดีไซน์ปุ่มเมนูให้ดูมินิมอลและหรูหรา
  Widget _buildMenuTile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: goldColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: goldColor),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: blackColor, fontSize: 16)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }
}