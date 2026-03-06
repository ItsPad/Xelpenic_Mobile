import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart'; // อย่าลืมลง package นี้นะครับ

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  final _supabase = Supabase.instance.client;
  final Color goldColor = const Color(0xFFDDAA55);
  final Color blackColor = const Color(0xFF141414);

  List<List<dynamic>> groupedTickets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyTickets();
  }

  Future<void> _fetchMyTickets() async {
    try {
      final userId = _supabase.auth.currentUser?.id ?? 'mock-uuid-1234-5678';

      final response = await _supabase
          .from('ticket')
          .select('*, movies(*), cinema(*), theater(*), showtime(*)')
          .eq('tk_cus_id', userId)
          .order('tk_time', ascending: false); // ใบใหม่สุดอยู่บน

      // --- อัปเดตลอจิกจัดกลุ่มให้รองรับการซื้อตั๋วหลายเรื่องแบบเป๊ะๆ ---
      Map<String, List<dynamic>> tempGroup = {};
      for (var ticket in response) {
        // ใช้ tk_st_id (รหัสรอบฉาย) และ tk_time (เวลาซื้อ) เป็นตัวจัดกลุ่ม
        // เพื่อให้แยกตั๋วคนละรอบ หรือคนละบิลออกจากกันชัดเจน
        String groupId = "${ticket['tk_st_id']}_${ticket['tk_time']}";

        if (!tempGroup.containsKey(groupId)) {
          tempGroup[groupId] = [];
        }
        tempGroup[groupId]!.add(ticket);
      }

      setState(() {
        groupedTickets = tempGroup.values.toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching tickets: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7), // พื้นหลังสีขาวอมครีม
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: blackColor),
        title: Text(
          'MY TICKETS',
          style: TextStyle(
            color: blackColor,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: goldColor))
          : groupedTickets.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: groupedTickets.length,
              itemBuilder: (context, index) {
                return _buildTicketCard(groupedTickets[index]);
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
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "คุณยังไม่มีตั๋วภาพยนตร์",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: goldColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'จองตั๋วเลย',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ดีไซน์บัตรตั๋วหนัง
  Widget _buildTicketCard(List<dynamic> ticketsInBooking) {
    // ดึงข้อมูลภาพยนตร์และโรงจากตั๋วใบแรกในกลุ่ม (เพราะซื้อพร้อมกัน ข้อมูลจะเหมือนกัน)
    final firstTicket = ticketsInBooking[0];
    final movie = firstTicket['movies'];
    final cinema = firstTicket['cinema'];
    final theater = firstTicket['theater'];
    final showtime = firstTicket['showtime'];

    // รวบรวมที่นั่งทั้งหมดในบิลนี้
    List<String> seats = ticketsInBooking
        .map((t) => t['tk_seat_no'].toString())
        .toList();

    // คำนวณราคารวม
    int totalPrice = ticketsInBooking.fold(
      0,
      (sum, t) => sum + (t['tk_price'] as int),
    );

    // แปลงเวลาฉาย
    DateTime showDateTime = DateTime.parse(showtime['st_time']).toLocal();
    String formattedDate = DateFormat('dd MMM yyyy').format(showDateTime);
    String formattedTime = DateFormat('HH:mm').format(showDateTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: blackColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: goldColor.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // ส่วนบน: ข้อมูลหนังและรอบฉาย
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // โปสเตอร์หนัง
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: movie['movie_post'] ?? '',
                    width: 80,
                    height: 120,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      width: 80,
                      height: 120,
                      color: Colors.grey.shade800,
                      child: Icon(Icons.movie, color: goldColor),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // รายละเอียด
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie['movie_title'] ?? 'Unknown Movie',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cinema['cm_name'] ?? 'XELPENIC CINEMA',
                        style: TextStyle(
                          color: goldColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        theater['tt_name'] ?? 'THEATER',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // กล่อง วันที่และเวลา
                      Row(
                        children: [
                          _buildInfoBox('DATE', formattedDate),
                          const SizedBox(width: 16),
                          _buildInfoBox('TIME', formattedTime),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // รอยปรุฉีกตั๋ว (ดีไซน์เจ๋งๆ)
          Row(
            children: [
              Container(
                width: 10,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFFFDFBF7),
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(10),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Flex(
                        direction: Axis.horizontal,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: List.generate(
                          (constraints.constrainWidth() / 10).floor(),
                          (index) => SizedBox(
                            width: 5,
                            height: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Container(
                width: 10,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFFFDFBF7),
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(10),
                  ),
                ),
              ),
            ],
          ),

          // ส่วนล่าง: ที่นั่ง และ QR Code
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SEATS',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        seats.join(', '),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'TOTAL',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '฿ ${NumberFormat('#,###').format(totalPrice)}',
                        style: TextStyle(
                          color: goldColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // --- แสดง QR Code จำลอง ---
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: QrImageView(
                    data: firstTicket['tk_id'].toString(), // ใช้ ID ตั๋วมาทำ QR
                    version: QrVersions.auto,
                    size: 70.0,
                    backgroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
