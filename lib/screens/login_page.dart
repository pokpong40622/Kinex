import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isMale = true;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // game room background — clear, no blur, no gradient
          Image.asset('assets/images/bg_room.png', fit: BoxFit.cover),
          // main content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.07),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: h * 0.04),
                      Center(
                        child: Image.asset('assets/images/kinex_logo.png',
                            width: w * 0.39),
                      ),
                      SizedBox(height: h * 0.04),
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text('Login',
                                style: GoogleFonts.poppins(
                                  fontSize: w * 0.069,
                                  fontWeight: FontWeight.w900,
                                  foreground: Paint()
                                    ..style = PaintingStyle.stroke
                                    ..strokeWidth = 6
                                    ..color = const Color(0xFF5361AF),
                                )),
                            Text('Login',
                                style: poppins(
                                    size: w * 0.069,
                                    weight: FontWeight.w900,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                      SizedBox(height: h * 0.03),
                      _InputField(
                        icon: 'assets/images/icon_user.png',
                        hint: 'Username',
                        w: w,
                        h: h,
                      ),
                      SizedBox(height: h * 0.02),
                      _InputField(
                        icon: 'assets/images/icon_padlock.png',
                        hint: 'Password',
                        w: w,
                        h: h,
                        obscure: true,
                      ),
                      SizedBox(height: h * 0.02),
                      _InputField(
                        textIcon: 'AGE',
                        hint: 'Age',
                        w: w,
                        h: h,
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: h * 0.03),
                      _GenderSelector(
                        isMale: _isMale,
                        onChanged: (v) => setState(() => _isMale = v),
                        w: w,
                        h: h,
                      ),
                      SizedBox(height: h * 0.03),
                      Center(
                        child: GestureDetector(
                          onTap: () => context.go('/home'),
                          child: Container(
                            width: w * 0.54,
                            height: h * 0.09,
                            decoration: BoxDecoration(
                              gradient: KColors.pinkGradient,
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                  color: Colors.white.withAlpha(115), width: 3),
                              boxShadow: const [
                                BoxShadow(
                                    color: Color(0x40000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 4))
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text('LOGIN',
                                style: montserrat(
                                    size: w * 0.052,
                                    weight: FontWeight.w900,
                                    color: Colors.white)),
                          ),
                        ),
                      ),
                      SizedBox(height: h * 0.18),
                    ],
                  ),
                );
              },
            ),
          ),
          // character on top, overlapping the gender selector
          Positioned(
            left: w * 0.754,
            bottom: h * -0.13,
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/char_main.png',
                height: h * 0.42,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String? icon;
  final String? textIcon;
  final String hint;
  final double w;
  final double h;
  final bool obscure;
  final TextInputType keyboardType;

  const _InputField({
    this.icon,
    this.textIcon,
    required this.hint,
    required this.w,
    required this.h,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: h * 0.09,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      padding: EdgeInsets.symmetric(horizontal: w * 0.04),
      child: Row(
        children: [
          if (textIcon != null)
            Container(
              width: w * 0.075,
              height: w * 0.075,
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(textIcon!,
                  style: TextStyle(
                      fontSize: w * 0.022,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
            )
          else if (icon != null)
            Image.asset(icon!, width: w * 0.075, color: KColors.labelBlue),
          SizedBox(width: w * 0.04),
          Expanded(
            child: TextField(
              obscureText: obscure,
              keyboardType: keyboardType,
              style: montserrat(
                  size: w * 0.042, weight: FontWeight.w900, color: KColors.labelBlue),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: montserrat(
                    size: w * 0.042,
                    weight: FontWeight.w900,
                    color: KColors.labelBlue),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenderSelector extends StatelessWidget {
  final bool isMale;
  final ValueChanged<bool> onChanged;
  final double w;
  final double h;

  const _GenderSelector({
    required this.isMale,
    required this.onChanged,
    required this.w,
    required this.h,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(true),
            child: Container(
              height: h * 0.17,
              decoration: BoxDecoration(
                color: const Color(0xFF92B1FF),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  bottomLeft: Radius.circular(25),
                ),
                border: isMale
                    ? Border.all(color: Colors.white.withAlpha(64), width: 5)
                    : null,
              ),
              child: Center(
                child:
                    Icon(Icons.male_rounded, color: Colors.white, size: w * 0.15),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(false),
            child: Container(
              height: h * 0.17,
              decoration: BoxDecoration(
                color: const Color(0xFFFFA7B3),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
                border: !isMale
                    ? Border.all(color: Colors.white.withAlpha(64), width: 5)
                    : null,
              ),
              child: Center(
                child: Icon(Icons.female_rounded,
                    color: Colors.white, size: w * 0.15),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
