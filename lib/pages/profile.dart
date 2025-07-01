import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_delivery/service/shared_pref.dart';
import 'package:food_delivery/pages/login.dart';
import 'package:food_delivery/pages/terms_and_conditions.dart';
import 'package:food_delivery/pages/signup.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String? Name;
  String? phoneNumber;

  getthesharedpref() async {
    phoneNumber = await SharedPrefrenceHelper().getPhoneKey();
    setState(() {});
  }

  ontheload() async {
    await getthesharedpref();
    setState(() {});
  }

  Future<String?> getUserName() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData['Name'];
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting user name: $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    ontheload();
    getUserName().then((value) {
      setState(() {
        Name = value ?? "User";
      });
    });
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  void confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              logout();
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ✅ Delete all user data from Firestore before deleting Firebase Auth account
  Future<void> deleteAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final uid = user.uid;
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid);

      // Delete all subcollections (Cart, Orders, etc.)
      final cartDocs = await userDocRef.collection('Cart').get();
      for (var doc in cartDocs.docs) {
        await doc.reference.delete();
      }
      final orderDocs = await userDocRef.collection('Orders').get();
      for (var doc in orderDocs.docs) {
        await doc.reference.delete();
      }

      // Delete user document
      await userDocRef.delete();

      // Optionally: Remove from AllOrders collection
      final allOrders = await FirebaseFirestore.instance
          .collection('AllOrders')
          .where('userId', isEqualTo: uid)
          .get();
      for (var doc in allOrders.docs) {
        await doc.reference.delete();
      }

      // Delete from SharedPreferences and Firebase Auth
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await user.delete();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Signup()),
        (route) => false,
      );
    } catch (e) {
      print('Error deleting user data: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to delete account")));
    }
  }

  void confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Account", style: TextStyle(color: Colors.red)),
        content: const Text(
          "Are you sure you want to delete your account permanently?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.green)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              deleteAccount();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile header with gradient and shadow
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 38),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 48,
                        backgroundImage: AssetImage('lib/images/boy.png'),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      Name ?? "User",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (phoneNumber != null)
                      Text(
                        phoneNumber!,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white70,
                          fontFamily: 'Poppins',
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Glassmorphic card for profile details
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 18),
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _glassProfileItem(Icons.person, "Name", Name ?? "User"),
                    _divider(),
                    _glassProfileItem(
                      Icons.phone,
                      "Phone number",
                      phoneNumber ?? "",
                    ),
                    _divider(),
                    GestureDetector(
                      onTap: goToTermsAndConditions,
                      child: _glassProfileItem(
                        Icons.book,
                        "Terms and Conditions",
                      ),
                    ),
                    _divider(),
                    GestureDetector(
                      onTap: confirmDeleteAccount,
                      child: _glassProfileItem(
                        Icons.delete,
                        "Delete Account",
                        null,
                        Colors.red,
                      ),
                    ),
                    _divider(),
                    GestureDetector(
                      onTap: confirmLogout,
                      child: _glassProfileItem(
                        Icons.logout,
                        "Log out",
                        null,
                        Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // App branding
              Text(
                "SabZr",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: Colors.green.shade400,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Freshness Delivered",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Colors.black38,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void goToTermsAndConditions() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TermsAndConditionsPage()),
    );
  }

  // Minimalistic profile item
  Widget _glassProfileItem(
    IconData icon,
    String title, [
    String? subtitle,
    Color iconColor = Colors.black,
  ]) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Minimal divider
  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Divider(
      color: Colors.grey.withOpacity(0.15),
      thickness: 1,
      height: 0,
    ),
  );
}
