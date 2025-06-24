import 'package:flutter/material.dart';
import 'package:food_delivery/admin/admin_login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_delivery/admin/home_admin.dart';

class AdminVerify extends StatelessWidget {
  const AdminVerify({super.key});

  Future<bool> checkAdminLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isAdminLoggedIn') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: checkAdminLogin(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.data == true) {
          return const HomeAdmin();
        } else {
          return const AdminLogin();
        }
      },
    );
  }
}
