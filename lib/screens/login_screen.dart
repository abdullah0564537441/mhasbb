// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:mhasb/screens/home_screen.dart';
import 'package:mhasb/main.dart'; // استيراد main.dart للوصول إلى المتغير العام 'prefs'

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isFirstLaunch = false;

  @override
  void initState() {
    super.initState();
    // بمجرد تهيئة الشاشة، نتحقق ما إذا كانت هذه هي المرة الأولى لفتح التطبيق
    _checkFirstLaunch();
  }

  // هذه الدالة تتحقق من وجود كلمة مرور مخزنة في SharedPreferences
  Future<void> _checkFirstLaunch() async {
    // نستخدم المتغير العام 'prefs' الذي تم تهيئته في main.dart
    final storedPassword = prefs.getString('app_password');
    setState(() {
      // إذا لم تكن هناك كلمة مرور مخزنة، فهذا يعني أن التطبيق يُفتح لأول مرة
      _isFirstLaunch = storedPassword == null || storedPassword.isEmpty;
    });
  }

  // هذه الدالة تعالج منطق تسجيل الدخول أو تعيين كلمة المرور
  void _login() async {
    // التحقق من صحة المدخلات في حقل كلمة المرور
    if (_formKey.currentState!.validate()) {
      // نستخدم المتغير العام 'prefs' هنا أيضاً
      final storedPassword = prefs.getString('app_password');
      final enteredPassword = _passwordController.text;

      if (_isFirstLaunch) {
        // إذا كانت هذه هي المرة الأولى، نقوم بحفظ كلمة المرور المدخلة
        await prefs.setString('app_password', enteredPassword);
        _showSnackBar('تم تعيين كلمة المرور بنجاح!', isError: false);
        // ننتقل إلى الشاشة الرئيسية ونزيل شاشة تسجيل الدخول من المكدس
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()));
      } else {
        // إذا لم تكن المرة الأولى، نقارن كلمة المرور المدخلة بكلمة المرور المخزنة
        if (storedPassword == enteredPassword) {
          _showSnackBar('تم تسجيل الدخول بنجاح!', isError: false);
          // ننتقل إلى الشاشة الرئيسية ونزيل شاشة تسجيل الدخول من المكدس
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()));
        } else {
          // إذا لم تتطابق كلمة المرور، نعرض رسالة خطأ
          _showSnackBar('كلمة المرور غير صحيحة.', isError: true);
        }
      }
    }
  }

  // دالة مساعدة لعرض رسائل قصيرة في أسفل الشاشة (Snack Bar)
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green, // لون أحمر للخطأ، أخضر للنجاح
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // يتغير عنوان AppBar بناءً على ما إذا كانت المرة الأولى أم تسجيل دخول
        title: Text(_isFirstLaunch ? 'تعيين كلمة مرور' : 'تسجيل الدخول'),
      ),
      body: Center(
        child: SingleChildScrollView( // للسماح بالتمرير إذا كانت لوحة المفاتيح تغطي الحقول
          padding: const EdgeInsets.all(24.0),
          child: Form( // يستخدم لتجميع حقول النص والتحقق من صحتها
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 80, color: Colors.indigo), // أيقونة القفل
                const SizedBox(height: 30),
                Text(
                  _isFirstLaunch
                      ? 'الرجاء تعيين كلمة مرور للتطبيق'
                      : 'أدخل كلمة المرور للدخول',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true, // لإخفاء النص المدخل (كلمة المرور)
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.vpn_key),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال كلمة المرور';
                    }
                    // شرط إضافي لطول كلمة المرور عند التعيين الأول
                    if (_isFirstLaunch && value.length < 4) {
                      return 'يجب أن تكون كلمة المرور 4 أحرف على الأقل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _login, // عند الضغط، يتم استدعاء دالة _login
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50), // زر يملأ العرض
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  // يتغير نص الزر بناءً على ما إذا كانت المرة الأولى أم تسجيل دخول
                  child: Text(_isFirstLaunch ? 'تعيين ودخول' : 'دخول'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
