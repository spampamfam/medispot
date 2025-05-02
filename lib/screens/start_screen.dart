import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'login_screen.dart';
import 'admin_login_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFEDE7F6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // اللوجو: درع + كاميرا + موقع
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    FontAwesomeIcons.shieldAlt,
                    size: 120,
                    color: Colors.white,
                  ),
                  Positioned(
                    top: 40,
                    child: Icon(
                      FontAwesomeIcons.camera,
                      size: 50,
                      color: Color(0xFF9575CD),
                    ),
                  ),
                  Positioned(
                    top: 15,
                    right: 45,
                    child: Icon(
                      FontAwesomeIcons.mapMarkerAlt,
                      size: 30,
                      color: Color(0xFF7E57C2),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // اسم التطبيق داخل كبسولة بشكل جذاب
              Container(
                width: 280,
                height: 120,
                decoration: BoxDecoration(
                  color: Color(0xFF9575CD),
                  borderRadius: BorderRadius.circular(60),
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 0,
                      child: Container(
                        width: 140,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(60),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 30,
                      child: Text(
                        'MEDI ',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9575CD),
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 30,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text(
                          ' SPOT',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        width: 20,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 50),

              // زر تسجيل الدخول كمستخدم
              _buildLoginButton(
                text: tr("user"),
                color: Color(0xFF7E57C2),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
              ),
              SizedBox(height: 15),

              // زر تسجيل الدخول كمدير
              _buildLoginButton(
                text: tr("admin"),
                color: Color(0xFF9575CD),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => AdminLoginScreen()),
                  );
                },
              ),
              SizedBox(height: 50),

              // زر تغيير اللغة (عربي/إنجليزي)
              GestureDetector(
                onTap: () {
                  if (context.locale == Locale('en')) {
                    context.setLocale(Locale('ar'));
                  } else {
                    context.setLocale(Locale('en'));
                  }
                },
                child: Column(
                  children: [
                    Icon(
                      FontAwesomeIcons.language,
                      color: Color(0xFF7E57C2),
                      size: 30,
                    ),
                    SizedBox(height: 5),
                    Text(
                      tr("change_language"),
                      style: TextStyle(
                        color: Color(0xFF7E57C2),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // تصميم زر الدخول الموحد للمستخدم والمدير
  Widget _buildLoginButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 220,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
