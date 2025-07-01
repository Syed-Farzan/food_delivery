import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_delivery/pages/bottom_navigation_bar.dart';
import 'package:food_delivery/pages/login.dart';
import 'package:food_delivery/service/shared_pref.dart';
import 'package:flutter/services.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formkey = GlobalKey<FormState>();
  TextEditingController phoneController = TextEditingController();
  TextEditingController otpController = TextEditingController();
  TextEditingController usernameController = TextEditingController();

  String verificationId = "";
  bool otpSent = false;
  bool isLoading = false;

  Future<void> sendOTP() async {
    final username = usernameController.text.trim();
    final phone = phoneController.text.trim();

    if (username.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.greenAccent,
          content: Text('Please fill in all fields.'),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // 🔍 Check if phone number already exists in Firestore
      final phoneQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .get();

      if (phoneQuery.docs.isNotEmpty) {
        setState(() => isLoading = false);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Phone Number Taken"),
            content: const Text("This phone number is already registered."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
        );
        return;
      }

      // ✅ Send OTP
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: "+91$phone",
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => BottomNav()),
          );
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green,
              content: Text('Verification Failed. ${e.message}'),
            ),
          );
          setState(() => isLoading = false);
        },
        codeSent: (String verId, int? resendToken) {
          setState(() {
            verificationId = verId;
            otpSent = true;
            isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verId) {
          setState(() {
            verificationId = verId;
            otpSent = true;
            isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('An error occurred while sending OTP.'),
        ),
      );
    }
  }

  Future<void> verifyOTP() async {
    try {
      setState(() => isLoading = true);

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpController.text.trim(),
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // 🔒 Double check user existence by UID
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (userDoc.exists) {
        await FirebaseAuth.instance.signOut(); // Avoid duplicate login
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("User Already Exists"),
            content: const Text(
              "An account with this phone number already exists.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
        );
        return;
      }

      // ✅ Register new user
      Map<String, dynamic> addUserInfo = {
        'Name': usernameController.text,
        'phone': phoneController.text,
        'id': uid,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(addUserInfo);

      await SharedPrefrenceHelper().saveUserName(usernameController.text);
      await SharedPrefrenceHelper().saveUserID(uid);
      await SharedPrefrenceHelper().savePhoneKey(phoneController.text);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BottomNav()),
      );
    } catch (e) {
      String errorMessage = 'Invalid OTP or error occurred.';
      if (e is FirebaseAuthException) {
        errorMessage = e.message ?? errorMessage;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.green, content: Text(errorMessage)),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // Minimal gradient background
            Container(
              width: double.infinity,
              height:
                  MediaQuery.of(context).size.height *
                  0.48, // Increased from 0.40
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // White card for form
            Container(
              margin: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.30,
              ),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x11000000),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: const SizedBox(height: 420),
            ),
            // Content
            Container(
              margin: const EdgeInsets.only(top: 48.0, left: 20, right: 20),
              child: Column(
                children: [
                  // Logo
                  Center(
                    child: Image.asset(
                      'lib/images/logo.png',
                      width: MediaQuery.of(context).size.width / 2,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 35),
                  Material(
                    borderRadius: BorderRadius.circular(18),
                    elevation: 2,
                    color: Colors.white,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 22,
                      ),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Form(
                        key: _formkey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              'Sign up with Phone',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontFamily: 'Poppins',
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Username
                            TextFormField(
                              controller: usernameController,
                              keyboardType: TextInputType.name,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Please enter username'
                                  : null,
                              decoration: InputDecoration(
                                hintText: 'User Name',
                                prefixIcon: const Icon(
                                  Icons.person_outline,
                                  color: Colors.black54,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            // Phone
                            TextFormField(
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(10),
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter phone number';
                                }
                                if (value.length != 10) {
                                  return 'Enter a valid 10-digit number';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: 'Phone number',
                                prefixIcon: const Icon(
                                  Icons.phone_android_outlined,
                                  color: Colors.black54,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            if (otpSent) ...[
                              const SizedBox(height: 18),
                              TextFormField(
                                controller: otpController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Enter OTP',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    color: Colors.black54,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 22),
                            isLoading
                                ? const CircularProgressIndicator()
                                : SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (_formkey.currentState!.validate()) {
                                          if (!otpSent) {
                                            sendOTP();
                                          } else {
                                            verifyOTP();
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF43E97B,
                                        ),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                      child: Text(
                                        otpSent ? 'Verify OTP' : 'Send OTP',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                    child: const Text(
                      "Already have an account? Log in",
                      style: TextStyle(
                        color: Color(0xFF43E97B),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
