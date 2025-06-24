import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class CartDetailsPage extends StatefulWidget {
  const CartDetailsPage({Key? key}) : super(key: key);

  @override
  State<CartDetailsPage> createState() => _CartDetailsPageState();
}

class _CartDetailsPageState extends State<CartDetailsPage> {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  final Set<String> selectedItems = {};
  late Razorpay _razorpay;
  int? full_price;
  String? phone;
  String? name;

  String selectedPincode = '190001';
  final List<String> pincodes = ['190001', '190002', '190003', '190004'];
  final TextEditingController landmarkController = TextEditingController();
  final TextEditingController laneController = TextEditingController();
  final TextEditingController areaController = TextEditingController();

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

    if (confirm == true) {
      deleteSelectedItems();
    }
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
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Selected items deleted")));
  }

  int calculateTotal(List<QueryDocumentSnapshot> docs) {
    int total = 0;
    for (var doc in docs) {
      if (selectedItems.contains(doc.id)) {
        total += int.tryParse(doc['Total'] ?? '0') ?? 0;
        full_price = total * 100;
      }
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
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentsucess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymenterror);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWalletResponse);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentsucess(PaymentSuccessResponse response) async {
    final selectedDocs = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('Cart')
        .get();

    final selectedItemsData = selectedDocs.docs
        .where((doc) => selectedItems.contains(doc.id))
        .map((doc) => doc.data())
        .toList();

    final orderData = {
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
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('Orders')
        .add(orderData);

    await FirebaseFirestore.instance.collection('AllOrders').add(orderData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color.fromARGB(255, 43, 255, 0),
        content: Text("Payment Successful and Order Placed"),
      ),
    );
  }

  void _handlePaymenterror(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.red,
        content: Text("Payment Failed"),
      ),
    );
  }

  void _handleExternalWalletResponse(ExternalWalletResponse response) {}

  void _openCheckout() async {
    final addressComplete = await _getAddressBeforePayment();
    if (!addressComplete) return;

    var options = {
      'key': 'rzp_test_icUYkQuoZmE36O',
      'amount': full_price,
      'name': name,
      'description': 'Items',
      'prefill': {'contact': phone, 'email': 'fooddelivery21234@gmail.com'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print(e);
    }
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
      appBar: AppBar(title: const Text('My Cart')),
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
          final selectedTotal = calculateTotal(cartDocs);

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
                    return GestureDetector(
                      onTap: () => toggleSelection(doc.id),
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
                              doc['Image'],
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              doc['Name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text("Qty: ${doc['Quantity']}"),
                            Text("₹ ${doc['Total']}"),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Spacer(),
              if (selectedItems.isNotEmpty)
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
                      "Total: ₹$selectedTotal",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: selectedItems.isEmpty ? null : _openCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        "Pay Now",
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
