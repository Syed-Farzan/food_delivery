import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserOrdersPage extends StatefulWidget {
  const UserOrdersPage({Key? key}) : super(key: key);

  @override
  State<UserOrdersPage> createState() => _UserOrdersPageState();
}

class _UserOrdersPageState extends State<UserOrdersPage> {
  String selectedStatus = 'All';

  final List<String> statusOptions = [
    'All',
    'Pending',
    'Delivered',
    'Cancelled',
  ];

  String formatTimestamp(Timestamp timestamp) {
    final dt = timestamp.toDate();
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> cancelOrder(
    BuildContext context,
    String orderId,
    String userId,
  ) async {
    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Cancel Order"),
            content: const Text("Are you sure you want to cancel this order?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("No"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Yes, Cancel",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('Orders')
          .doc(orderId)
          .update({'status': 'Cancelled'});

      await FirebaseFirestore.instance
          .collection('AllOrders')
          .doc(orderId)
          .update({'status': 'Cancelled'});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order cancelled successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to cancel order: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        actions: [
          DropdownButton<String>(
            value: selectedStatus,
            onChanged: (value) {
              setState(() {
                selectedStatus = value!;
              });
            },
            items: statusOptions
                .map(
                  (status) => DropdownMenuItem<String>(
                    value: status,
                    child: Text("Filter: $status"),
                  ),
                )
                .toList(),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('Orders')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          List<QueryDocumentSnapshot> orders = snapshot.data!.docs;

          if (selectedStatus != 'All') {
            orders = orders.where((doc) {
              final status = (doc['status'] ?? 'Pending') as String;
              return status == selectedStatus;
            }).toList();
          }

          if (orders.isEmpty) {
            return const Center(child: Text("No orders found."));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final doc = orders[index];
              final data = doc.data() as Map<String, dynamic>;
              final orderId = doc.id;
              final status = data['status'] ?? 'Pending';
              final items = data['items'] as List<dynamic>;
              final thresholdDiscount = (data['thresholdDiscount'] ?? 0)
                  .toDouble();
              final finalTotal = (data['finalTotal'] ?? 0).toDouble();

              final address =
                  '${data['lane']}, ${data['area']}, Landmark: ${data['landmark']}, Pincode: ${data['pincode']}';

              double subtotal = 0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Order ID: $orderId",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Status: $status",
                        style: TextStyle(
                          color: status == 'Cancelled'
                              ? Colors.red
                              : status == 'Delivered'
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Delivery Address:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(address),
                      const SizedBox(height: 8),
                      Text("Order Time: ${formatTimestamp(data['timestamp'])}"),
                      const Divider(height: 20, thickness: 1.2),
                      const Text(
                        "Items:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...items.map((item) {
                        final name = item['Name'];
                        final quantity = item['Quantity'];
                        final unitPrice = (item['Price']).toDouble();
                        final itemTotal = unitPrice * quantity;
                        subtotal += itemTotal;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            "• $name (₹$unitPrice × $quantity = ₹${itemTotal.toStringAsFixed(2)})",
                          ),
                        );
                      }).toList(),
                      const Divider(thickness: 1.2),
                      Text("Subtotal: ₹${subtotal.toStringAsFixed(2)}"),
                      if (thresholdDiscount > 0)
                        Text(
                          "Threshold Discount: -₹${thresholdDiscount.toStringAsFixed(2)}",
                          style: const TextStyle(color: Colors.green),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        "Final Price: ₹${finalTotal.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (status == 'Pending')
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                cancelOrder(context, orderId, userId),
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            label: const Text(
                              "Cancel Order",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
