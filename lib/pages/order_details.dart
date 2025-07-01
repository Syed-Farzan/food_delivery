import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserOrdersPage extends StatefulWidget {
  const UserOrdersPage({super.key});

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
            title: Text("Cancel Order", style: TextStyle(color: Colors.red)),
            content: const Text("Are you sure you want to cancel this order?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("No", style: TextStyle(color: Colors.green)),
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
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'My Orders',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          DropdownButton<String>(
            value: selectedStatus,
            underline: SizedBox(),
            onChanged: (value) {
              setState(() {
                selectedStatus = value!;
              });
            },
            items: statusOptions.map((status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(
                  "Filter: $status",
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 12),
        ],
      ),
      backgroundColor: const Color(0xFFF8F9FB),
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
            return const Center(
              child: Text(
                "No orders found.",
                style: TextStyle(
                  color: Colors.black54,
                  fontFamily: 'Poppins',
                  fontSize: 16,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final doc = orders[index];
              final data = doc.data() as Map<String, dynamic>;
              final orderId = doc.id;

              final status = data['status'] ?? 'Pending';
              final userName = data['userName'] ?? 'Unknown';
              final userPhone = data['userPhone'] ?? 'Unknown';
              final paymentMode = data['paymentMode'] ?? 'Unknown';
              final address =
                  '${data['lane']}, ${data['area']}, Landmark: ${data['landmark']}, Pincode: ${data['pincode']}';
              final timestamp = data['timestamp'] as Timestamp;
              final items = data['items'] as List<dynamic>;

              int total = 0;

              return Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.withOpacity(0.10)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.07),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Order ID: $orderId",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Status: $status",
                      style: TextStyle(
                        color: status == 'Cancelled'
                            ? Colors.red
                            : status == 'Delivered'
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "User: $userName",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      "Phone: $userPhone",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      "Payment Mode: $paymentMode",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Delivery Address:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      address,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Order Time: ${formatTimestamp(timestamp)}",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const Divider(height: 20, thickness: 1.1),
                    const Text(
                      "Items:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    ...items.map((item) {
                      final name = item['Name'] ?? '';
                      final quantity = item['Quantity'] ?? '1';
                      final totalPrice = item['Total'] ?? '0';
                      final saved = item['Saved'] ?? '0.00';

                      final parsedTotal = (totalPrice is num)
                          ? totalPrice.toInt()
                          : int.tryParse(totalPrice.toString()) ?? 0;

                      total += parsedTotal;

                      final savedStr = saved != '0.00' && saved != null
                          ? " (Saved ₹$saved)"
                          : "";

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          "• $name x$quantity - ₹$totalPrice$savedStr",
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    }),
                    const Divider(thickness: 1.1),
                    Text(
                      "Total: ₹$total",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        color: Colors.black87,
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
                            style: TextStyle(
                              color: Colors.red,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
