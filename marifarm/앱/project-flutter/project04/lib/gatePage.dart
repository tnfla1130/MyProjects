import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'mainPage.dart';
import 'loginPage.dart';

class GatePage extends StatelessWidget {
  const GatePage({super.key});

  Future<void> _proceed(BuildContext context) async {
    final ok = await AuthService.instance.hasValidToken();
    if (!context.mounted) return;

    if (ok) {
      // ✅ 로그인된 유저 정보 가져오기
      final authUser = AuthService.instance.user;

      if (authUser != null) {
        // user 정보가 세팅돼 있으면 MainPage로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainPage(authUser: authUser),
          ),
        );
      } else {
        // 토큰은 있는데 user 정보가 비어있을 때 → 로그인 페이지로 보내기
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } else {
      // 토큰이 없거나 비정상 → 로그인으로
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InkWell(
        onTap: () => _proceed(context),
        child: SizedBox.expand(
          child: Image.asset(
            "assets/images/gate.png",
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
