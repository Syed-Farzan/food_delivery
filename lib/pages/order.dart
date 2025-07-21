// ✅ UPDATED CartDetailsPage with fixed Total saving

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartDetailsPage extends StatefulWidget {
  const CartDetailsPage({super.key});

  @override
  State<CartDetailsPage> createState() => _CartDetailsPageState();
}

class _CartDetailsPageState extends State<CartDetailsPage> {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  String? name;
  String? phone;

  String selectedPincode = '190001';
  final List<String> pincodes = [
    '191101',
    '190004',
    '190001',
    '190008',
    '191121',
  ];
  final TextEditingController landmarkController = TextEditingController();
  final TextEditingController laneController = TextEditingController();
  final TextEditingController areaController = TextEditingController();

  int calculateTotal(List<Map<String, dynamic>> items) {
    int total = 0;
    for (var data in items) {
      final quantity = int.tryParse(data['Quantity'].toString()) ?? 0;
      final discountedPrice =
          double.tryParse(data['PricePerItem']?.toString() ?? '') ?? 0;
      total += (discountedPrice * quantity).round();
    }
    return total;
  }

  int calculateOriginalTotal(List<Map<String, dynamic>> items) {
    int total = 0;
    for (var data in items) {
      final quantity = int.tryParse(data['Quantity'].toString()) ?? 0;
      final originalPrice =
          double.tryParse(data['OriginalPrice']?.toString() ?? '') ?? 0;
      total += (originalPrice * quantity).round();
    }
    return total;
  }

  int calculateDiscountedTotal(List<Map<String, dynamic>> items) {
    int total = 0;
    for (var data in items) {
      final quantity = int.tryParse(data['Quantity'].toString()) ?? 0;
      final discountedPrice =
          double.tryParse(data['PricePerItem']?.toString() ?? '') ?? 0;
      total += (discountedPrice * quantity).round();
    }
    return total;
  }

  List<Map<String, dynamic>> combineCartItems(
    List<QueryDocumentSnapshot> docs,
  ) {
    final Map<String, Map<String, dynamic>> combined = {};
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final key = data['Name'];
      final quantity = int.tryParse(data['Quantity'].toString()) ?? 0;

      if (combined.containsKey(key)) {
        // Combine quantities
        combined[key]!['Quantity'] =
            (int.tryParse(combined[key]!['Quantity'].toString()) ?? 0) +
            quantity;
      } else {
        combined[key] = Map<String, dynamic>.from(data);
      }
    }
    return combined.values.toList();
  }

  Future<void> ontheload() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    name = userDoc['Name'];
    phone = userDoc['phone'];
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    ontheload();
  }

  bool _isPlacingOrder = false; // Add this field

  void placeCashOnDeliveryOrder(List<QueryDocumentSnapshot> cartDocs) async {
    const int deliveryFee = 50;
    setState(() {
      _isPlacingOrder = true;
    });

    final addressComplete = await _getAddressBeforePayment();
    if (!addressComplete) {
      setState(() {
        _isPlacingOrder = false;
      });
      return;
    }

    // Stock check for each item in cart
    final List<String> collections = ['Vegetable', 'Fruit', 'Dairy', 'Chicken'];
    bool allInStock = true;
    String? outOfStockItem;

    final combinedCartItems = combineCartItems(cartDocs);

    for (var data in combinedCartItems) {
      final name = data['Name'];
      bool found = false;
      bool inStock = false;

      for (final collection in collections) {
        final foodSnap = await FirebaseFirestore.instance
            .collection(collection)
            .where('Name', isEqualTo: name)
            .limit(1)
            .get();

        if (foodSnap.docs.isNotEmpty) {
          found = true;
          final foodData = foodSnap.docs.first.data();
          inStock = foodData['inStock'] ?? false;
          break;
        }
      }

      if (!found) {
        allInStock = false;
        outOfStockItem = name;
        break;
      }

      if (!inStock) {
        allInStock = false;
        outOfStockItem = name;
        break;
      }
    }

    if (!allInStock) {
      setState(() {
        _isPlacingOrder = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            outOfStockItem != null
                ? "$outOfStockItem is out of stock. Please update your cart."
                : "One or more items are out of stock.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final selectedItemsData = combinedCartItems.map((data) {
      return {
        'Name': data['Name'],
        'Quantity': data['Quantity'],
        'Price': data['PricePerItem'],
        'Total':
            (double.tryParse(data['PricePerItem']?.toString() ?? '') ?? 0) *
            (int.tryParse(data['Quantity'].toString()) ?? 0),
        'Image': data['Image'],
      };
    }).toList();

    // --- BEGIN: Free Item Threshold Logic ---
    final orderTotal = calculateTotal(combinedCartItems);

    final thresholdSnap = await FirebaseFirestore.instance
        .collection('free_item_thresholds')
        .orderBy('price')
        .get();

    String? rewardItem;
    num? rewardThreshold;

    for (final doc in thresholdSnap.docs.reversed) {
      final price = doc['price'] as num;
      final item = doc['item'] as String;
      if (orderTotal >= price) {
        rewardItem = item;
        rewardThreshold = price;
        break;
      }
    }

    // If a reward is earned, add it to the items list (without price/quantity)
    if (rewardItem != null) {
      selectedItemsData.add({
        'Name': '[FREE] $rewardItem',
        'Quantity': null,
        'Price': null,
        'Total': null,
        'Image': null,
        'isReward': true,
      });
    }
    // --- END: Free Item Threshold Logic ---

    final orderId = FirebaseFirestore.instance.collection('AllOrders').doc().id;
    final grandTotal = orderTotal + deliveryFee;
    final orderData = {
      'orderId': orderId,
      'userId': userId,
      'userName': name,
      'userPhone': phone,
      'pincode': selectedPincode,
      'landmark': landmarkController.text.trim(),
      'lane': laneController.text.trim(),
      'area': areaController.text.trim(),
      'items': selectedItemsData,
      'timestamp': Timestamp.now(),
      'status': 'Pending',
      'paymentMode': 'Cash on Delivery',
      'deliveryFee': deliveryFee,
      'grandTotal': grandTotal,
      if (rewardItem != null)
        'reward': {'item': rewardItem, 'threshold': rewardThreshold},
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('Orders')
        .doc(orderId)
        .set(orderData);
    await FirebaseFirestore.instance
        .collection('AllOrders')
        .doc(orderId)
        .set(orderData);

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in cartDocs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    setState(() {
      _isPlacingOrder = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text(
          rewardItem != null
              ? "Order Placed! You earned a free item: $rewardItem"
              : "Order Placed Successfully with Cash on Delivery",
        ),
      ),
    );
  }

  Future<bool> _getAddressBeforePayment() async {
    final prefs = await SharedPreferences.getInstance();
    laneController.text = prefs.getString('address_lane') ?? '';
    areaController.text = prefs.getString('address_area') ?? '';
    landmarkController.text = prefs.getString('address_landmark') ?? '';
    selectedPincode = prefs.getString('address_pincode') ?? selectedPincode;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Enter Delivery Address"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selectedPincode,
                    onChanged: (value) =>
                        setState(() => selectedPincode = value!),
                    items: pincodes
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text("Pincode: $p"),
                          ),
                        )
                        .toList(),
                  ),
                  TextField(
                    controller: laneController,
                    decoration: const InputDecoration(labelText: 'Lane'),
                  ),
                  TextField(
                    controller: areaController,
                    decoration: const InputDecoration(labelText: 'Area'),
                  ),
                  TextField(
                    controller: landmarkController,
                    decoration: const InputDecoration(labelText: 'Landmark'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.red),
                ),
              ),
              TextButton(
                onPressed: () async {
                  if (laneController.text.trim().isEmpty ||
                      areaController.text.trim().isEmpty ||
                      landmarkController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please fill all address fields."),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  await prefs.setString(
                    'address_lane',
                    laneController.text.trim(),
                  );
                  await prefs.setString(
                    'address_area',
                    areaController.text.trim(),
                  );
                  await prefs.setString(
                    'address_landmark',
                    landmarkController.text.trim(),
                  );
                  await prefs.setString('address_pincode', selectedPincode);

                  Navigator.pop(context, true);
                },
                child: const Text(
                  "Continue",
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> updateCartQuantity(
    String itemName,
    int newQuantity,
    List<QueryDocumentSnapshot> cartDocs,
  ) async {
    // Find all docs for this item
    final docsToUpdate = cartDocs
        .where(
          (doc) => (doc.data() as Map<String, dynamic>)['Name'] == itemName,
        )
        .toList();

    if (docsToUpdate.isEmpty) return;

    final sample = docsToUpdate.first.data() as Map<String, dynamic>;
    final discountedPrice =
        double.tryParse(sample['PricePerItem'].toString()) ?? 0;
    final total = discountedPrice * newQuantity;

    final batch = FirebaseFirestore.instance.batch();

    if (newQuantity > 0) {
      batch.update(docsToUpdate.first.reference, {
        'Quantity': newQuantity,
        'Total': total,
      });
    } else {
      batch.delete(docsToUpdate.first.reference);
    }

    // Delete any extra docs for this item (shouldn't usually exist, but for safety)
    for (var i = 1; i < docsToUpdate.length; i++) {
      batch.delete(docsToUpdate[i].reference);
    }

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    const int deliveryFee = 50;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('My Cart')),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('Cart')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final cartDocs = snapshot.data!.docs;
              final combinedCartItems = combineCartItems(cartDocs);
              final total = calculateTotal(combinedCartItems);
              final originalTotal = calculateOriginalTotal(combinedCartItems);
              final discountedTotal = calculateDiscountedTotal(
                combinedCartItems,
              );
              final totalSaved = originalTotal - discountedTotal;
              final grandTotal = total + deliveryFee; // Add delivery fee

              // --- BEGIN: Free Item Threshold Logic for UI ---
              String? rewardItem;
              num? rewardThreshold;

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('free_item_thresholds')
                    .orderBy('price')
                    .get(),
                builder: (context, thresholdSnapshot) {
                  String? congratsMessage;
                  if (thresholdSnapshot.hasData) {
                    final thresholdDocs = thresholdSnapshot.data!.docs;
                    for (final doc in thresholdDocs.reversed) {
                      final price = doc['price'] as num;
                      final item = doc['item'] as String;
                      if (total >= price) {
                        rewardItem = item;
                        rewardThreshold = price;
                        congratsMessage =
                            "🎉 Congratulations! Your cart is eligible for a FREE \"$rewardItem\" (on orders above ₹$rewardThreshold)!";
                        break;
                      }
                    }
                  }

                  return Column(
                    children: [
                      if (congratsMessage != null)
                        Container(
                          width: double.infinity,
                          color: Colors.amber.shade100,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.card_giftcard,
                                color: Colors.orange,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  congratsMessage,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: combinedCartItems.length,
                          itemBuilder: (context, index) {
                            final data = combinedCartItems[index];

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade300,
                                    blurRadius: 4,
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                leading: Image.network(
                                  data['Image'],
                                  height: 60,
                                  width: 60,
                                  fit: BoxFit.cover,
                                ),
                                title: Text(
                                  data['Name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                          ),
                                          onPressed:
                                              (int.tryParse(
                                                        data['Quantity']
                                                            .toString(),
                                                      ) ??
                                                      1) >
                                                  1
                                              ? () async {
                                                  await updateCartQuantity(
                                                    data['Name'],
                                                    (int.tryParse(
                                                              data['Quantity']
                                                                  .toString(),
                                                            ) ??
                                                            1) -
                                                        1,
                                                    cartDocs,
                                                  );
                                                }
                                              : null,
                                        ),
                                        Text(
                                          "Qty: ${data['Quantity'] ?? ''}",
                                          style: const TextStyle(fontSize: 15),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                          ),
                                          onPressed: () async {
                                            await updateCartQuantity(
                                              data['Name'],
                                              (int.tryParse(
                                                        data['Quantity']
                                                            .toString(),
                                                      ) ??
                                                      1) +
                                                  1,
                                              cartDocs,
                                            );
                                          },
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () async {
                                            await updateCartQuantity(
                                              data['Name'],
                                              0,
                                              cartDocs,
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '${data['Name']} removed from cart',
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    Text(
                                      "\u20B9 ${(double.tryParse(data['PricePerItem']?.toString() ?? '') ?? 0) * (int.tryParse(data['Quantity'].toString()) ?? 0)}",
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 12,
                              offset: const Offset(0, -6),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Subtotal: \u20B9$total",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (combinedCartItems
                                    .isNotEmpty) // Only show if cart is not empty
                                  Text(
                                    "Delivery: \u20B9$deliveryFee",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total: \u20B9${combinedCartItems.isNotEmpty ? grandTotal : 0}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed:
                                      combinedCartItems.isEmpty ||
                                          _isPlacingOrder
                                      ? null
                                      : () =>
                                            placeCashOnDeliveryOrder(cartDocs),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 30,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text(
                                    "Place Order (COD)",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (totalSaved > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  "You saved \u20B9$totalSaved on this order!",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        if (_isPlacingOrder)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
