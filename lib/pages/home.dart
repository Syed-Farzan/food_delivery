import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_delivery/pages/details.dart';
import 'package:food_delivery/pages/order.dart';
import 'package:food_delivery/service/database.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String selectedCategory = "Vegetable";
  Stream? fooditemStream;
  String? Name;
  int cartCount = 0;

  @override
  void initState() {
    getUserName().then((value) {
      setState(() {
        Name = value ?? "User";
      });
    });
    onTheLoad(selectedCategory);
    listenCartCount();
    super.initState();
  }

  void listenCartCount() {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('Cart')
        .snapshots()
        .listen((snapshot) {
          int count = 0;
          for (var doc in snapshot.docs) {
            final data = doc.data();
            count += int.tryParse(data['Quantity'].toString()) ?? 1;
          }
          setState(() {
            cartCount = count;
          });
        });
  }

  onTheLoad(String category) async {
    fooditemStream = await DatabaseMethods().getFoodItem(category);
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

  Future<void> addToCart({
    required String name,
    required int quantity,
    required double totalPrice,
    required String image,
    required double perItemPrice,
    required double? originalPrice,
    required bool hasDiscount,
    required double savedAmount,
  }) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    Map<String, dynamic> cartItem = {
      "Name": name,
      'Quantity': quantity.toString(),
      'Total': totalPrice.toDouble(),
      'Image': image,
      'PricePerItem': perItemPrice.toStringAsFixed(2),
      'OriginalPrice': originalPrice?.toStringAsFixed(2) ?? '',
      'DiscountApplied': hasDiscount ? 'Discount' : 'None',
      'Saved': savedAmount.toStringAsFixed(2),
    };
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('Cart')
        .add(cartItem);
  }

  Widget allitemsVertically() {
    return StreamBuilder(
      stream: fooditemStream,
      builder: (context, AsyncSnapshot snapshot) {
        return snapshot.hasData
            ? ListView.builder(
                itemCount: snapshot.data.docs.length,
                padding: EdgeInsets.zero,
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.docs[index];
                  // FIX: Correct logic for outOfStock
                  bool outOfStock = !(ds['inStock'] ?? false);

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Details(
                            detail: ds['Detail'] ?? '',
                            image: ds['Image'] ?? '',
                            name: ds['Name'] ?? '',
                            originalPrice: (ds['OriginalPrice'] as num?)
                                ?.toDouble(),
                            discountedPrice: (ds['DiscountedPrice'] as num?)
                                ?.toDouble(),
                            inStock: !outOfStock,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.09),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.07),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                ds['Image'],
                                height: 80,
                                width: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ds['Name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      fontFamily: 'Poppins',
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ds['Detail'],
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  outOfStock
                                      ? Text(
                                          "Out of Stock",
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins',
                                            fontSize: 13,
                                          ),
                                        )
                                      : _buildPriceTag(
                                          (ds['OriginalPrice'] as num?)
                                              ?.toDouble(),
                                          (ds['DiscountedPrice'] as num?)
                                              ?.toDouble(),
                                        ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (outOfStock)
                              ElevatedButton(
                                onPressed: null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade300,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  "Out of Stock",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            else
                              ElevatedButton.icon(
                                onPressed: () {
                                  addToCart(
                                    name: ds['Name'],
                                    quantity: 1,
                                    totalPrice:
                                        (ds['DiscountedPrice'] ??
                                                ds['OriginalPrice'])
                                            ?.toDouble() ??
                                        0.0,
                                    image: ds['Image'],
                                    perItemPrice:
                                        (ds['DiscountedPrice'] ??
                                                ds['OriginalPrice'])
                                            ?.toDouble() ??
                                        0.0,
                                    originalPrice: (ds['OriginalPrice'] as num?)
                                        ?.toDouble(),
                                    hasDiscount:
                                        ds['OriginalPrice'] != null &&
                                        ds['DiscountedPrice'] != null &&
                                        (ds['OriginalPrice'] as num) >
                                            (ds['DiscountedPrice'] as num),
                                    savedAmount:
                                        (ds['OriginalPrice'] != null &&
                                            ds['DiscountedPrice'] != null)
                                        ? ((ds['OriginalPrice'] as num) -
                                                  (ds['DiscountedPrice']
                                                      as num))
                                              .toDouble()
                                        : 0.0,
                                  );
                                },
                                icon: const Icon(
                                  Icons.add_shopping_cart,
                                  size: 18,
                                ),
                                label: const Text(
                                  "Add",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              )
            : const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildPriceTag(double? original, double? discounted) {
    if (discounted != null && discounted != 0 && discounted != original) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${original?.toStringAsFixed(2)} INR",
            style: const TextStyle(
              decoration: TextDecoration.lineThrough,
              color: Colors.red,
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "${discounted.toStringAsFixed(2)} INR",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.green,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      );
    } else {
      return Text(
        "${original?.toStringAsFixed(2) ?? discounted?.toStringAsFixed(2) ?? 'N/A'} INR",
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: Colors.black87,
          fontFamily: 'Poppins',
        ),
      );
    }
  }

  Widget showItem() {
    List<Map<String, dynamic>> categories = [
      {"name": "Vegetable", "icon": "lib/images/vegetables.png"},
      {"name": "Fruit", "icon": "lib/images/fruit.png"},
      {"name": "Dairy", "icon": "lib/images/dairy-products.png"},
      {"name": "Chicken", "icon": "lib/images/christmas-dinner.png"},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: categories.map((category) {
        bool selected = selectedCategory == category["name"];
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedCategory = category["name"];
              onTheLoad(selectedCategory);
            });
          },
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  color: selected ? Colors.green.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? Colors.green : Colors.grey.shade300,
                    width: selected ? 2 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                padding: const EdgeInsets.all(10),
                child: Image.asset(
                  category["icon"],
                  height: 36,
                  width: 36,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                category["name"],
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Poppins',
                  color: selected ? Colors.green : Colors.black87,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(top: 32, left: 16, right: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hello ${Name ?? ""}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      fontFamily: 'Poppins',
                      color: Colors.black87,
                    ),
                  ),
                  Stack(
                    children: [
                      // Make the cart button larger and easier to tap
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: IconButton(
                          iconSize: 32, // Larger icon
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.shopping_cart_outlined,
                            color: Colors.black87,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CartDetailsPage(),
                              ),
                            );
                          },
                        ),
                      ),
                      if (cartCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Center(
                              child: Text(
                                '$cartCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Nutritious Veggies!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  fontFamily: 'Poppins',
                  color: Colors.black87,
                ),
              ),
              const Text(
                'Discover and Get Products',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 18),
              showItem(),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(child: allitemsVertically()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
