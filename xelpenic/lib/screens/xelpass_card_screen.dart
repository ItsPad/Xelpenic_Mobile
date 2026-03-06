import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 💡 เพิ่มการนำเข้า Supabase

class XelpassCardScreen extends StatefulWidget {
  // รับข้อมูลมาเป็นทางเลือก แต่ถ้าไม่มีจะดึงใหม่เอง
  final Map<String, dynamic>? xelpassData;

  const XelpassCardScreen({super.key, this.xelpassData});

  @override
  State<XelpassCardScreen> createState() => _XelpassCardScreenState();
}

class _XelpassCardScreenState extends State<XelpassCardScreen> {
  final _supabase = Supabase.instance.client;
  Timer? _timer;
  Duration _timeLeft = Duration.zero;
  Map<String, dynamic>? _currentXelData; // 💡 ตัวแปรเก็บข้อมูลสมาชิกในหน้านี้
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 💡 เริ่มการดึงข้อมูลสมาชิกใหม่เพื่อให้ชัวร์ว่าข้อมูลขึ้นแน่นอน
    _initXelpassData();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateTimeLeft();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // 💡 ฟังก์ชันดึงข้อมูลสมาชิกสดจาก Database
  Future<void> _initXelpassData() async {
    if (widget.xelpassData != null) {
      _currentXelData = widget.xelpassData;
      _isLoading = false;
      _calculateTimeLeft();
    } else {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final data = await _supabase
            .from('xelpass')
            .select()
            .eq('xel_user_id', user.id)
            .gte('xel_exp', DateTime.now().toIso8601String())
            .maybeSingle();

        if (mounted) {
          setState(() {
            _currentXelData = data;
            _isLoading = false;
          });
          _calculateTimeLeft();
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _calculateTimeLeft() {
    if (_currentXelData == null || _currentXelData!['xel_exp'] == null) return;

    final expiryDate = DateTime.parse(_currentXelData!['xel_exp']);
    final now = DateTime.now();
    final difference = expiryDate.difference(now);

    if (mounted) {
      setState(() {
        _timeLeft = difference.isNegative ? Duration.zero : difference;
      });
    }
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return "EXPIRED";
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return "${days}d ${hours}h ${minutes}m ${seconds}s";
  }

  @override
  Widget build(BuildContext context) {
    final bool hasData =
        _currentXelData != null; // ใช้ข้อมูลจากหน้านี้แทน widget
    final String xelType = _currentXelData?['xel_type'] ?? 'No Member';
    final Color goldColor = const Color(0xFFDDAA55);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "MY XELPASS",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFDDAA55)),
            ) // โหลดข้อมูลแป๊บนึง
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // 💡 บัตร XELPASS
                  AspectRatio(
                    aspectRatio: 1.586,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: hasData
                              ? [
                                  const Color(0xFF333333),
                                  const Color(0xFF111111),
                                ]
                              : [
                                  const Color(0xFF222222),
                                  const Color(0xFF222222),
                                ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: goldColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                        border: Border.all(
                          color: goldColor.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -20,
                            bottom: -20,
                            child: Text(
                              'X',
                              style: TextStyle(
                                fontSize: 200,
                                color: goldColor.withOpacity(0.05),
                                fontWeight: FontWeight.w100,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'XELPENIC',
                                      style: TextStyle(
                                        color: goldColor,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.nfc_rounded,
                                      color: Colors.white24,
                                      size: 30,
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  xelType.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.timer_outlined,
                                      color: Colors.white60,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      hasData
                                          ? "TIME LEFT: ${_formatDuration(_timeLeft)}"
                                          : "NO PASS ACTIVE",
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 12,
                                        fontFamily: 'monospace',
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
                  ),
                  const SizedBox(height: 40),
                  if (hasData) ...[
                    _buildBenefitItem(
                      Icons.check_circle_outline,
                      "รับสิทธิ์ชมภาพยนตร์ฟรีตามแพ็กเกจ",
                    ),
                    _buildBenefitItem(
                      Icons.fastfood_outlined,
                      "ส่วนลดพิเศษสำหรับชุดป๊อปคอร์นและเครื่องดื่ม",
                    ),
                    _buildBenefitItem(
                      Icons.event_seat_outlined,
                      "สิทธิ์จองที่นั่งล่วงหน้าในรอบพิเศษ",
                    ),
                  ] else
                    Column(
                      children: [
                        const Text(
                          "คุณยังไม่มี Xelpass ในขณะนี้",
                          style: TextStyle(color: Colors.white60),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: goldColor,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text("ไปที่หน้าแลกสิทธิ์"),
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFDDAA55), size: 20),
          const SizedBox(width: 16),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
