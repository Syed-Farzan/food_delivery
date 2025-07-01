import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_delivery/pages/bottom_navigation_bar.dart';
import 'package:food_delivery/pages/signup.dart';

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance
          .authStateChanges(), // ✅ listens to login state
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator()); // Loading
        } else if (snapshot.hasData) {
          return Scaffold(body: BottomNav()); // ✅ Already logged in
        } else {
          return Scaffold(body: Signup()); // 🔐 Not logged in
        }
      },
    );
  }
}
