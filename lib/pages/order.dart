// ✅ UPDATED CartDetailsPage with fixed Total saving

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CartDetailsPage extends StatefulWidget {
  const CartDetailsPage({Key? key}) : super(key: key);

  @override
  State<CartDetailsPage> createState() => _CartDetailsPageState();
}

class _CartDetailsPageState extends State<CartDetailsPage> {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  final Set<String> selectedItems = {};
  String? name;
  String? phone;

  String selectedPincode = '190001';
  final List<String> pincodes = ['190001', '190002', '190003', '190004'];
  final TextEditingController landmarkController = TextEditingController();
  final TextEditingController laneController = TextEditingController();
  final TextEditingController areaController = TextEditingController();

  bool selectionMode = false;

  void toggleSelection(String docId) {
    setState(() {
      if (selectedItems.contains(docId)) {
        selectedItems.remove(docId);
      } else {
        selectedItems.add(docId);
      }
    });
  }

  void showDeleteConfirmation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Confirmation"),
        content: const Text(
          "Are you sure you want to delete the selected items?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) deleteSelectedItems();
  }

  void deleteSelectedItems() async {
    final batch = FirebaseFirestore.instance.batch();
    for (String docId in selectedItems) {
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('Cart')
          .doc(docId);
      batch.delete(ref);
    }
    await batch.commit();
    setState(() {
      selectedItems.clear();
      selectionMode = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Selected items deleted")));
  }

  int calculateTotal(List<QueryDocumentSnapshot> docs) {
    int total = 0;
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final value = data['Total'];
      final parsed = (value is num)
          ? value.toInt()
          : int.tryParse(value.toString()) ?? 0;
      total += parsed;
    }
    return total;
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

  void placeCashOnDeliveryOrder(List<QueryDocumentSnapshot> cartDocs) async {
    final addressComplete = await _getAddressBeforePayment();
    if (!addressComplete) return;

    final selectedItemsData = cartDocs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'Name': data['Name'],
        'Quantity': data['Quantity'],
        'Price': data['Price'],
        'Total': (data['Total'] is num)
            ? data['Total']
            : int.tryParse(data['Total'].toString()) ?? 0,
        'Saved': data['Saved'],
        'Image': data['Image'],
      };
    }).toList();

    final orderId = FirebaseFirestore.instance.collection('AllOrders').doc().id;

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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color.fromARGB(255, 43, 255, 0),
        content: Text("Order Placed Successfully with Cash on Delivery"),
      ),
    );
  }

  Future<bool> _getAddressBeforePayment() async {
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
                    controller: landmarkController,
                    decoration: const InputDecoration(labelText: 'Landmark'),
                  ),
                  TextField(
                    controller: laneController,
                    decoration: const InputDecoration(labelText: 'Lane'),
                  ),
                  TextField(
                    controller: areaController,
                    decoration: const InputDecoration(labelText: 'Area'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Continue"),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        actions: [
          IconButton(
            icon: Icon(selectionMode ? Icons.close : Icons.delete),
            onPressed: () {
              setState(() {
                selectionMode = !selectionMode;
                selectedItems.clear();
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('Cart')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final cartDocs = snapshot.data!.docs;
          final total = calculateTotal(cartDocs);

          return Column(
            children: [
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: cartDocs.length,
                  itemBuilder: (context, index) {
                    final doc = cartDocs[index];
                    final isSelected = selectedItems.contains(doc.id);
                    final data = doc.data() as Map<String, dynamic>;

                    return GestureDetector(
                      onTap: selectionMode
                          ? () => toggleSelection(doc.id)
                          : null,
                      child: Container(
                        width: 160,
                        margin: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.deepPurple[100]
                              : Colors.deepPurple[50],
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: Colors.deepPurple, width: 2)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade300,
                              blurRadius: 4,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.network(
                              data['Image'],
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              data['Name'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text("Qty: ${data['Quantity'] ?? ''}"),
                            Text(
                              "\u20B9 ${data['Total'] ?? ''}",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (data['Saved'] != null &&
                                data['Saved'] != '0.00')
                              Text(
                                "You saved \u20B9 ${data['Saved']}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Spacer(),
              if (selectionMode && selectedItems.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: showDeleteConfirmation,
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text(
                        "Delete Selected",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
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
                    BoxShadow(color: Colors.grey.shade300, blurRadius: 8),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total: \u20B9$total",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: cartDocs.isEmpty
                          ? null
                          : () => placeCashOnDeliveryOrder(cartDocs),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        "Place Order (COD)",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
