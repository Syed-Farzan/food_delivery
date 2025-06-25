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
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Orders (Admin View)'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Delivered'),
            Tab(text: 'Cancelled'),
          ],
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
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const Center(child: Text("No orders found"));

        final filteredOrders = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == status;
        }).toList();

        if (filteredOrders.isEmpty) {
          return Center(child: Text("No $status orders"));
        }

        return ListView(
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
    final viewed = data['viewedByAdmin'] ?? false;

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
                color: status == 'Delivered'
                    ? Colors.green
                    : status == 'Cancelled'
                    ? Colors.red
                    : Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "🧾 Items:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text(
                  "- ${item['Name'] ?? ''} | Qty: ${item['Quantity'] ?? ''} | ₹ ${item['Total'] ?? ''}",
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status == 'Pending')
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
                if (status == 'Delivered')
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
                if (status == 'Cancelled' && viewed == false)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.visibility),
                    label: const Text("Mark as Viewed"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    onPressed: () async {
                      await markCancelledAsViewed(doc.id, userId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Marked as viewed")),
                      );
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
