import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RedeemScreen extends StatefulWidget {
  const RedeemScreen({super.key});

  @override
  State<RedeemScreen> createState() => _RedeemScreenState();
}

class _RedeemScreenState extends State<RedeemScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  final Color goldColor = const Color(0xFFDDAA55);
  final Color blackColor = const Color(0xFF141414);

  Future<void> _processRedeem() async {
    if (_codeController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser!.id;
      final inputCode = _codeController.text.trim();

      // 1. ตรวจสอบโค้ดในตาราง change_log ว่ามีจริงและยังไม่ได้ถูกใช้งาน
      final logData = await _supabase
          .from('change_log')
          .select('*, items(items_name)')
          .eq('chl_items_code', inputCode)
          .eq('chl_redeem', false)
          .maybeSingle();

      if (logData == null) {
        throw Exception("โค้ดนี้ไม่ถูกต้อง หรือถูกใช้งานไปแล้ว");
      }

      // 2. อัปเดตสถานะคูปองเป็นใช้งานแล้ว (true)
      await _supabase
          .from('change_log')
          .update({'chl_redeem': true})
          .eq('chl_id', logData['chl_id']);

      // 3. Insert ข้อมูลลงตาราง xelpass เพื่อเปิดใช้งานบัตร
      DateTime now = DateTime.now();
      DateTime expire = DateTime(now.year, now.month + 1, now.day); // หมดอายุ +1 เดือน

      await _supabase.from('xelpass').insert({
        'xel_user_id': userId,
        'xel_type': logData['items']['items_name'] ?? 'XELPASS',
        'xel_start': now.toIso8601String(),
        'xel_exp': expire.toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Redeem สำเร็จ! บัตร XELPASS ของคุณถูกเปิดใช้งานแล้ว'), backgroundColor: Colors.green));
        Navigator.pop(context); // กลับหน้าเดิม
      }

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('REDEEM CODE', style: TextStyle(color: blackColor, fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.white, elevation: 0, iconTheme: IconThemeData(color: blackColor),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.qr_code_scanner, size: 60, color: Color(0xFFDDAA55)),
            const SizedBox(height: 20),
            Text('กรอกรหัส Redeem ของคุณ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: blackColor)),
            const SizedBox(height: 8),
            Text('นำโค้ดที่ได้จากการแลกของรางวัลมากรอกเพื่อเปิดใช้งานสิทธิพิเศษ', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 40),
            
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: 'วางโค้ดที่นี่ (เช่น 550e8400-e29b-...)',
                filled: true, fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: goldColor, width: 2)),
              ),
            ),
            
            const SizedBox(height: 40),
            _isLoading
                ? Center(child: CircularProgressIndicator(color: goldColor))
                : SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton(
                      onPressed: _processRedeem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blackColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('ยืนยันโค้ด', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
          ],
        ),
      ),
    );
  }
}