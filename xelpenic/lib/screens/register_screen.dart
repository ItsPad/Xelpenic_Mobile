import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:google_fonts/google_fonts.dart'; // ถ้าใช้ฟอนต์ Google

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // --- Controllers สำหรับรับค่าข้อมูลแต่ละช่อง ---
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  // สำหรับช่องวันเกิด (แยกเป็น วัน/เดือน/ปี)
  final _dayController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();

  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool _acceptTerms = false;

  // --- ฟังก์ชันสมัครสมาชิก ---
  Future<void> _handleRegister() async {
    // 1. ตรวจสอบเงื่อนไขพื้นฐานก่อน
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณายอมรับเงื่อนไขการใช้งานครับ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('รหัสผ่านไม่ตรงกันครับ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // เช็คว่ากรอกวันเกิดครบไหม
    if (_dayController.text.isEmpty ||
        _monthController.text.isEmpty ||
        _yearController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกวันเกิดให้ครบถ้วน'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. สร้างบัญชีใน Auth ของ Supabase
      final res = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. ถ้าสมัครสำเร็จ ให้ Insert ข้อมูลลงตาราง profiles
      if (res.user != null) {
        // จัดรูปแบบวันเกิดให้เป็น YYYY-MM-DD และเติม 0 ข้างหน้าถ้าพิมพ์มาหลักเดียว
        String year = _yearController.text.trim();
        String month = _monthController.text.trim().padLeft(2, '0');
        String day = _dayController.text.trim().padLeft(2, '0');
        String birthDate = '$year-$month-$day';

        await _supabase.from('profiles').insert({
          'customer_ID': res.user!.id,
          'customer_username': _fullNameController.text.trim(),
          'customer_avatar_url':
              'https://uxwing.com/wp-content/themes/uxwing/download/peoples-avatars/man-user-circle-icon.png',
          'customer_dob': birthDate, // <-- บันทึกวันเกิดลงคอลัมน์นี้
          'customer_points': 0,
          'customer_exp': 0,
        });
      }

      if (mounted) {
        Navigator.pop(context); // สมัครเสร็จเด้งกลับหน้า Login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('สมัครสำเร็จ! กรุณาเข้าสู่ระบบ'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('==== ❌ Error สมัครสมาชิก ====');
      print(e);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('สมัครไม่สำเร็จ: $e'),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Widget ช่วยสร้างช่องกรอกข้อมูล ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(prefixIcon, color: const Color(0xFFDDAA55)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFDDAA55)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('สร้างบัญชีใหม่'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.brown,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.stars_rounded, size: 80, color: Color(0xFFDDAA55)),
            const SizedBox(height: 16),
            const Text(
              'สร้างบัญชีใหม่',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 40),

            _buildTextField(
              controller: _fullNameController,
              labelText: 'ชื่อ-สกุล',
              prefixIcon: Icons.person,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              labelText: 'อีเมล',
              prefixIcon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _passwordController,
              labelText: 'รหัสผ่าน',
              prefixIcon: Icons.lock,
              obscureText: true,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(height: 4, width: 80, color: Colors.red),
                const SizedBox(width: 8),
                Container(height: 4, width: 80, color: Colors.yellow),
                const SizedBox(width: 8),
                Container(height: 4, width: 80, color: Colors.green),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _confirmPasswordController,
              labelText: 'ยืนยันรหัสผ่าน',
              prefixIcon: Icons.lock_outline,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              labelText: 'เบอร์โทรศัพท์',
              prefixIcon: Icons.phone_android,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // ช่องวันเกิด (แยก วัน / เดือน / ปี )
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _dayController,
                    labelText: 'วัน',
                    prefixIcon: Icons.calendar_today,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTextField(
                    controller: _monthController,
                    labelText: 'เดือน',
                    prefixIcon: Icons.calendar_month,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTextField(
                    controller: _yearController,
                    labelText: 'ปี (ค.ศ.)',
                    prefixIcon: Icons.calendar_today_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Checkbox(
                  value: _acceptTerms,
                  activeColor: const Color(0xFFDDAA55),
                  onChanged: (value) => setState(() => _acceptTerms = value!),
                ),
                const Expanded(
                  child: Text(
                    'ฉันยอมรับข้อกำหนดและเงื่อนไขใบ\nข้อกำหนดและเงื่อนไขเพิ่มเติม',
                    style: TextStyle(fontSize: 12, color: Colors.brown),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _isLoading
                ? const CircularProgressIndicator(color: Color(0xFFDDAA55))
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDDAA55),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'สมัครสมาชิก',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

            const SizedBox(height: 16),
            InkWell(
              onTap: () => Navigator.pop(context),
              child: const Text(
                'มีบัญชีอยู่แล้ว? เข้าสู่ระบบ',
                style: TextStyle(
                  color: Colors.brown,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
