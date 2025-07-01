import 'package:flutter/material.dart';
import 'package:food_delivery/pages/home.dart';
import 'package:food_delivery/pages/order.dart';
import 'package:food_delivery/pages/profile.dart';
import 'package:food_delivery/pages/order_details.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int currentTabIndex = 0;

  late List<Widget> pages;
  late Home homepage;
  late Profile profile;
  late CartDetailsPage cartDetailsPage;
  late UserOrdersPage order;

  List<int> navigationHistory = [0]; // Start with Home tab

  @override
  void initState() {
    homepage = Home();
    profile = Profile();
    cartDetailsPage = CartDetailsPage();
    order = UserOrdersPage();
    pages = [homepage, cartDetailsPage, order, profile];
    super.initState();
  }

  void _onTabSelected(int index) {
    if (currentTabIndex != index) {
      setState(() {
        navigationHistory.add(index);
        currentTabIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (navigationHistory.length > 1) {
          setState(() {
            navigationHistory.removeLast();
            currentTabIndex = navigationHistory.last;
          });
          return false; // Don't exit app, go to previous tab
        }
        return true; // Exit app if only one tab in history
      },
      child: Scaffold(
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(
                    icon: Icons.home_outlined,
                    label: "Home",
                    index: 0,
                  ),
                  _buildNavItem(
                    icon: Icons.shopping_cart_outlined,
                    label: "Cart",
                    index: 1,
                  ),
                  _buildNavItem(
                    icon: Icons.list_alt_outlined,
                    label: "Orders",
                    index: 2,
                  ),
                  _buildNavItem(
                    icon: Icons.person_outline,
                    label: "Profile",
                    index: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Use IndexedStack to preserve state and prevent flicker
        body: IndexedStack(index: currentTabIndex, children: pages),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool selected = currentTabIndex == index;
    return GestureDetector(
      onTap: () => _onTabSelected(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.green.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? Colors.green : Colors.black54,
              size: 28,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.green : Colors.black54,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
