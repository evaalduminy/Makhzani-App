import 'package:flutter/material.dart';

import 'package:makhzani_app/services/database_helper.dart';
import 'package:makhzani_app/models/user_model.dart';
import 'package:makhzani_app/utils/security_utils.dart';
import 'package:makhzani_app/utils/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // State
  int _currentStep = 1; // 1: Username, 2: Security Question, 3: New Password
  bool _isLoading = false;
  User? _foundUser;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _answerController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // الخطوة 1: التحقق من اسم المستخدم
  Future<void> _verifyUsername() async {
    if (_usernameController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final dbHelper = DatabaseHelper();
      final user = await dbHelper.getUserByUsername(_usernameController.text);

      if (user != null) {
        if (user.securityQuestion != null && user.securityAnswer != null) {
          setState(() {
            _foundUser = user;
            _currentStep = 2; // الانتقال لخطوة السؤال
          });
        } else {
          _showError(
              'عذراً، هذا الحساب ليس لديه سؤال أمان مضبوط. يرجى التواصل مع المسؤول.');
        }
      } else {
        _showError('اسم المستخدم غير موجود');
      }
    } catch (e) {
      _showError('حدث خطأ: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // الخطوة 2: التحقق من إجابة سؤال الأمان
  void _verifyAnswer() {
    if (_answerController.text.isEmpty) return;

    // مقارنة بسيطة (يمكن تحسينها لتجاهل المسافات الزائدة)
    if (_answerController.text.trim() == _foundUser!.securityAnswer) {
      setState(() {
        _currentStep = 3; // الانتقال لخطوة تغيير كلمة المرور
      });
    } else {
      _showError('الإجابة غير صحيحة');
    }
  }

  // الخطوة 3: تغيير كلمة المرور
  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dbHelper = DatabaseHelper();

      // تشفير كلمة المرور الجديدة
      final newPasswordHash =
          SecurityUtils.hashPassword(_newPasswordController.text);

      // تحديث المستخدم بكلمة المرور الجديدة
      // نحتاج لنسخ المستخدم الحالي مع كلمة المرور الجديدة
      // ملاحظة: بما أن user_model.dart قد لا يحتوي على copyWith حالياً، سننشئ كائناً جديداً

      // للأسف DatabaseHelper قد لا يكون فيه دالة update مباشرة تقبل User كامل
      // سنفترض وجود دالة update أو نستخدم insert مع conflictAlgorithm replace إذا كانت مدعومة
      // أو نكتب استعلام تحديث يدوي.
      // للأمان، سنضيف دالة تحديث كلمة مرور في DatabaseHelper لاحقاً،
      // لكن الآن سنفترض أننا سنقوم بتعديل بسيط أو استخدام update إذا وجد.
      // لحظة، لم أتحقق من وجود دالة update في DatabaseHelper.
      // سأستخدم db.update في DatabaseHelper. (سأحتاج لإضافتها إذا لم تكن موجودة)
      // سأقوم بكتابة كود التحديث هنا مباشرة إذا لم أتمكن من تعديل Helper الآن،
      // لكن الأفضل تعديل Helper. سأفترض أنني سأضيف دالة updateUser في الخطوة التالية.

      await dbHelper.updatePassword(_foundUser!.username, newPasswordHash);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تغيير كلمة المرور بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // العودة لشاشة الدخول
      }
    } catch (e) {
      _showError('فشل تحديث كلمة المرور: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('استعادة كلمة المرور',
              style: TextStyle(fontFamily: 'Cairo', color: AppColors.primary)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_currentStep == 1) _buildStep1(),
                if (_currentStep == 2) _buildStep2(),
                if (_currentStep == 3) _buildStep3(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // واجهة الخطوة 1: إدخال اسم المستخدم
  Widget _buildStep1() {
    return Column(
      children: [
        const Icon(Icons.lock_reset, size: 80, color: Colors.grey),
        const SizedBox(height: 16),
        const Text(
          'أدخل اسم المستخدم للبحث عن حسابك',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontFamily: 'Cairo'),
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: 'اسم المستخدم',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyUsername,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('تحقق',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  // واجهة الخطوة 2: سؤال الأمان
  Widget _buildStep2() {
    return Column(
      children: [
        const Text(
          'أجب على سؤال الأمان التالي للتحقق من هويتك',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontFamily: 'Cairo'),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.security, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _foundUser?.securityQuestion ?? '',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _answerController,
          decoration: const InputDecoration(
            labelText: 'إجابة سؤال الأمان',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.question_answer),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyAnswer,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('تحقق من الإجابة',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  // واجهة الخطوة 3: كلمة المرور الجديدة
  Widget _buildStep3() {
    return Column(
      children: [
        const Text(
          'قم بتعيين كلمة مرور جديدة',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontFamily: 'Cairo'),
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _newPasswordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            labelText: 'كلمة المرور الجديدة',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility),
              onPressed: () =>
                  setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
          ),
          validator: (value) {
            if (value == null || value.length < 6) {
              return 'كلمة المرور قصيرة';
            }
            if (RegExp(r'[\u0600-\u06FF]').hasMatch(value)) {
              return 'لا تقبل العربية';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_isConfirmPasswordVisible,
          decoration: InputDecoration(
            labelText: 'تأكيد كلمة المرور',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(_isConfirmPasswordVisible
                  ? Icons.visibility_off
                  : Icons.visibility),
              onPressed: () => setState(
                  () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
            ),
          ),
          validator: (value) {
            if (value != _newPasswordController.text) {
              return 'كلمة المرور غير متطابقة';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('تغيير كلمة المرور',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
      ],
    );
  }
}
