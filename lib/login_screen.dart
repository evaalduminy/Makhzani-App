import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:makhzani_app/home_screen.dart';
import 'package:makhzani_app/register_screen.dart';
import 'package:makhzani_app/screens/forgot_password_screen.dart'; // استيراد شاشة استعادة كلمة المرور
import 'package:makhzani_app/utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:makhzani_app/services/app_settings_service.dart';
import 'package:makhzani_app/services/database_helper.dart';
import 'package:makhzani_app/utils/security_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    // يفحص كل الحقول دفعة واحد
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final dbHelper = DatabaseHelper();
        final username = _usernameController.text;
        final password = _passwordController.text;

        // التحقق من صحة المستخدم في قاعدة البيانات
        final user = await dbHelper.getUserByUsername(username);

        // تشفير كلمة المرور المدخلة ومقارنتها مع المحفوظة
        if (user != null) {
          final hashedEnteredPassword = SecurityUtils.hashPassword(password);
          if (user.passwordHash == hashedEnteredPassword) {
            // حفظ اسم المستخدم في الإعدادات العامة
            if (!mounted) return;
            await context.read<AppSettingsService>().setUsername(username);

            if (mounted) {
              setState(() => _isLoading = false);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
            return; // خروج ناجح
          }
        }

        // إذا وصلنا هنا، يعني خطأ في الاسم أو كلمة المرور
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'اسم المستخدم أو كلمة المرور غير صحيحة',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ أثناء تسجيل الدخول: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // إذا فشل التحقق، نظهر SnackBar لتوضيح أن هناك أخطاء في المدخلات
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تصحيح الأخطاء الظاهرة في الحقول أولاً'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.inventory_2_rounded,
                        size: 80, color: AppColors.primary),
                    const SizedBox(height: 16),
                    const Text('مخزني',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontFamily: 'Cairo')),
                    const SizedBox(height: 8),
                    Text('نظام إدارة المخزون الذكي',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 16, color: Colors.grey[600])),
                    const SizedBox(height: 48),
                    TextFormField(
                      controller: _usernameController,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'اسم المستخدم',
                        hintText: 'أدخل اسم المستخدم (حروف فقط)',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      inputFormatters: [
                        // السماح فقط بالحروف (الإنجليزية والعربية) والمسافات
                        // \u0621-\u064A هي نطاق الحروف العربية الأساسية (بدون أرقام عربية)
                        FilteringTextInputFormatter.allow(RegExp(
                            r'[a-zA-Z\s\u0621-\u064A\u0671-\u06D3\u06FB-\u06FE]')),
                        // منع الأرقام الإنجليزية
                        FilteringTextInputFormatter.deny(RegExp(r'[0-9]')),
                        // منع الأرقام العربية والرموز
                        FilteringTextInputFormatter.deny(RegExp(
                            r'[\u0660-\u0669\u06F0-\u06F9!@#\$%^&*(),.?":{}|<>]')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال اسم المستخدم';
                        }
                        // التحقق من وجود أرقام (إنجليزية أو عربية) أو رموز
                        if (RegExp(
                                r'[0-9\u0660-\u0669\u06F0-\u06F9!@#\$%^&*(),.?":{}|<>]')
                            .hasMatch(value)) {
                          return 'يسمح بالحروف والمسافات فقط (لا يسمح بالأرقام أو الرموز)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        hintText: 'أدخل كلمة المرور (بدون حروف عربية)',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(
                              () => _isPasswordVisible = !_isPasswordVisible),
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(
                            r'[\u0600-\u06FF]')), // منع أي حرف عربي (بما فيه الأرقام والرموز العربية)
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال كلمة المرور';
                        }
                        if (value.length < 6) {
                          return 'كلمة المرور قصيرة جداً (6 خانات على الأقل)';
                        }
                        // التحقق من وجود حروف عربية (في حال تم اللصق)
                        if (RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]')
                            .hasMatch(value)) {
                          return 'خطأ: كلمة المرور يجب أن تكون بالإنجليزية والأرقام فقط';
                        }
                        return null;
                      },
                    ),

                    // زر نسيت كلمة المرور
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'نسيت كلمة المرور؟',
                          style: TextStyle(
                            color: Color(0xFF5C6BC0),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : const Text('تسجيل الدخول',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RegisterScreen())),
                      child: RichText(
                        text: const TextSpan(
                          text: 'ليس لديك حساب؟ ',
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontFamily: 'Segoe UI'),
                          children: [
                            TextSpan(
                                text: 'أنشئ حساباً جديداً',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold))
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
