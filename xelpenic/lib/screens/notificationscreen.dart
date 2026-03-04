import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // ตัวแปรเก็บว่าตอนนี้เลือกแท็บไหนอยู่ (0 = ทั้งหมด)
  int _selectedTabIndex = 0;

  // รายการแท็บด้านซ้าย
  final List<Map<String, dynamic>> _tabs = [
    {'title': 'ทั้งหมด', 'count': 3},
    {'title': 'โปรโมชั่น', 'count': 1},
    {'title': 'ข่าวสาร', 'count': 1},
    {'title': 'ส่วนตัว', 'count': 1},
  ];

  // ข้อมูลจำลองสำหรับการแจ้งเตือน (Mock Data)
  final List<Map<String, dynamic>> _notifications = [
    {
      'type': 'promo',
      'title': 'โปรโมชั่นดูหนังพิเศษ!\nวันจันทร์ลด 50%',
      'description': 'รับสิทธิ์ส่วนลดบัตรชมภาพยนตร์ทันที 50% ทุกเรื่อง\nทุกโรงภาพยนตร์ XELPENIC',
      'time': 'วันนี้ , 09:00 น.',
      'isUnread': true,
      'icon': Icons.card_giftcard,
    },
    {
      'type': 'news',
      'title': 'SPIDER-MAN BRAND NEW\nDAY ฉายแล้ววันนี้!',
      'description': 'SPIDER-MAN BRAND NEW DAY ฉายแล้ววันนี้!',
      'time': 'วันนี้ , 09:00 น.',
      'isUnread': true,
      'icon': Icons.campaign, // รูปโทรโข่ง
    },
    {
      'type': 'personal',
      'title': 'คุณได้รับ 200 เหรียญ!',
      'description': 'คุณได้รับ 200 เหรียญจากการดู Avenger DoomsDay',
      'time': 'วันนี้ , 09:00 น.',
      'isUnread': true,
      'icon': Icons.monetization_on, // รูปเหรียญ
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // สีพื้นหลังฝั่งขวา (เทาอ่อน)
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.brown),
          onPressed: () => Navigator.pop(context), // กดเพื่อย้อนกลับ
        ),
        title: const Text(
          'XELPENIC',
          style: TextStyle(
            color: Colors.brown,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ฝั่งซ้าย: เมนูหมวดหมู่
          _buildSidebar(),
          // ฝั่งขวา: รายการแจ้งเตือน
          Expanded(
            child: _buildNotificationList(),
          ),
        ],
      ),
    );
  }

  // --- Widget ฝั่งซ้าย (Sidebar) ---
  Widget _buildSidebar() {
    return Container(
      width: 120, // ความกว้างของเมนูด้านซ้าย
      color: const Color(0xFFD4C1A0), // สีพื้นหลังเมนูซ้าย (สีเนื้อ/น้ำตาลอ่อน)
      child: Column(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          final tab = _tabs[index];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              margin: const EdgeInsets.only(bottom: 2), // เส้นคั่นบางๆ
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFFE6D6B8), // สีปุ่มตอนเลือก/ไม่เลือก
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [],
              ),
              child: Text(
                '${tab['title']} (${tab['count']})',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- Widget ฝั่งขวา (List การแจ้งเตือน) ---
  Widget _buildNotificationList() {
    // กรองข้อมูลตามแท็บที่เลือก (ถ้าอนาคตมีระบบ Filter)
    // ตอนนี้ให้แสดงทั้งหมดไปก่อนเพื่อความสวยงาม
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final noti = _notifications[index];
        return _buildNotificationCard(noti);
      },
    );
  }

  // --- Widget การ์ดแจ้งเตือน 1 อัน ---
  Widget _buildNotificationCard(Map<String, dynamic> noti) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EFE9), // สีพื้นหลังการ์ด
        border: Border.all(color: const Color(0xFFCBAE82), width: 1.5), // สีกรอบการ์ด
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ไอคอนด้านซ้าย
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD4C1A0),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(noti['icon'], color: Colors.black87, size: 24),
                ),
                const SizedBox(width: 12),
                // ข้อความตรงกลาง
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        noti['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        noti['description'],
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        noti['time'],
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFCBAE82), // สีเวลาออกน้ำตาลๆ
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // จุดสีแดง (Unread) มุมขวาบน
          if (noti['isUnread'] == true)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}