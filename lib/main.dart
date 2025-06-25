import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:food_delivery/admin/admin_login.dart';
import 'package:food_delivery/admin/admin_order_page.dart';
import 'package:food_delivery/admin/adminverify.dart';
import 'package:food_delivery/pages/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        fontFamily: 'poppins',
      ),
      //home: AuthCheck(), //Authcheck default
      //home: AdminVerify(),
      home: AdminLogin(),
      //home: AdminOrdersPage(),
    );
  }
}
