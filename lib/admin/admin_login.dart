import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:food_delivery/admin/home_admin.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminLogin extends StatefulWidget {
  const AdminLogin({super.key});

  @override
  State<AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  TextEditingController usernameconroller = TextEditingController();
  TextEditingController passwordconroller = TextEditingController();

  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void dispose() {
    usernameconroller.dispose();
    passwordconroller.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFededeb),
      body: Stack(
        children: [
          // Decorative background
          Container(
            margin: EdgeInsets.only(
              top: MediaQuery.of(context).size.height / 2.5,
            ),
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF232526),
                  Color(0xFF414345),
                  Color(0xFF232526),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.elliptical(1000, 110),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 30,
                  offset: Offset(0, -10),
                ),
              ],
            ),
          ),
          // Logo and form
          SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo or Icon
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.black,
                      child: Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                  const Text(
                    'Welcome, Admin!',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to your admin dashboard',
                    style: TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                  const SizedBox(height: 30),
                  Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(24),
                    shadowColor: Colors.black38,
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formkey,
                        child: Column(
                          children: [
                            TextFormField(
                              focusNode: _usernameFocus,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please Enter UserName';
                                }
                                return null;
                              },
                              controller: usernameconroller,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.person_outline_rounded),
                                hintText: 'Username',
                                filled: true,
                                fillColor: Color(0xFFF5F5F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 18,
                                  horizontal: 16,
                                ),
                              ),
                              onFieldSubmitted: (_) {
                                FocusScope.of(
                                  context,
                                ).requestFocus(_passwordFocus);
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              focusNode: _passwordFocus,
                              textInputAction: TextInputAction.done,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please Enter Password';
                                }
                                return null;
                              },
                              controller: passwordconroller,
                              obscureText: true,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.lock_outline_rounded),
                                hintText: 'Password',
                                filled: true,
                                fillColor: Color(0xFFF5F5F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 18,
                                  horizontal: 16,
                                ),
                              ),
                              onFieldSubmitted: (_) {
                                if (_formkey.currentState!.validate()) {
                                  loginAdmin();
                                }
                              },
                            ),
                            const SizedBox(height: 30),
                            GestureDetector(
                              onTap: () {
                                if (_formkey.currentState!.validate()) {
                                  loginAdmin();
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF232526),
                                      Color(0xFF414345),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    "Login",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void loginAdmin() async {
    final snapshot = await FirebaseFirestore.instance.collection('Admin').get();
    bool matched = false;

    for (var result in snapshot.docs) {
      final data = result.data();
      if (data['id'] == usernameconroller.text.trim() &&
          data['password'] == passwordconroller.text.trim()) {
        matched = true;
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAdminLoggedIn', true);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeAdmin()),
        );
        break;
      }
    }

    if (!matched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid username or password"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
