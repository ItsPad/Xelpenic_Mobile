import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CoinScreen extends StatefulWidget {
  const CoinScreen({super.key});

  @override
  State<CoinScreen> createState() => _CoinScreenState();
}

class _CoinScreenState extends State<CoinScreen> {
  final _supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _itemsFuture;

  // จำลองข้อมูลผู้ใช้ (เนื่องจากยังไม่มีระบบ Login)
  int _currentCoins = 0;
  String _profileImageUrl = '';
  String _userName = '';
  bool _isLoadingProfile = true;

  late final StreamSubscription<AuthState> _authStateSubscription;

  // จำลองแพ็กเกจเติมเงิน
  final List<Map<String, dynamic>> _topUpPackages = [
    {'coins': 50, 'price': 50},
    {'coins': 150, 'price': 150},
    {'coins': 250, 'price': 250},
    {'coins': 500, 'price': 500},
    {'coins': 750, 'price': 750},
    {'coins': 1000, 'price': 1000},
    {'coins': 1500, 'price': 1500},
    {'coins': 2000, 'price': 2000},
  ];

  @override
  void initState() {
    super.initState();
    _fetchItems();
    _fetchUserProfile(); // เรียกฟังก์ชันดึงข้อมูล Profile เพิ่มเข้ามา

    _authStateSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      _fetchUserProfile();
    });
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  void _fetchItems() {
    // ดึงข้อมูลของรางวัลจากตาราง items
    _itemsFuture = _supabase.from('items').select();
  }

 Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoadingProfile = true; // สั่งให้ขึ้นโหลดทุกครั้งที่ดึงข้อมูลใหม่
    });

    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        final response = await _supabase
            .from('profiles')
            .select('customer_points, customer_avatar_url, customer_username')
            .eq('customer_ID', user.id)
            .single();

        setState(() {
          _currentCoins = response['customer_points'] ?? 0;
          _profileImageUrl = response['customer_avatar_url'] ?? 'https://i.pravatar.cc/150?img=47';
          _userName = response['customer_username'] ?? 'John Doe';
          _isLoadingProfile = false; 
        });
      } else {
        setState(() {
          _currentCoins = 0;
          _profileImageUrl = 'https://i.pravatar.cc/150?img=47';
          _userName = 'John Doe';
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      print('==== ❌ Error Fetching Profile ====');
      print(e);
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _processTopUp(int coinsToAdd) async {
    try {
      final user = _supabase.auth.currentUser;
      final newTotalCoins = _currentCoins + coinsToAdd;

      // ถ้ามีการ Login อยู่ ให้อัปเดตลงฐานข้อมูล
      if (user != null) {
        await _supabase
            .from('profiles')
            .update({'customer_points': newTotalCoins}) // อัปเดตยอดใหม่
            .eq('customer_ID', user.id);
      }

      // อัปเดตหน้าจอ UI ให้ตัวเลขเปลี่ยนตาม
      setState(() {
        _currentCoins = newTotalCoins;
      });

      // แจ้งเตือนผู้ใช้ว่าเติมสำเร็จ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เติมเงินสำเร็จ! ได้รับ $coinsToAdd Coins'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('==== ❌ Error Topping Up ====');
      print(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เกิดข้อผิดพลาดในการเติมเงิน'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F1),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'COINS',
          style: TextStyle(
            color: Colors.brown,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Color(0xFFD4AF37), size: 20),
                const SizedBox(width: 4),
                // โชว์ตัวโหลดกลมๆ เล็กๆ ถ้าระบบกำลังดึง Points จากฐานข้อมูล
                _isLoadingProfile
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.brown),
                      )
                    : Text(
                        '$_currentCoins',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 16,
                  backgroundImage: _profileImageUrl.isNotEmpty 
                      ? NetworkImage(_profileImageUrl) 
                      : null,
                  backgroundColor: Colors.grey.shade300,
                  child: _profileImageUrl.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                ),
                SizedBox(width: 4,),
                Text(_userName,style:TextStyle(fontWeight: FontWeight.bold))
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTopUpBanner(),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'แลกของรางวัล',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildItemsGrid(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopUpBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD4C1A0), Color(0xFFBCA67F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ยอดเหรียญคงเหลือ',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.white, size: 28),
                  const SizedBox(width: 8),
                  _isLoadingProfile 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          '$_currentCoins',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            onPressed: _showTopUpModal,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.brown,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('เติมเงิน', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- Grid แสดงรายการของที่ใช้เหรียญแลกได้ ---
  Widget _buildItemsGrid() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _itemsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
        }
        
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('ไม่มีของรางวัลในขณะนี้'));
        }

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75, // ปรับสัดส่วนการ์ด
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildItemCard(item);
          },
        );
      },
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // รูปภาพสินค้า
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                item['items_url'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade100,
                  child: const Icon(Icons.image, color: Colors.grey, size: 40),
                ),
              ),
            ),
          ),
          // ข้อมูลสินค้า
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  item['items_name'] ?? 'ไม่มีชื่อ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on, color: Color(0xFFD4AF37), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${item['items_cost'] ?? 0}',
                      style: const TextStyle(
                        color: Colors.brown,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- หน้าต่าง (Bottom Sheet) สำหรับเลือกแพ็กเกจเติมเงิน ---
  void _showTopUpModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7, // ความสูง 70% ของจอ
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // ขีดลากด้านบน
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('เลือกแพ็กเกจเติมเหรียญ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
              ),
              // กริดแพ็กเกจ
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 คอลัมน์แบบในรูป
                    childAspectRatio: 2.2, // ความกว้างต่อความสูงของการ์ดแพ็กเกจ
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _topUpPackages.length,
                  itemBuilder: (context, index) {
                    final pkg = _topUpPackages[index];
                    return _buildPackageCard(pkg);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> pkg) {
    return InkWell(
      onTap: () {
        // ปิดหน้าต่าง Modal ลงมาก่อน
        Navigator.pop(context);
        
        // เรียกฟังก์ชันเติมเงินและส่งจำนวนเหรียญของแพ็กเกจนั้นไปบวกเพิ่ม
        _processTopUp(pkg['coins']);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.blue.shade100, width: 1.5),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${pkg['coins']} Coins',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              '฿${pkg['price']}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue.shade600),
            ),
          ],
        ),
      ),
    );
  }
}