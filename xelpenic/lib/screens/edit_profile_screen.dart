import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _supabase = Supabase.instance.client;
  final Color goldColor = const Color(0xFFDDAA55);
  final Color blackColor = const Color(0xFF141414);

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _avatarUrlController = TextEditingController();
  DateTime? _selectedDob;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // ทำให้เวลาพิมพ์ URL รูปภาพ แล้วรูปพรีวิวอัปเดตทันที
    _avatarUrlController.addListener(() {
      setState(() {});
    });
    _loadProfileData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  // โหลดข้อมูลเก่ามาโชว์
  Future<void> _loadProfileData() async {
    try {
      final userId = _supabase.auth.currentUser?.id ?? 'mock-uuid-1234-5678';
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('customer_ID', userId)
          .single();

      setState(() {
        _usernameController.text = data['customer_username'] ?? '';
        _avatarUrlController.text = data['customer_avatar_url'] ?? '';

        // เช็คว่ามีข้อมูลวันเกิดไหม ถ้ามีให้แปลงเป็น DateTime
        if (data['customer_dob'] != null &&
            data['customer_dob'].toString().isNotEmpty) {
          _selectedDob = DateTime.parse(data['customer_dob']);
        }
        isLoading = false;
      });
    } catch (e) {
      print("Load Profile Error: $e");
      setState(() => isLoading = false);
    }
  }

  // อัปเดตข้อมูลลง Database
  Future<void> _saveProfile() async {
    setState(() => isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id ?? 'mock-uuid-1234-5678';

      await _supabase
          .from('profiles')
          .update({
            'customer_username': _usernameController.text,
            'customer_avatar_url': _avatarUrlController.text,
            // เก็บเฉพาะส่วนวันที่ รูปแบบ YYYY-MM-DD
            'customer_dob': _selectedDob != null
                ? DateFormat('yyyy-MM-dd').format(_selectedDob!)
                : null,
          })
          .eq('customer_ID', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('อัปเดตโปรไฟล์สำเร็จ!'),
            backgroundColor: goldColor,
          ),
        );
        Navigator.pop(context); // บันทึกเสร็จให้เด้งกลับหน้า More
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ฟังก์ชันเปิดปฏิทินเลือกวันเกิด
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDob ?? DateTime(2000, 1, 1), // ค่าเริ่มต้นถ้ายังไม่เคยเลือก
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        // แต่งปฏิทินให้เป็นโทนทอง-ดำ
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: goldColor, // สี Header และวงกลมวันที่เลือก
              onPrimary: Colors.white, // สีตัวหนังสือบน Header
              onSurface: blackColor, // สีตัวหนังสือวันที่
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: goldColor,
              ), // สีปุ่ม Cancel/OK
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: blackColor),
        title: Text(
          'EDIT PROFILE',
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
          : SingleChildScrollView(
              // ใช้ ScrollView กัน Error คีย์บอร์ดบังจอ
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- ส่วนแสดงรูปโปรไฟล์พรีวิว ---
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: goldColor, width: 2),
                            color: Colors.grey.shade100,
                          ),
                          child: ClipOval(
                            child: _avatarUrlController.text.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: _avatarUrlController.text,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) => Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.grey.shade400,
                                    ),
                                  )
                                : Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.grey.shade400,
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: blackColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- URL รูปโปรไฟล์ ---
                  _buildInputLabel('Image URL (ลิงก์รูปภาพ)'),
                  TextField(
                    controller: _avatarUrlController,
                    decoration: _inputDecoration(
                      hint: 'https://example.com/image.jpg',
                      icon: Icons.link,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- ชื่อผู้ใช้งาน ---
                  _buildInputLabel('ชื่อผู้ใช้งาน (Username)'),
                  TextField(
                    controller: _usernameController,
                    decoration: _inputDecoration(
                      hint: 'กรอกชื่อผู้ใช้งานของคุณ',
                      icon: Icons.person_outline,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- วันเกิด ---
                  _buildInputLabel('วันเกิด (Date of Birth)'),
                  InkWell(
                    onTap: () => _selectDate(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.transparent),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: Colors.grey.shade600,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _selectedDob != null
                                ? DateFormat(
                                    'dd MMMM yyyy',
                                  ).format(_selectedDob!)
                                : 'เลือกวันเกิดของคุณ',
                            style: TextStyle(
                              color: _selectedDob != null
                                  ? blackColor
                                  : Colors.grey.shade500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // --- ปุ่มบันทึก ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blackColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'บันทึกข้อมูล',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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

  // Widget สร้างหัวข้อฟิลด์
  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Widget สไตล์กล่องกรอกข้อความ
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 22),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: goldColor, width: 1.5),
      ),
    );
  }
}
