import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  Map<String, dynamic>? _xelpassData;

  final Color goldPrimary = const Color(0xFFDDAA55);
  final Color darkSecondary = const Color(0xFF1A1A1A);

  final List<Map<String, dynamic>> _topUpPackages = [
    {'coins': 100, 'price': 100},
    {'coins': 300, 'price': 300},
    {'coins': 500, 'price': 500},
    {'coins': 1000, 'price': 1000},
    {'coins': 2000, 'price': 2000},
    {'coins': 5000, 'price': 5000},
  ];

  final List<Map<String, dynamic>> _xelpassPackages = [
    {
      'id': 991,
      'name': 'Student Pass',
      'cost': 1500,
      'price_thb': 199,
      'desc': 'ดูฟรี 1 ครั้ง/เรื่อง พร้อมส่วนลดขนม 10%',
    },
    {
      'id': 992,
      'name': 'Standard Pass',
      'cost': 2500,
      'price_thb': 299,
      'desc': 'ดูฟรี 1 ครั้ง/เรื่อง และส่วนลดป๊อปคอร์น 20%',
    },
    {
      'id': 993,
      'name': 'Premium Pass',
      'cost': 4000,
      'price_thb': 499,
      'desc': 'ดูฟรีไม่จำกัดเรื่อง อัปเกรดที่นั่ง Honeymoon ฟรี',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchItems();
    _fetchUserProfile();
  }

  void _fetchItems() {
    _itemsFuture = _supabase.from('items').select().lt('items_id', 900);
  }

  // 💡 ปรับปรุงการดึงข้อมูล: ดึงค่าสดจาก Database เสมอ
  Future<void> _fetchUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        // ใช้ Future.wait เพื่อดึงข้อมูล Profile และ Xelpass พร้อมกัน ลด Latency
        final List<dynamic> results = await Future.wait([
          _supabase
              .from('profiles')
              .select()
              .eq('customer_ID', user.id)
              .single(),
          _supabase
              .from('xelpass')
              .select()
              .eq('xel_user_id', user.id)
              .gte('xel_exp', DateTime.now().toIso8601String())
              .maybeSingle(),
        ]);

        final profileRes = results[0];
        final xelData = results[1];

        if (mounted) {
          setState(() {
            _currentCoins = profileRes['customer_points'] ?? 0;
            _profileImageUrl = profileRes['customer_avatar_url'] ?? '';
            _userName = profileRes['customer_username'] ?? 'User';
            _xelpassData = xelData;
            _isLoadingProfile = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Fetch Profile Error: $e");
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  // 💡 ปรับปรุงลอจิกการอัปเดตเหรียญ: ป้องกันบั๊กเงินไม่ตรง
  Future<bool> _updateCoinsDB(int amount, bool isAddition) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // 1. ดึงค่าล่าสุดจาก DB ก่อนคำนวณ (ป้องกัน Race Condition ในแอป)
      final currentData = await _supabase
          .from('profiles')
          .select('customer_points')
          .eq('customer_ID', userId)
          .single();
      int latestCoins = currentData['customer_points'] ?? 0;

      // 2. คำนวณยอดใหม่
      int newTotal = isAddition ? latestCoins + amount : latestCoins - amount;
      if (newTotal < 0) return false; // ป้องกันเงินติดลบ

      // 3. Update ลง Database
      await _supabase
          .from('profiles')
          .update({'customer_points': newTotal})
          .eq('customer_ID', userId);

      // 4. สำคัญที่สุด: Refetch ข้อมูลใหม่ทั้งหมดจาก DB เพื่ออัปเดต UI ให้ตรงความจริง
      await _fetchUserProfile();
      return true;
    } catch (e) {
      debugPrint("Update Coins Error: $e");
      return false;
    }
  }

  Future<String?> _createRedeemCode(int itemsId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;
      final res = await _supabase
          .from('change_log')
          .insert({
            'chl_user_id': userId,
            'chl_items_id': itemsId,
            'chl_redeem': false,
          })
          .select()
          .single();
      return res['chl_items_code'].toString();
    } catch (e) {
      return null;
    }
  }

  void _showResult(String title, String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars_rounded, color: Color(0xFFDDAA55), size: 80),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 8),
            const Text(
              "ได้รับรหัสสำหรับการใช้งานแล้ว",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SelectableText(
                code,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1,
                  color: Colors.brown,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "ตกลง",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTopUpSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isProcessing = false;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Top Up Coins",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isProcessing)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: Colors.brown),
                    )
                  else
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: _topUpPackages
                          .map(
                            (pkg) => InkWell(
                              onTap: () async {
                                setSheetState(() => isProcessing = true);
                                final ok = await _updateCoinsDB(
                                  pkg['coins'],
                                  true,
                                );
                                if (mounted) {
                                  Navigator.pop(ctx);
                                  if (ok) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "เติมเงินสำเร็จ +${pkg['coins']} Coins",
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.monetization_on,
                                      color: goldPrimary,
                                      size: 20,
                                    ),
                                    Text(
                                      "${pkg['coins']}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "฿${pkg['price']}",
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showXelpassSheet(Map<String, dynamic> pass) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isBusy = false;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bool hasActivePass = _xelpassData != null;

            return Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    color: Color(0xFFDDAA55),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    pass['name'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pass['desc'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),

                  if (hasActivePass) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Text(
                        "คุณมีแพ็กเกจ ${_xelpassData!['xel_type']} ใช้งานอยู่แล้ว",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  if (isBusy)
                    const CircularProgressIndicator(color: Colors.brown)
                  else
                    Column(
                      children: [
                        _buildRedeemButton(
                          hasActivePass
                              ? "ALREADY ACTIVE"
                              : "REDEEM WITH ${pass['cost']} COINS",
                          hasActivePass ? Colors.grey.shade300 : goldPrimary,
                          hasActivePass ? Colors.grey.shade600 : Colors.black,
                          (hasActivePass ||
                                  _currentCoins < (pass['cost'] as int))
                              ? null
                              : () async {
                                  setSheetState(() => isBusy = true);
                                  final ok = await _updateCoinsDB(
                                    pass['cost'],
                                    false,
                                  );
                                  if (ok) {
                                    final code = await _createRedeemCode(
                                      pass['id'],
                                    );
                                    if (mounted) {
                                      Navigator.pop(ctx);
                                      if (code != null)
                                        _showResult(pass['name'], code);
                                    }
                                  } else {
                                    setSheetState(() => isBusy = false);
                                  }
                                },
                        ),
                        const SizedBox(height: 12),
                        _buildRedeemButton(
                          hasActivePass
                              ? "ALREADY ACTIVE"
                              : "BUY WITH CASH ฿${pass['price_thb']}",
                          hasActivePass ? Colors.grey.shade100 : Colors.black,
                          hasActivePass ? Colors.grey.shade400 : Colors.white,
                          hasActivePass
                              ? null
                              : () async {
                                  setSheetState(() => isBusy = true);
                                  final code = await _createRedeemCode(
                                    pass['id'],
                                  );
                                  await _fetchUserProfile();
                                  if (mounted) {
                                    Navigator.pop(ctx);
                                    if (code != null)
                                      _showResult(pass['name'], code);
                                  }
                                },
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showItemSheet(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isBusy = false;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final int cost = item['items_cost'] ?? 0;
            return Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(
                      item['items_url'] ?? '',
                      height: 160,
                      width: 240,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    item['items_name'],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (isBusy)
                    const CircularProgressIndicator(color: Colors.brown)
                  else
                    _buildRedeemButton(
                      "REDEEM FOR $cost COINS",
                      Colors.black,
                      Colors.white,
                      _currentCoins < cost
                          ? null
                          : () async {
                              setSheetState(() => isBusy = true);
                              final ok = await _updateCoinsDB(cost, false);
                              if (ok) {
                                final code = await _createRedeemCode(
                                  item['items_id'],
                                );
                                if (mounted) {
                                  Navigator.pop(ctx);
                                  if (code != null)
                                    _showResult(item['items_name'], code);
                                }
                              } else {
                                setSheetState(() => isBusy = false);
                              }
                            },
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRedeemButton(
    String label,
    Color bg,
    Color text,
    VoidCallback? action,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: text,
          disabledBackgroundColor: Colors.grey.shade100,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        onPressed: action,
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: darkSecondary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [darkSecondary, const Color(0xFF333333)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        "YOUR BALANCE",
                        style: TextStyle(
                          color: goldPrimary.withOpacity(0.8),
                          fontSize: 12,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.monetization_on,
                            color: goldPrimary,
                            size: 36,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "$_currentCoins",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showTopUpSheet,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text(
                          "TOP UP COINS",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: goldPrimary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("XELPASS MEMBERSHIP"),
                  const SizedBox(height: 16),
                  _buildXelpassList(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Divider(),
                  ),
                  _buildSectionTitle("EXCLUSIVE REWARDS"),
                  const SizedBox(height: 16),
                  _buildRewardsGrid(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: Colors.black,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildXelpassList() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _xelpassPackages.length,
        itemBuilder: (context, i) {
          final p = _xelpassPackages[i];
          return GestureDetector(
            onTap: () => _showXelpassSheet(p),
            child: Container(
              width: 260,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: darkSecondary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: goldPrimary.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    color: Color(0xFFDDAA55),
                    size: 28,
                  ),
                  const Spacer(),
                  Text(
                    p['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    "${p['cost']} Coins",
                    style: TextStyle(
                      color: goldPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRewardsGrid() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _itemsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final items = snapshot.data!;
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 0.75,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            return GestureDetector(
              onTap: () => _showItemSheet(item),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: Image.network(
                          item['items_url'] ?? '',
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['items_name'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "${item['items_cost']} Coins",
                            style: TextStyle(
                              color: goldPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
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
