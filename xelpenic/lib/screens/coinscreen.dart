import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart'; // สำหรับสร้าง QR Code

class CoinScreen extends StatefulWidget {
  const CoinScreen({super.key});

  @override
  State<CoinScreen> createState() => _CoinScreenState();
}

class _CoinScreenState extends State<CoinScreen> {
  final _supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _itemsFuture;

  int _currentCoins = 0;
  String _profileImageUrl = '';
  String _userName = '';
  bool _isLoadingProfile = true;

  late final StreamSubscription<AuthState> _authStateSubscription;

  // แพ็กเกจเติมเงิน
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
    _fetchUserProfile();

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
    _itemsFuture = _supabase.from('items').select();
  }

  Future<void> _fetchUserProfile() async {
    setState(() => _isLoadingProfile = true);
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
          _profileImageUrl = response['customer_avatar_url'] ?? '';
          _userName = response['customer_username'] ?? 'User';
          _isLoadingProfile = false;
        });
      } else {
        setState(() {
          _currentCoins = 0;
          _profileImageUrl = '';
          _userName = 'Guest';
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      print('Error Fetching Profile: $e');
      setState(() => _isLoadingProfile = false);
    }
  }

  // --- 1. ระบบเติมเงินด้วย QR Code พร้อมจับเวลา ---
  void _showQRTopUpDialog(Map<String, dynamic> pkg) {
    Navigator.pop(context); // ปิดหน้าต่างเลือกแพ็กเกจก่อน

    int timeLeft = 180; // เวลา 3 นาที (180 วินาที)
    Timer? countdownTimer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (countdownTimer == null) {
              countdownTimer = Timer.periodic(const Duration(seconds: 1), (
                timer,
              ) {
                if (timeLeft > 0) {
                  setDialogState(() => timeLeft--);
                } else {
                  timer.cancel();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('หมดเวลาทำรายการ กรุณาลองใหม่'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              });
            }

            String minutes = (timeLeft ~/ 60).toString().padLeft(2, '0');
            String seconds = (timeLeft % 60).toString().padLeft(2, '0');

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'สแกนเพื่อเติมเหรียญ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ยอดชำระ: ฿${pkg['price']}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFDDAA55),
                      ),
                    ),
                    Text(
                      'ได้รับ: ${pkg['coins']} Coins',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: QrImageView(
                        data:
                            "topup-mock-payload-${DateTime.now().millisecondsSinceEpoch}",
                        version: QrVersions.auto,
                        size: 180.0,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'กรุณาชำระภายใน $minutes:$seconds',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () {
                          countdownTimer?.cancel();
                          Navigator.pop(context);
                          _processTopUpDatabase(
                            pkg['coins'],
                          ); // ดำเนินการอัปเดตลง DB จริง
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF141414),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'ชำระเงินเสร็จสิ้น',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        countdownTimer?.cancel();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'ยกเลิก',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) => countdownTimer?.cancel());
  }

  Future<void> _processTopUpDatabase(int coinsToAdd) async {
    try {
      final user = _supabase.auth.currentUser;
      final newTotalCoins = _currentCoins + coinsToAdd;

      if (user != null) {
        await _supabase
            .from('profiles')
            .update({'customer_points': newTotalCoins})
            .eq('customer_ID', user.id);
      }

      setState(() {
        _currentCoins = newTotalCoins;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Icon(
              Icons.monetization_on,
              color: Color(0xFFDDAA55),
              size: 60,
            ),
            content: Text(
              'เติมเงินสำเร็จ!\nคุณได้รับ $coinsToAdd Coins',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'ตกลง',
                  style: TextStyle(
                    color: Color(0xFFDDAA55),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เกิดข้อผิดพลาดในการเติมเงิน'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  // --- 2. ระบบแลกของรางวัล (Redeem Items) ---
  void _showItemDetailModal(Map<String, dynamic> item) {
    int itemCost = item['items_cost'] ?? 0;
    bool canAfford = _currentCoins >= itemCost; // เช็คว่าเหรียญพอไหม

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // รูปไอเทมขนาดใหญ่
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    item['items_url'] ?? '',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, size: 50),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                item['items_name'] ?? 'ไม่มีชื่อ',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(
                    Icons.monetization_on,
                    color: Color(0xFFDDAA55),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$itemCost Coins',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDDAA55),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // รายละเอียดจำลอง (เพราะใน DB ไม่มีคอลัมน์รายละเอียด)
              Text(
                'รายละเอียดของรางวัล:',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'สามารถนำไปแลกรับของรางวัลได้ที่เคาน์เตอร์ XELPENIC ทุกสาขา สินค้ามีจำนวนจำกัด กรุณาตรวจสอบก่อนกดแลก',
                style: TextStyle(color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 30),

              // ปุ่มกดแลก
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: canAfford
                      ? () => _processRedeemItem(item)
                      : null, // ปิดปุ่มถ้าเหรียญไม่พอ
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF141414),
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    canAfford ? 'แลกของรางวัล' : 'เหรียญไม่เพียงพอ',
                    style: TextStyle(
                      color: canAfford ? Colors.white : Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processRedeemItem(Map<String, dynamic> item) async {
    Navigator.pop(context); // ปิดหน้าต่างรายละเอียด

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFDDAA55)),
      ),
    );

    try {
      final user = _supabase.auth.currentUser;
      int itemCost = item['items_cost'];
      final newTotalCoins = _currentCoins - itemCost; // หักเหรียญ

      if (user != null) {
        // 1. อัปเดตเหรียญที่เหลือลงตาราง profiles
        await _supabase
            .from('profiles')
            .update({'customer_points': newTotalCoins})
            .eq('customer_ID', user.id);

        // 2. บันทึกลงตาราง change_log (ประวัติการแลกของ/คูปอง)
        await _supabase.from('change_log').insert({
          'chl_user_id': user.id,
          'chl_items_id': item['items_id'],
          'chl_redeem': false, // false = ยังไม่ได้ใช้งาน (ยังไม่ถูกพนักงานสแกน)
          // หมายเหตุ: chl_items_code ปล่อยให้ Supabase Gen UUID ให้เองตามที่ตั้งค่าไว้
        });
      }

      setState(() {
        _currentCoins = newTotalCoins;
      });

      if (mounted) Navigator.pop(context); // ปิด Loading

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Icon(
              Icons.card_giftcard,
              color: Colors.green,
              size: 60,
            ),
            content: Text(
              'แลกสำเร็จ!\nคุณได้รับ ${item['items_name']}\n(เหลือ $_currentCoins Coins)',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // ปิด Pop-up
                  // (เผื่ออนาคต) เด้งไปหน้าคูปองของฉัน
                },
                child: const Text(
                  'ตกลง',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  // ... (ส่วน UI อื่นๆ เหมือนเดิม)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F1),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
                const Icon(
                  Icons.monetization_on,
                  color: Color(0xFFD4AF37),
                  size: 20,
                ),
                const SizedBox(width: 4),
                _isLoadingProfile
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.brown,
                        ),
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
                  child: _profileImageUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.white, size: 20)
                      : null,
                ),
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  Expanded(child: _buildItemsGrid()),
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
                  const Icon(
                    Icons.monetization_on,
                    color: Colors.white,
                    size: 28,
                  ),
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
            ),
            child: const Text(
              'เติมเงิน',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showTopUpModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'เลือกแพ็กเกจเติมเหรียญ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _topUpPackages.length,
                  itemBuilder: (context, index) {
                    final pkg = _topUpPackages[index];
                    return InkWell(
                      onTap: () => _showQRTopUpDialog(pkg), // โยงไปเปิดหน้า QR
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xFFDDAA55),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${pkg['coins']} Coins',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '฿${pkg['price']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemsGrid() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _itemsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final items = snapshot.data ?? [];
        if (items.isEmpty)
          return const Center(child: Text('ไม่มีของรางวัลในขณะนี้'));

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return InkWell(
              onTap: () => _showItemDetailModal(
                item,
              ), // โยงไปเปิดหน้าต่างรายละเอียดสินค้า
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.network(
                          item['items_url'] ?? '',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text(
                            item['items_name'] ?? 'ไม่มีชื่อ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.monetization_on,
                                color: Color(0xFFD4AF37),
                                size: 14,
                              ),
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
              ),
            );
          },
        );
      },
    );
  }
}
