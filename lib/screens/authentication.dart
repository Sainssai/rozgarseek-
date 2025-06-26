import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razgorsek/controllers/locale_controller.dart';
import 'package:razgorsek/screens/adminscreen.dart';
import 'package:razgorsek/screens/providerhome.dart';
import 'package:razgorsek/screens/userhome.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();

  final _signupName = TextEditingController();
  final _signupEmail = TextEditingController();
  final _signupPassword = TextEditingController();
  final _signupPhone = TextEditingController();
  final _categoryController = TextEditingController();
  String _role = 'user';
  final _location = TextEditingController();

  bool showAdmin = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkIfAdminExists();
  }

  Future<void> _checkIfAdminExists() async {
    final adminQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .limit(1)
        .get();

    if (adminQuery.docs.isNotEmpty) {
      setState(() => showAdmin = false);
    }
  }

  Future<void> loginUser(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user?.uid;
      if (uid == null) throw Exception("User UID is null");

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final role = data['role'];
        final name = data['name'];

        if (role == 'admin') {
          Get.offAll(() => AdminHome());
        } else if (role == 'provider') {
          Get.offAll(() => const ProviderHomePage());
        } else {
          Get.offAll(() => UserHomePage(userName: name));
        }
      } else {
        throw Exception("User data not found in Firestore");
      }
    } catch (e) {
      Get.snackbar("Login Failed", e.toString());
    }

    _loginEmail.clear();
    _loginPassword.clear();
  }

  Future<void> signUp() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _signupEmail.text.trim(),
            password: _signupPassword.text.trim(),
          );

      final userData = {
        'name': _signupName.text.trim(),
        'email': _signupEmail.text.trim(),
        'phone': _signupPhone.text.trim(),
        'role': _role,
      };
      if (_role != 'admin') {
        userData['location'] = _location.text.trim();
      }
      if (_role == 'provider') {
        userData['category'] = _categoryController.text.trim();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData);

      setState(() => _role = 'user');
      _tabController.animateTo(0);
      _checkIfAdminExists();

      Get.snackbar(
        "Success",
        "Account created. Please log in.",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        "Error",
        e.message ?? "Sign up failed",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }

    _signupName.clear();
    _signupEmail.clear();
    _signupPassword.clear();
    _signupPhone.clear();
    _location.clear();
    _categoryController.clear();
  }

  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  blurRadius: 24,
                  color: Colors.black12,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: GetBuilder<LocaleController>(
                    builder: (controller) {
                      return DropdownButton<Locale>(
                        value: controller.locale.value, // Use reactive locale
                        icon: const Icon(
                          Icons.language,
                          color: Colors.deepPurple,
                        ),
                        underline: Container(),
                        onChanged: (Locale? newLocale) {
                          if (newLocale != null) {
                            controller.changeLocale(
                              newLocale,
                            ); // Update via LocaleController
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: Locale('en', 'US'),
                            child: Text('English'),
                          ),
                          DropdownMenuItem(
                            value: Locale('hi', 'IN'),
                            child: Text('हिंदी'),
                          ),
                          DropdownMenuItem(
                            value: Locale('te', 'IN'),
                            child: Text('తెలుగు'),
                          ),
                          DropdownMenuItem(
                            value: Locale('ta', 'IN'),
                            child: Text('தமிழ்'),
                          ),
                          DropdownMenuItem(
  value: Locale('de', 'DE'),
  child: Text('Deutsch'),
),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset("assets/images/logo.jpg", height: 70),
                ),
                const SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F1F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    labelColor: theme.primaryColor,
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(icon: Icon(Icons.login), text: "Log In".tr),
                      Tab(icon: Icon(Icons.person_add), text: "Sign Up".tr),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.62,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      SingleChildScrollView(child: _buildLoginForm()),
                      SingleChildScrollView(child: _buildSignupForm()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            _simpleTextField(
              controller: _loginEmail,
              label: "Email Address".tr,
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Please enter your email';
                if (!GetUtils.isEmail(value.trim()))
                  return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _simpleTextField(
              controller: _loginPassword,
              label: "Password".tr,
              icon: Icons.lock,
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Please enter your password';
                if (value.length < 6) return 'At least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.amberAccent,
                ),
                onPressed: () {
                  if (_loginFormKey.currentState!.validate()) {
                    FocusScope.of(context).unfocus();
                    loginUser(
                      _loginEmail.text.trim(),
                      _loginPassword.text.trim(),
                    );
                  }
                },
                icon: const Icon(Icons.login),
                label: Text("LogIn".tr, style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _signupFormKey,
      child: Column(
        children: [
          _simpleTextField(
            controller: _signupName,
            label: "Full Name".tr,
            icon: Icons.person,
            keyboardType: TextInputType.name,
            validator: (value) => value == null || value.isEmpty
                ? 'Please enter your name'
                : null,
          ),
          const SizedBox(height: 14),
          _simpleTextField(
            controller: _signupEmail,
            label: "Email Address".tr,
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Please enter your email';
              if (!GetUtils.isEmail(value.trim())) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _simpleTextField(
            controller: _signupPhone,
            label: "Phone Number".tr,
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: (value) => value == null || value.isEmpty
                ? 'Please enter your phone number'
                : null,
          ),
          const SizedBox(height: 14),
          _simpleTextField(
            controller: _signupPassword,
            label: "Password".tr,
            icon: Icons.lock,
            obscureText: true,
            keyboardType: TextInputType.visiblePassword,
            validator: (value) => value == null || value.length < 6
                ? 'Password must be at least 6 characters'
                : null,
          ),
          const SizedBox(height: 14),
          if (_role != 'admin')
            _simpleTextField(
              controller: _location,
              label: "Location".tr,
              icon: Icons.location_city,
              validator: (value) => value == null || value.isEmpty
                  ? 'Please enter your location'
                  : null,
            ),
          if (_role != 'admin') const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _role,
            isExpanded: true,
            decoration: _inputDecoration(
              "Account Type".tr,
              Icons.account_circle,
            ),
            onChanged: (val) => setState(() => _role = val!),
            items: [
              DropdownMenuItem(value: 'user', child: Text("User".tr)),
              DropdownMenuItem(value: 'provider', child: Text("Provider".tr)),
              if (showAdmin)
                DropdownMenuItem(value: 'admin', child: Text("Admin".tr)),
            ],
            validator: (value) => value == null || value.isEmpty
                ? 'Please select account type'
                : null,
          ),
          if (_role == 'provider') ...[
            const SizedBox(height: 14),
            _simpleTextField(
              controller: _categoryController,
              label: "Category".tr,
              icon: Icons.category,
              validator: (value) => value == null || value.isEmpty
                  ? 'Please enter your category'
                  : null,
            ),
          ],
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.amberAccent,
              ),
              onPressed: () {
                if (_signupFormKey.currentState!.validate()) {
                  FocusScope.of(context).unfocus();
                  signUp();
                }
              },
              icon: const Icon(Icons.person_add),
              label: Text("Sign Up".tr, style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _simpleTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: _inputDecoration(label, icon),
      validator: validator,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.deepPurple),
      filled: true,
      fillColor: const Color(0xFFF5F6FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
    );
  }
}
