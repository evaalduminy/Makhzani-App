import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:makhzani_app/login_screen.dart';
import 'package:makhzani_app/services/database_helper.dart';
import 'package:makhzani_app/models/user_model.dart';
import 'package:makhzani_app/utils/security_utils.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // مفتاح النموذج للتحقق من صحة البيانات
  final _formKey = GlobalKey<FormState>();

  // وحدات التحكم في النصوص
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _securityAnswerController =
      TextEditingController(); // جديد: إجابة سؤال الأمان

  // متغيرات الحالة
  bool _isPasswordVisible = false; // لإظهار/إخفاء كلمة المرور
  bool _isConfirmPasswordVisible = false; // لإظهار/إخفاء تأكيد كلمة المرور
  bool _isLoading = false; // لإظهار حالة التحميل
  String? _selectedSecurityQuestion; // جديد: السؤال المختار

  // قائمة أسئلة الأمان
  final List<String> _securityQuestions = [
    'ما هو اسم حيوانك الأليف الأول؟',
    'ما هو اسم مدرستك الابتدائية؟',
    'ما هو اسم صديق طفولتك المفضل؟',
    'ما هي مدينتك المفضلة؟',
  ];

  @override
  void dispose() {
    // تنظيف وحدات التحكم عند إغلاق الشاشة لتجنب تسريب الذاكرة
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // دالة إنشاء الحساب
  Future<void> _register() async {
    // إخفاء لوحة المفاتيح
    FocusScope.of(context).unfocus();

    // التحقق من صحة الحقول
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // بدء التحميل
      });

      try {
        final dbHelper = DatabaseHelper();
        final username = _usernameController.text;
        final password = _passwordController.text;

        // التحقق مما إذا كان اسم المستخدم موجوداً مسبقاً
        final existingUser = await dbHelper.getUserByUsername(username);
        if (existingUser != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'اسم المستخدم مستخدم بالفعل، يرجى اختيار اسم آخر',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          // إنشاء مستخدم جديد
          // استخدام SecurityUtils لتشفير كلمة المرور
          // 2. تطبيق خوارزمية التشفير SHA-256 (Hashing)
          final hashedPassword =
              SecurityUtils.hashPassword(password); // تشفير كلمة المرور

          final newUser = User(
            fullName: username, // يمكن إضافة حقل للاسم الكامل لاحقاً
            username: username,
            passwordHash: hashedPassword, // حفظ النسخة المشفرة فقط
            securityQuestion: _selectedSecurityQuestion, // حفظ السؤال
            securityAnswer: _securityAnswerController.text, // حفظ الإجابة
            isActive: true,
          );

          await dbHelper.insertUser(newUser);

          if (mounted) {
            // عرض رسالة نجاح
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'تم إنشاء الحساب بنجاح! الرجاء تسجيل الدخول الآن.',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor: Colors.green,
              ),
            );

            // الانتقال لشاشة تسجيل الدخول
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'حدث خطأ أثناء التسجيل: $e',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false; // إيقاف التحميل
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // استخدام Directionality لضمان اتجاه الكتابة من اليمين لليسار (RTL)
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50], // نفس خلفية شاشة الدخول
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1A237E)),
            onPressed: () => Navigator.pop(context), // زر الرجوع
          ),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(
            context,
          ).unfocus(), // إخفاء الكيبورد عند النقر في الفراغ
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
                    // --- العنوان ---
                    const Text(
                      'إنشاء حساب جديد',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 76, 230, 230),
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'أدخل بياناتك للتسجيل في مخزني',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 48),

                    // --- حقل اسم المستخدم ---
                    TextFormField(
                      controller: _usernameController,
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      decoration: _buildInputDecoration(
                        label: 'اسم المستخدم',
                        hint: 'أدخل اسم المستخدم (حروف فقط)',
                        icon: Icons.person_outline,
                      ),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      inputFormatters: [
                        // يسمح بالحروف والمسافات فقط (بدون أي نوع من الأرقام)
                        FilteringTextInputFormatter.allow(RegExp(
                            r'[a-zA-Z\s\u0621-\u064A\u0671-\u06D3\u06FB-\u06FE]')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال اسم المستخدم';
                        }
                        if (RegExp(
                                r'[0-9\u0660-\u0669\u06F0-\u06F9!@#\$%^&*(),.?":{}|<>]')
                            .hasMatch(value)) {
                          return 'يسمح بالحروف والمسافات فقط (لا يسمح بالأرقام أو الرموز)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // --- حقل كلمة المرور ---
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      textInputAction: TextInputAction.next,
                      decoration: _buildInputDecoration(
                        label: 'كلمة المرور',
                        hint: 'أدخل كلمة المرور (بدون حروف عربية)',
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(
                            r'[\u0600-\u06FF]')), // منع العربية والرموز العربية
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال كلمة المرور';
                        }
                        if (value.length < 6) {
                          return 'كلمة المرور يجب أن تكون 6 خانات على الأقل';
                        }
                        if (RegExp(r'[\u0600-\u06FF]').hasMatch(value)) {
                          return 'خطأ: كلمة المرور لا تقبل الحروف العربية';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // --- حقل تأكيد كلمة المرور ---
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _register(),
                      decoration: _buildInputDecoration(
                        label: 'تأكيد كلمة المرور',
                        hint: 'أعد إدخال كلمة المرور',
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(
                            RegExp(r'[\u0600-\u06FF]')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء تأكيد كلمة المرور';
                        }
                        if (value != _passwordController.text) {
                          return 'كلمة المرور غير متطابقة';
                        }
                        if (RegExp(r'[\u0600-\u06FF]').hasMatch(value)) {
                          return 'خطأ: لا تقبل الحروف العربية';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // --- قسم استعادة كلمة المرور (جديد) ---
                    const Text(
                      'إعدادات استعادة كلمة المرور',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // قائمة منسدلة لاختيار سؤال الأمان
                    DropdownButtonFormField<String>(
                      value: _selectedSecurityQuestion,
                      decoration: _buildInputDecoration(
                        label: 'سؤال الأمان',
                        hint: 'اختر سؤالاً لاستعادة الحساب',
                        icon: Icons.security,
                      ),
                      items: _securityQuestions.map((String question) {
                        return DropdownMenuItem<String>(
                          value: question,
                          child: Text(question),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedSecurityQuestion = newValue;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'الرجاء اختيار سؤال أمان' : null,
                    ),
                    const SizedBox(height: 16),

                    // حقل إجابة سؤال الأمان
                    TextFormField(
                      controller: _securityAnswerController,
                      decoration: _buildInputDecoration(
                        label: 'إجابة سؤال الأمان',
                        hint: 'أدخل الإجابة (تذكرها جيداً)',
                        icon: Icons.question_answer,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال إجابة السؤال';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // --- زر إنشاء الحساب ---
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 76, 230, 230),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'إنشاء الحساب',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- زر العودة لتسجيل الدخول ---
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // إغلاق الشاشة والعودة
                      },
                      child: RichText(
                        text: const TextSpan(
                          text: 'لديك حساب بالفعل؟ ',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontFamily: 'Segoe UI',
                          ),
                          children: [
                            TextSpan(
                              text: 'تسجيل الدخول',
                              style: TextStyle(
                                color: Color.fromARGB(255, 76, 230, 230),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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

  // دالة مساعدة لتنسيق الحقول (لتقليل تكرار الكود)
  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
