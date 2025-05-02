import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'home_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  _AdminLoginScreenState createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _adminCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String _errorMessage = '';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureAdminCode = true;
  String? _pharmacyName;

  Future<void> _adminLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _pharmacyName = null;
    });

    try {
      // 1. التحقق من صحة الكود الإداري ضد collection pharmacy_inventory
      final pharmacyQuery = await _firestore
          .collection('pharmacy_inventory')
          .where('adminCode', isEqualTo: _adminCodeController.text.trim())
          .limit(1)
          .get();

      if (pharmacyQuery.docs.isEmpty) {
        setState(() => _errorMessage = tr('invalid_admin_code'));
        return;
      }

      final pharmacyDoc = pharmacyQuery.docs.first;
      setState(() => _pharmacyName = pharmacyDoc['name']);

      // 2. تسجيل الدخول باستخدام البريد الإلكتروني وكلمة المرور
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        // 3. حفظ بيانات المدير في Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': userCredential.user!.email,
          'isAdmin': true,
          'enteredAdminCode': _adminCodeController.text.trim(),
          'pharmacyId': pharmacyDoc.id,
          'pharmacyName': pharmacyDoc['name'],
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // 4. الانتقال إلى الشاشة الرئيسية
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              medications: [],
              pharmacies: [],
              isAdmin: true,
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      debugPrint("Error during admin login: $e");
      _showErrorDialog(tr('unexpected_error'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleAuthError(FirebaseAuthException e) {
    String errorMessage = tr('login_failed');
    debugPrint("Error during admin login: $e");

    switch (e.code) {
      case 'invalid-email':
        errorMessage = tr('invalid_email_format');
        break;
      case 'user-disabled':
        errorMessage = tr('account_disabled');
        break;
      case 'user-not-found':
        errorMessage = tr('user_not_found');
        break;
      case 'wrong-password':
        errorMessage = tr('wrong_password');
        break;
      case 'too-many-requests':
        errorMessage = tr('too_many_attempts');
        break;
    }

    _showErrorDialog(errorMessage);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('error')),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('ok')),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyAdminCode(String code) async {
    if (code.length > 5) {
      final pharmacyQuery = await _firestore
          .collection('pharmacy_inventory')
          .where('adminCode', isEqualTo: code.trim())
          .limit(1)
          .get();

      if (pharmacyQuery.docs.isNotEmpty && mounted) {
        setState(() {
          _pharmacyName = pharmacyQuery.docs.first['name'];
        });
      } else if (mounted) {
        setState(() => _pharmacyName = null);
      }
    } else if (mounted) {
      setState(() => _pharmacyName = null);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _adminCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFB3E5FC),
              Color(0xFFE1BEE7),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          FontAwesomeIcons.userShield,
                          size: 60,
                          color: Color(0xFF7E57C2),
                        ),
                        SizedBox(height: 24),
                        Text(
                          tr("admin_login"),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A148C),
                          ),
                        ),
                        SizedBox(height: 32),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: tr('email'),
                            prefixIcon:
                                Icon(Icons.email, color: Color(0xFF7E57C2)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return tr('email_required');
                            }
                            if (!value.contains('@')) {
                              return tr('invalid_email_format');
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: tr('password'),
                            prefixIcon:
                                Icon(Icons.lock, color: Color(0xFF7E57C2)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return tr('password_required');
                            }
                            if (value.length < 6) {
                              return tr('password_too_short');
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _adminCodeController,
                          obscureText: _obscureAdminCode,
                          decoration: InputDecoration(
                            labelText: tr('admin_code'),
                            prefixIcon:
                                Icon(Icons.security, color: Color(0xFF7E57C2)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureAdminCode
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureAdminCode = !_obscureAdminCode;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return tr('admin_code_required');
                            }
                            return null;
                          },
                          onChanged: (value) async {
                            await _verifyAdminCode(value);
                          },
                        ),
                        if (_pharmacyName != null) ...[
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 8),
                                Text(
                                  '${tr('pharmacy')}: $_pharmacyName',
                                  style: TextStyle(color: Colors.green),
                                ),
                              ],
                            ),
                          ),
                        ],
                        SizedBox(height: 16),
                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              _errorMessage,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _adminLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF7E57C2),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    tr('login'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
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
        ),
      ),
    );
  }
}
