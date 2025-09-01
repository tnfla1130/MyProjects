import 'package:flutter/material.dart';

void main() {
  runApp(const SignUpApp());
}

class SignUpApp extends StatelessWidget {
  const SignUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '회원가입 페이지',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const SignUpPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordCheckController = TextEditingController();
  final TextEditingController _emailIdController = TextEditingController();
  final TextEditingController _emailDomainController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _zipcodeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _addressDetailController = TextEditingController();

  void _handleSignUp() {
    final id = _idController.text.trim();
    final pw = _passwordController.text.trim();
    final pwCheck = _passwordCheckController.text.trim();
    final emailId = _emailIdController.text.trim();
    final emailDomain = _emailDomainController.text.trim();
    final phone = _phoneController.text.trim();
    final nickname = _nicknameController.text.trim();
    final zipcode = _zipcodeController.text.trim();
    final address = _addressController.text.trim();
    final addressDetail = _addressDetailController.text.trim();

    if ([id, pw, pwCheck, emailId, emailDomain, phone, nickname, zipcode, address, addressDetail]
        .any((e) => e.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목을 입력해주세요.')),
      );
      return;
    }

    if (pw != pwCheck) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
      );
      return;
    }

    final email = '$emailId@$emailDomain';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('회원가입 완료!\n아이디: $id\n이메일: $email\n주소: [$zipcode] $address $addressDetail'),
      ),
    );

    _idController.clear();
    _passwordController.clear();
    _passwordCheckController.clear();
    _emailIdController.clear();
    _emailDomainController.clear();
    _phoneController.clear();
    _nicknameController.clear();
    _zipcodeController.clear();
    _addressController.clear();
    _addressDetailController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6CB70),
      appBar: AppBar(
        title: const Text('회원가입'),
        centerTitle: true,
        elevation: 2,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF6CB70),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.shade200.withOpacity(0.7),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(controller: _idController, label: '아이디', icon: Icons.person),
                const SizedBox(height: 10),

                _buildTextField(
                  controller: _passwordController,
                  label: '비밀번호',
                  icon: Icons.lock,
                  obscureText: true,
                ),
                const SizedBox(height: 10),

                _buildTextField(
                  controller: _passwordCheckController,
                  label: '비밀번호 확인',
                  icon: Icons.lock_outline,
                  obscureText: true,
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildTextField(
                        controller: _emailIdController,
                        label: '이메일 아이디',
                        icon: Icons.email_outlined,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text('@', style: TextStyle(fontSize: 16)),
                    ),
                    Expanded(
                      flex: 5,
                      child: _buildTextField(
                        controller: _emailDomainController,
                        label: '도메인',
                        icon: Icons.domain_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                _buildTextField(
                  controller: _phoneController,
                  label: '전화번호',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),

                _buildTextField(
                  controller: _nicknameController,
                  label: '닉네임',
                  icon: Icons.face,
                ),
                const SizedBox(height: 10),

                // 우편번호 + 검색 버튼
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: _buildTextField(
                        controller: _zipcodeController,
                        label: '우편번호',
                        icon: Icons.markunread_mailbox_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: ElevatedButton(
                        onPressed: () {
                          // 우편번호 검색 기능 추가 가능
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.indigo,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '검색',
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                _buildTextField(
                  controller: _addressController,
                  label: '주소',
                  icon: Icons.home,
                ),
                const SizedBox(height: 10),

                _buildTextField(
                  controller: _addressDetailController,
                  label: '상세 주소',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      '가입하기',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 20),
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}