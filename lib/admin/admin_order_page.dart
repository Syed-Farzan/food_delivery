import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> markAsDelivered(String docId, String userId) async {
    final firestore = FirebaseFirestore.instance;

    await firestore.collection('AllOrders').doc(docId).update({
      'status': 'Delivered',
    });

    await firestore
        .collection('users')
        .doc(userId)
        .collection('Orders')
        .doc(docId)
        .update({'status': 'Delivered'});
  }

  Future<void> deleteDeliveredOrder(String docId, String userId) async {
    final firestore = FirebaseFirestore.instance;

    await firestore.collection('AllOrders').doc(docId).delete();
    await firestore
        .collection('users')
        .doc(userId)
        .collection('Orders')
        .doc(docId)
        .delete();
  }

  Future<void> markCancelledAsViewed(String docId, String userId) async {
    await FirebaseFirestore.instance.collection('AllOrders').doc(docId).update({
      'viewedByAdmin': true,
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('Orders')
        .doc(docId)
        .update({'viewedByAdmin': true});
  }

  @override
  Widget build(BuildContext context) {
    final List<String> orderCategories = ['Pending', 'Delivered', 'Cancelled'];

    return Scaffold(
      backgroundColor: const Color(0xFFededeb),
      appBar: AppBar(
        backgroundColor: const Color(0xFF232526),
        elevation: 4,
        iconTheme: const IconThemeData(
          color: Colors.white, // Makes the back arrow light colored
        ),
        title: const Text(
          'All Orders (Admin View)',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: orderCategories.asMap().entries.map((entry) {
                final int idx = entry.key;
                final String cat = entry.value;
                // No highlight for any option
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        _tabController.index = idx;
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        child: DefaultTextStyle(
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.normal,
                            fontSize: 16,
                            letterSpacing: 1.1,
                          ),
                          child: Text(cat),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildOrdersList(status: 'Pending'),
          buildOrdersList(status: 'Delivered'),
          buildOrdersList(status: 'Cancelled'),
        ],
      ),
    );
  }

  Widget buildOrdersList({required String status}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('AllOrders')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No orders found",
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
          );
        }

        final filteredOrders = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == status;
        }).toList();

        if (filteredOrders.isEmpty) {
          return Center(
            child: Text(
              "No $status orders",
              style: const TextStyle(fontSize: 18, color: Colors.black54),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          children: filteredOrders
              .map((doc) => buildOrderCard(doc, context, status))
              .toList(),
        );
      },
    );
  }

  Widget buildOrderCard(
    QueryDocumentSnapshot doc,
    BuildContext context,
    String status,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
    final userId = data['userId'];
    final deliveryFee = data['deliveryFee'] ?? 0;
    final grandTotal = data['grandTotal'] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      elevation: 7,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: Colors.grey[800]),
                const SizedBox(width: 8),
                Text(
                  "Order ID: ${doc.id}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: status == 'Delivered'
                        ? Colors.green[100]
                        : status == 'Cancelled'
                        ? Colors.red[100]
                        : Colors.orange[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: status == 'Delivered'
                          ? Colors.green[800]
                          : status == 'Cancelled'
                          ? Colors.red[800]
                          : Colors.orange[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1.2),
            Row(
              children: [
                const Icon(Icons.person, color: Colors.black54, size: 20),
                const SizedBox(width: 6),
                Text(
                  data['userName'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 18),
                const Icon(Icons.phone, color: Colors.black54, size: 20),
                const SizedBox(width: 6),
                Text(
                  data['userPhone'] ?? '',
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: Colors.black54, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "${data['lane']}, ${data['area']}, ${data['landmark']}, Pincode: ${data['pincode']}",
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              "Items:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    const Icon(Icons.fastfood, size: 18, color: Colors.black54),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "${item['Name'] ?? ''} | Qty: ${item['Quantity'] ?? ''} | ₹ ${item['Total'] ?? ''}",
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // --- Delivery Fee and Grand Total Section (now vertical, left-aligned) ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Delivery Fee: ₹$deliveryFee",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Total: ₹$grandTotal",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status == 'Pending') ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text("Mark as Delivered"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () async {
                      await markAsDelivered(doc.id, userId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Order marked as Delivered"),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.cancel),
                    label: const Text("Cancel Order"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Confirm Cancel"),
                          content: const Text(
                            "Are you sure you want to cancel this order?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("No"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Yes, Cancel"),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await FirebaseFirestore.instance
                            .collection('AllOrders')
                            .doc(doc.id)
                            .update({'status': 'Cancelled'});
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .collection('Orders')
                            .doc(doc.id)
                            .update({'status': 'Cancelled'});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Order cancelled")),
                        );
                      }
                    },
                  ),
                ],
                if (status == 'Delivered' || status == 'Cancelled')
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text("Delete Order"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Confirm Delete"),
                          content: Text(
                            status == 'Delivered'
                                ? "Are you sure you want to delete this delivered order?"
                                : "Are you sure you want to delete this cancelled order?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Delete"),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await deleteDeliveredOrder(doc.id, userId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              status == 'Delivered'
                                  ? "Delivered order deleted successfully"
                                  : "Cancelled order deleted successfully",
                            ),
                          ),
                        );
                      }
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
