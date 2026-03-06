import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MyCouponsScreen extends StatefulWidget {
  const MyCouponsScreen({super.key});

  @override
  State<MyCouponsScreen> createState() => _MyCouponsScreenState();
}

class _MyCouponsScreenState extends State<MyCouponsScreen> {
  final _supabase = Supabase.instance.client;
  final Color goldColor = const Color(0xFFDDAA55);
  final Color blackColor = const Color(0xFF141414);

  List<dynamic> myCoupons = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCoupons();
  }

  Future<void> _fetchCoupons() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      // ดึงข้อมูลการแลกของ พร้อมดึงรายละเอียดจากตาราง items มาด้วย
      final response = await _supabase
          .from('change_log')
          .select('*, items(*)')
          .eq('chl_user_id', userId)
          .order('chl_id', ascending: false); // ใหม่สุดอยู่บน

      setState(() {
        myCoupons = response;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching coupons: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: blackColor),
        title: Text(
          'MY COUPONS',
          style: TextStyle(
            color: blackColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: goldColor))
          : myCoupons.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: myCoupons.length,
              itemBuilder: (context, index) {
                return _buildCouponCard(myCoupons[index]);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_activity_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "คุณยังไม่มีคูปองของรางวัล",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> couponData) {
    final item = couponData['items'];
    final bool isUsed =
        couponData['chl_redeem'] ?? false; // เช็คว่าใช้ไปหรือยัง
    final String qrData =
        couponData['chl_items_code']?.toString() ?? 'error-code';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isUsed
            ? Colors.grey.shade200
            : Colors.white, // ถ้าใช้แล้วให้เป็นสีเทา
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUsed ? Colors.grey.shade300 : goldColor.withOpacity(0.5),
        ),
        boxShadow: isUsed
            ? []
            : [
                BoxShadow(
                  color: goldColor.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Row(
        children: [
          // ส่วนรูปภาพ
          Container(
            width: 100,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(15),
              ),
              color: Colors.grey.shade100,
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(15),
              ),
              child: CachedNetworkImage(
                imageUrl: item['items_url'] ?? '',
                fit: BoxFit.cover,
                // ทำให้รูปเป็นขาวดำถ้าคูปองถูกใช้ไปแล้ว
                color: isUsed ? Colors.grey : null,
                colorBlendMode: isUsed ? BlendMode.saturation : null,
                errorWidget: (context, url, error) =>
                    const Icon(Icons.image, color: Colors.grey),
              ),
            ),
          ),

          // รอยปรุคูปอง
          Container(
            width: 1,
            height: 100,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Flex(
                  direction: Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    10,
                    (_) => SizedBox(
                      width: 1,
                      height: 5,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ส่วนข้อมูล และ QR Code
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['items_name'] ?? 'ไม่มีชื่อสินค้า',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isUsed ? Colors.grey.shade600 : blackColor,
                      decoration: isUsed
                          ? TextDecoration.lineThrough
                          : null, // ขีดฆ่าถ้าใช้แล้ว
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  if (isUsed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ใช้งานแล้ว',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    const Text(
                      'โปรดแสดง QR ให้พนักงาน',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ส่วน QR Code
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Opacity(
              opacity: isUsed ? 0.3 : 1.0, // ถ้าใช้แล้ว QR Code จะจางลง
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 70.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
