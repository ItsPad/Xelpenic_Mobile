import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  final _supabase = Supabase.instance.client;
  final Color goldColor = const Color(0xFFDDAA55);
  final Color blackColor = const Color(0xFF141414);

  List<Map<String, dynamic>> bookingHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final userId = _supabase.auth.currentUser?.id ?? 'mock-uuid-1234-5678';
      
      final response = await _supabase
          .from('ticket')
          .select('*, movies(movie_title)') // ดึงแค่ชื่อหนังพอให้กระชับ
          .eq('tk_cus_id', userId)
          .order('tk_time', ascending: false);

      // จัดกลุ่มตั๋วที่ซื้อในเวลาเดียวกันให้เป็น 1 รายการ (1 บรรทัด)
      Map<String, Map<String, dynamic>> historyMap = {};
      
      for (var ticket in response) {
        String txTime = ticket['tk_time'].toString();
        
        if (!historyMap.containsKey(txTime)) {
          historyMap[txTime] = {
            'time': txTime,
            'movie_title': ticket['movies']['movie_title'],
            'seats': [ticket['tk_seat_no']],
            'total_price': ticket['tk_price'],
          };
        } else {
          historyMap[txTime]!['seats'].add(ticket['tk_seat_no']);
          historyMap[txTime]!['total_price'] += ticket['tk_price'];
        }
      }

      setState(() {
        bookingHistory = historyMap.values.toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching history: $e");
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
        title: Text('TRANSACTION HISTORY', style: TextStyle(color: blackColor, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: goldColor))
          : bookingHistory.isEmpty
              ? Center(child: Text("ไม่มีประวัติการทำรายการ", style: TextStyle(color: Colors.grey.shade500)))
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: bookingHistory.length,
                  separatorBuilder: (context, index) => const Divider(height: 30),
                  itemBuilder: (context, index) {
                    final item = bookingHistory[index];
                    DateTime txDate = DateTime.parse(item['time']).toLocal();
                    
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ไอคอนวันที่
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: blackColor, borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            children: [
                              Text(DateFormat('dd').format(txDate), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(DateFormat('MMM').format(txDate).toUpperCase(), style: TextStyle(color: goldColor, fontSize: 10, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // รายละเอียดแบบบรรทัด
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['movie_title'] ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: blackColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text("ที่นั่ง: ${(item['seats'] as List).join(', ')}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                        ),
                        
                        // ราคา
                        Text(
                          "฿${item['total_price']}", 
                          style: TextStyle(fontWeight: FontWeight.w800, color: goldColor, fontSize: 16),
                        )
                      ],
                    );
                  },
                ),
    );
  }
}