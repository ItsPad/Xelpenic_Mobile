import 'dart:async'; // สำหรับทำระบบนับถอยหลัง
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart'; // สำหรับสร้าง QR Code
import 'my_tickets_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> movie;
  final String cinemaName;
  final String theaterName;
  final String showTime;
  final Map<String, dynamic> showtimeData;

  const SeatSelectionScreen({
    super.key,
    required this.movie,
    required this.cinemaName,
    required this.theaterName,
    required this.showTime,
    required this.showtimeData,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  final _supabase = Supabase.instance.client;

  final Color goldColor = const Color(0xFFDDAA55);
  final Color blackColor = const Color(0xFF141414);

  final int normalPrice = 120;
  final int honeymoonPrice = 150;

  List<String> selectedSeats = [];
  List<String> bookedSeats = [];
  bool isLoadingSeats = true;

  @override
  void initState() {
    super.initState();
    _fetchBookedSeats();
  }

  Future<void> _fetchBookedSeats() async {
    try {
      final response = await _supabase
          .from('ticket')
          .select('tk_seat_no')
          .eq('tk_st_id', widget.showtimeData['st_id']);

      List<String> fetchedSeats = [];
      for (var row in response) {
        if (row['tk_seat_no'] != null) {
          fetchedSeats.add(row['tk_seat_no'].toString());
        }
      }

      setState(() {
        bookedSeats = fetchedSeats;
        isLoadingSeats = false;
      });
    } catch (e) {
      print("Error fetching booked seats: $e");
      setState(() => isLoadingSeats = false);
    }
  }

  int get totalPrice {
    int total = 0;
    for (String seat in selectedSeats) {
      if (seat.startsWith('A') ||
          seat.startsWith('B') ||
          seat.startsWith('C')) {
        total += honeymoonPrice;
      } else {
        total += normalPrice;
      }
    }
    return total;
  }

  int get earnedExp {
    double exp = 0;
    for (String seat in selectedSeats) {
      if (seat.startsWith('A') ||
          seat.startsWith('B') ||
          seat.startsWith('C')) {
        exp += honeymoonPrice * 0.12;
      } else {
        exp += normalPrice * 0.10;
      }
    }
    return exp.round();
  }

  void _toggleSeat(String seatId) {
    if (bookedSeats.contains(seatId)) return;

    setState(() {
      if (selectedSeats.contains(seatId)) {
        selectedSeats.remove(seatId);
      } else {
        selectedSeats.add(seatId);
      }
    });
  }

  // --- ฟังก์ชันหลักในการบันทึกข้อมูลตั๋วและ EXP (ใช้ร่วมกันทั้ง 2 วิธีจ่ายเงิน) ---
  Future<void> _finalizePayment() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          Center(child: CircularProgressIndicator(color: goldColor)),
    );

    try {
      final userId = _supabase.auth.currentUser?.id ?? 'mock-uuid-1234-5678';
      String transactionTime = DateTime.now().toIso8601String();

      // บันทึกตั๋วลง DB
      for (String seat in selectedSeats) {
        int price =
            (seat.startsWith('A') ||
                seat.startsWith('B') ||
                seat.startsWith('C'))
            ? honeymoonPrice
            : normalPrice;

        await _supabase.from('ticket').insert({
          'tk_movie_id': widget.movie['movie_id'],
          'tk_tt_id': widget.showtimeData['st_tt_id'],
          'tk_st_id': widget.showtimeData['st_id'],
          'tk_cus_id': userId,
          'tk_cm_id': widget.showtimeData['st_cm_id'],
          'tk_seat_no': seat,
          'tk_price': price,
          'tk_time': transactionTime,
        });
      }

      // อัปเดต EXP
      final userProfileForExp = await _supabase
          .from('profiles')
          .select('customer_exp')
          .eq('customer_ID', userId)
          .single();

      int currentExp = userProfileForExp['customer_exp'] ?? 0;
      await _supabase
          .from('profiles')
          .update({'customer_exp': currentExp + earnedExp})
          .eq('customer_ID', userId);

      if (mounted) Navigator.pop(context); // ปิด Loading

      _showSuccessDialog();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- ทางเลือกที่ 1: จ่ายด้วย Points ---
  Future<void> _processPointsPayment() async {
    Navigator.pop(context); // ปิด BottomSheet
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          Center(child: CircularProgressIndicator(color: goldColor)),
    );

    try {
      final userId = _supabase.auth.currentUser?.id ?? 'mock-uuid-1234-5678';

      // เช็คและหักพอยต์
      final userProfile = await _supabase
          .from('profiles')
          .select('customer_points')
          .eq('customer_ID', userId)
          .single();

      int currentPoints = userProfile['customer_points'] ?? 0;

      if (currentPoints < totalPrice) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('พอยต์ของคุณไม่เพียงพอ!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await _supabase
          .from('profiles')
          .update({'customer_points': currentPoints - totalPrice})
          .eq('customer_ID', userId);

      if (mounted) Navigator.pop(context); // ปิด Loading

      // ไปบันทึกตั๋วต่อ
      await _finalizePayment();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- ทางเลือกที่ 2: โชว์หน้า QR Code แบบมีเวลานับถอยหลัง ---
  void _showQRDialog() {
    Navigator.pop(context); // ปิด BottomSheet เดิม

    int timeLeft = 180; // เวลา 3 นาที (180 วินาที)
    Timer? countdownTimer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          // จำเป็นต้องใช้เพื่ออัปเดตเวลาใน Dialog
          builder: (context, setDialogState) {
            // เริ่มนับเวลาถอยหลัง
            if (countdownTimer == null) {
              countdownTimer = Timer.periodic(const Duration(seconds: 1), (
                timer,
              ) {
                if (timeLeft > 0) {
                  setDialogState(() => timeLeft--);
                } else {
                  timer.cancel();
                  Navigator.pop(context); // หมดเวลา ปิดหน้า QR
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
                    Text(
                      'สแกนเพื่อชำระเงิน',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: blackColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ยอดชำระ: ฿${NumberFormat('#,###').format(totalPrice)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: goldColor,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // QR Code จำลอง
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
                            "promptpay-mock-payload-${DateTime.now().millisecondsSinceEpoch}",
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // เวลานับถอยหลัง
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

                    // ปุ่มยืนยันการโอนเงิน
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () {
                          countdownTimer?.cancel();
                          Navigator.pop(context); // ปิดหน้า QR
                          _finalizePayment(); // บันทึกตั๋ว
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: blackColor,
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
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        countdownTimer?.cancel();
                        Navigator.pop(context); // ยกเลิก
                      },
                      child: const Text(
                        'ยกเลิกการทำรายการ',
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
    ).then((_) => countdownTimer?.cancel()); // เคลียร์ Timer ถ้า Dialog ปิดไป
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Icon(Icons.check_circle, color: goldColor, size: 60),
        content: Text(
          'การจองสำเร็จ!\nคุณได้รับ +$earnedExp EXP',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // ปิด Popup
              Navigator.pop(context); // กลับหน้า Movie Detail
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyTicketsScreen(),
                ),
              );
            },
            child: Text(
              'ดูตั๋วของฉัน',
              style: TextStyle(
                color: goldColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ชำระเงิน',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: blackColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: blackColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: goldColor.withOpacity(0.2),
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
                          Text(
                            'ยอดรวมที่ต้องชำระ',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '฿ ${NumberFormat('#,###').format(totalPrice)}',
                            style: TextStyle(
                              color: goldColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'EXP ที่จะได้รับ',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '+$earnedExp EXP',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _buildPaymentButton(
                  icon: Icons.stars_rounded,
                  title: 'ชำระด้วย XELPENIC Points',
                  subtitle: 'ใช้พอยต์ในระบบเพื่อแลกตั๋วหนัง',
                  onTap: _processPointsPayment, // โยงไปหักพอยต์
                ),
                const SizedBox(height: 12),

                _buildPaymentButton(
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'ชำระด้วย QR PromptPay',
                  subtitle: 'สแกนจ่ายผ่านแอปธนาคาร',
                  onTap: _showQRDialog, // โยงไปเปิดหน้า QR
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: goldColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: goldColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: blackColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: blackColor),
        title: Column(
          children: [
            Text(
              widget.movie['movie_title'] ?? 'Title',
              style: TextStyle(
                color: blackColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${widget.cinemaName} | ${widget.theaterName} | ${widget.showTime}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 20),
            child: Column(
              children: [
                Container(
                  height: 40,
                  width: MediaQuery.of(context).size.width * 0.8,
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: goldColor, width: 4)),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.elliptical(200, 40),
                    ),
                  ),
                  alignment: Alignment.topCenter,
                  child: const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      'หน้าจอ (SCREEN)',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoadingSeats
                ? Center(child: CircularProgressIndicator(color: goldColor))
                : InteractiveViewer(
                    panEnabled: true,
                    constrained: false,
                    boundaryMargin: const EdgeInsets.all(80),
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: _buildSeatGrid(),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                  Colors.white,
                  goldColor,
                  'Normal\n฿$normalPrice',
                ),
                const SizedBox(width: 20),
                _buildLegendItem(
                  goldColor.withOpacity(0.1),
                  goldColor,
                  'Honeymoon\n฿$honeymoonPrice',
                ),
                const SizedBox(width: 20),
                _buildLegendItem(blackColor, blackColor, 'Booked'),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildSeatGrid() {
    List<String> rows = [
      'M',
      'L',
      'K',
      'J',
      'I',
      'H',
      'G',
      'F',
      'E',
      'D',
      'C',
      'B',
      'A',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: rows.map((row) {
          bool isHoneymoon = row == 'A' || row == 'B' || row == 'C';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  child: Text(
                    row,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ...List.generate(20, (index) {
                  if (index == 10) return const SizedBox(width: 30);
                  String seatId = '$row${index + 1}';
                  bool isBooked = bookedSeats.contains(seatId);
                  bool isSelected = selectedSeats.contains(seatId);

                  return GestureDetector(
                    onTap: () => _toggleSeat(seatId),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isBooked
                            ? blackColor
                            : (isSelected
                                  ? goldColor
                                  : (isHoneymoon
                                        ? goldColor.withOpacity(0.1)
                                        : Colors.white)),
                        border: Border.all(
                          color: isBooked ? blackColor : goldColor,
                          width: 1.5,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                          bottomLeft: Radius.circular(2),
                          bottomRight: Radius.circular(2),
                        ),
                      ),
                      child: isBooked
                          ? const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            )
                          : (isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null),
                    ),
                  );
                }),
                const SizedBox(width: 10),
                SizedBox(
                  width: 20,
                  child: Text(
                    row,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegendItem(Color bgColor, Color borderColor, String label) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ที่นั่งที่เลือก',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 200,
                      child: Text(
                        selectedSeats.isEmpty ? '-' : selectedSeats.join(', '),
                        style: TextStyle(
                          color: blackColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'ราคารวม',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '฿ ${NumberFormat('#,###').format(totalPrice)}',
                      style: TextStyle(
                        color: goldColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: selectedSeats.isEmpty
                    ? null
                    : _showPaymentBottomSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: goldColor,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'ดำเนินการต่อ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
