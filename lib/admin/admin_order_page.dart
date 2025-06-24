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
    _tabController = TabController(length: 2, vsync: this);
  }

  // ✅ Mark order as delivered in both AllOrders and user's subcollection
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

  // ✅ Delete delivered order from both collections
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Orders (Admin View)'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Delivered'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildOrdersList(delivered: false),
          buildOrdersList(delivered: true),
        ],
      ),
    );
  }

  Widget buildOrdersList({required bool delivered}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('AllOrders')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const Center(child: Text("No orders found"));

        final filteredOrders = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return delivered
              ? data['status'] == 'Delivered'
              : data['status'] != 'Delivered';
        }).toList();

        if (filteredOrders.isEmpty) {
          return Center(
            child: Text(
              delivered ? "No delivered orders" : "No pending orders",
            ),
          );
        }

        return ListView(
          children: filteredOrders
              .map((doc) => buildOrderCard(doc, context, !delivered))
              .toList(),
        );
      },
    );
  }

  // 🔧 Build order card UI
  Widget buildOrderCard(
    QueryDocumentSnapshot doc,
    BuildContext context,
    bool canMarkDelivered,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
    final status = data['status'] ?? 'Pending';
    final userId = data['userId'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "📦 Order ID: ${doc.id}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text("👤 Name: ${data['userName'] ?? ''}"),
            Text("📞 Phone: ${data['userPhone'] ?? ''}"),
            Text(
              "📍 Address: ${data['lane']}, ${data['area']}, ${data['landmark']}, Pincode: ${data['pincode']}",
            ),
            Text(
              "🚚 Status: $status",
              style: TextStyle(
                color: status == 'Delivered' ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "🧾 Items:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    "- ${item['Name'] ?? ''} | Qty: ${item['Quantity'] ?? ''} | ₹ ${item['Total'] ?? ''}",
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (canMarkDelivered)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text("Mark as Delivered"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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
                if (!canMarkDelivered)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text("Delete Order"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Confirm Delete"),
                          content: const Text(
                            "Are you sure you want to delete this delivered order?",
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
                          const SnackBar(
                            content: Text(
                              "Delivered order deleted successfully",
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
