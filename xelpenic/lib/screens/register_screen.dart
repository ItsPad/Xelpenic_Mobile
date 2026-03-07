import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // --- Controllers ---
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dayController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();

  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  // --- ฟังก์ชันแจ้งเตือน (SnackBar) ---
  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.warning_rounded : Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3), // โชว์ 3 วินาทีแล้วหายไป
      ),
    );
  }

  // --- ฟังก์ชันหลักในการสมัครสมาชิก (ดักจับทุกช่อง) ---
  Future<void> _handleRegister() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();
    final phone = _phoneController.text.trim();
    final day = _dayController.text.trim();
    final month = _monthController.text.trim();
    final year = _yearController.text.trim();

    // ---------------------------------------------------------
    // 🛑 ด่านที่ 1: ตรวจสอบข้อมูลทีละช่องแบบละเอียด (Validation)
    // ---------------------------------------------------------

    // 1. เช็กชื่อ
    if (fullName.isEmpty) {
      _showMessage('กรุณากรอก "ชื่อ-สกุล" ครับ');
      return;
    }

    // 2. เช็กอีเมล
    if (email.isEmpty) {
      _showMessage('กรุณากรอก "อีเมล" ครับ');
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showMessage('รูปแบบ "อีเมล" ไม่ถูกต้อง (เช่น user@mail.com)');
      return;
    }

    // 3. เช็กรหัสผ่าน
    if (password.isEmpty) {
      _showMessage('กรุณากรอก "รหัสผ่าน" ครับ');
      return;
    }
    if (password.length < 6) {
      _showMessage('"รหัสผ่าน" ต้องมีอย่างน้อย 6 ตัวอักษรขึ้นไปครับ');
      return;
    }

    // 4. เช็กยืนยันรหัสผ่าน
    if (confirm.isEmpty) {
      _showMessage('กรุณากรอก "ยืนยันรหัสผ่าน" ครับ');
      return;
    }
    if (password != confirm) {
      _showMessage('รหัสผ่านและการยืนยันรหัสผ่าน "ไม่ตรงกัน" ครับ');
      return;
    }

    // 5. เช็กเบอร์โทรศัพท์
    if (phone.isEmpty) {
      _showMessage('กรุณากรอก "เบอร์โทรศัพท์" ครับ');
      return;
    }
    if (!RegExp(r'^[0-9]{9,10}$').hasMatch(phone)) {
      _showMessage('"เบอร์โทรศัพท์" ต้องเป็นตัวเลข 9-10 หลักเท่านั้นครับ');
      return;
    }

    // 6. เช็กวัน/เดือน/ปี เกิด
    if (day.isEmpty || month.isEmpty || year.isEmpty) {
      _showMessage('กรุณากรอก "วัน/เดือน/ปีเกิด" ให้ครบทุกช่องครับ');
      return;
    }

    final d = int.tryParse(day);
    final m = int.tryParse(month);
    final y = int.tryParse(year);

    if (d == null || d < 1 || d > 31) {
      _showMessage('กรุณากรอก "วันเกิด" ให้ถูกต้อง (1 - 31) ครับ');
      return;
    }
    if (m == null || m < 1 || m > 12) {
      _showMessage('กรุณากรอก "เดือนเกิด" ให้ถูกต้อง (1 - 12) ครับ');
      return;
    }
    final currentYear = DateTime.now().year;
    if (y == null || y < 1900 || y > currentYear) {
      _showMessage('กรุณากรอก "ปีเกิด (ค.ศ.)" ให้ถูกต้อง (ไม่เกินปีปัจจุบัน) ครับ');
      return;
    }

    // ดักวันที่แปลกๆ (เช่น 31 กุมภาพันธ์)
    try {
      final checkDate = DateTime(y, m, d);
      if (checkDate.year != y || checkDate.month != m || checkDate.day != d) {
        _showMessage('วันที่นี้ไม่มีอยู่จริงในปฏิทิน กรุณาตรวจสอบใหม่ครับ');
        return;
      }
    } catch (_) {
      _showMessage('วันที่เกิดไม่ถูกต้อง กรุณาตรวจสอบใหม่ครับ');
      return;
    }

    // 7. เช็กการยอมรับเงื่อนไข
    if (!_acceptTerms) {
      _showMessage('กรุณากดติ๊กถูกเพื่อ "ยอมรับข้อกำหนดและเงื่อนไข" ก่อนครับ');
      return;
    }

    // ---------------------------------------------------------
    // ✅ ด่านที่ 2: ข้อมูลผ่านหมดแล้ว เริ่มส่งเข้า Database
    // ---------------------------------------------------------
    setState(() => _isLoading = true);

    try {
      final res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (res.user != null) {
        // จัดรูปแบบวันเกิดให้เป็น YYYY-MM-DD
        final birthDate = '$year-${month.padLeft(2, '0')}-${day.padLeft(2, '0')}';

        await _supabase.from('profiles').insert({
          'customer_ID': res.user!.id,
          'customer_username': fullName,
          'customer_avatar_url': 'https://uxwing.com/wp-content/themes/uxwing/download/peoples-avatars/man-user-circle-icon.png',
          'customer_dob': birthDate,
          'customer_phone': phone, // เก็บเบอร์โทรด้วยเลย
          'customer_points': 0,
          'customer_exp': 0,
        });

        if (mounted) {
          _showMessage('สมัครสมาชิกสำเร็จ! กรุณาเข้าสู่ระบบ', isError: false);
          Navigator.pop(context); // เด้งกลับไปหน้าล็อกอิน
        }
      }
    } on AuthException catch (e) {
      // แจ้ง Error จาก Supabase เช่น มีอีเมลนี้ในระบบแล้ว
      if (e.message.contains('already registered')) {
        _showMessage('อีเมลนี้ถูกใช้งานไปแล้ว กรุณาใช้อีเมลอื่นครับ');
      } else {
        _showMessage(e.message);
      }
    } catch (e) {
      _showMessage('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI สร้างช่องกรอกข้อมูล ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFDDAA55)),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDDAA55))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, foregroundColor: Colors.brown),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.stars_rounded, size: 70, color: Color(0xFFDDAA55)),
            const SizedBox(height: 12),
            const Text('สร้างบัญชี XELPENIC', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.brown)),
            const SizedBox(height: 32),
            
            _buildTextField(controller: _fullNameController, label: 'ชื่อ-สกุล', icon: Icons.person),
            const SizedBox(height: 16),
            _buildTextField(controller: _emailController, label: 'อีเมล', icon: Icons.email, type: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _buildTextField(controller: _passwordController, label: 'รหัสผ่าน (อย่างน้อย 6 ตัว)', icon: Icons.lock, obscure: true),
            const SizedBox(height: 16),
            _buildTextField(controller: _confirmPasswordController, label: 'ยืนยันรหัสผ่านอีกครั้ง', icon: Icons.lock_outline, obscure: true),
            const SizedBox(height: 16),
            _buildTextField(controller: _phoneController, label: 'เบอร์โทรศัพท์ (9-10 หลัก)', icon: Icons.phone_android, type: TextInputType.phone),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(child: _buildTextField(controller: _dayController, label: 'วัน (1-31)', icon: Icons.calendar_today, type: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: _buildTextField(controller: _monthController, label: 'เดือน (1-12)', icon: Icons.calendar_month, type: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: _buildTextField(controller: _yearController, label: 'ปี (ค.ศ.)', icon: Icons.calendar_today_outlined, type: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Checkbox(value: _acceptTerms, activeColor: const Color(0xFFDDAA55), onChanged: (v) => setState(() => _acceptTerms = v!)),
                const Expanded(child: Text('ยอมรับข้อกำหนดและเงื่อนไขการใช้งาน', style: TextStyle(fontSize: 12, color: Colors.brown))),
              ],
            ),
            const SizedBox(height: 24),
            
            _isLoading
                ? const CircularProgressIndicator(color: Color(0xFFDDAA55))
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDDAA55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('สมัครสมาชิก', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('มีบัญชีอยู่แล้ว? เข้าสู่ระบบ', style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}