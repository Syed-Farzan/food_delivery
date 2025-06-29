import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditItems extends StatefulWidget {
  const EditItems({super.key});

  @override
  State<EditItems> createState() => _EditItemsState();
}

class _EditItemsState extends State<EditItems> {
  String selectedCategory = 'Vegetable';
  List<String> categories = ['Vegetable', 'Fruit', 'Dairy', 'Chicken'];

  String? internalPage = 'Edit Items';

  final List<String> internalPages = [
    'Edit Items',
    'Add Item',
    'Orders',
    'Users',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: DropdownButton<String>(
          value: internalPage,
          underline: SizedBox(),
          icon: Icon(Icons.arrow_drop_down, color: Colors.white),
          dropdownColor: Colors.grey[900],
          style: const TextStyle(color: Colors.white, fontSize: 18),
          onChanged: (String? newPage) {
            setState(() {
              internalPage = newPage!;
              // You can add navigation logic here based on selected internal page
              if (internalPage != 'Edit Items') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Navigate to "$internalPage" page')),
                );
              }
            });
          },
          items: internalPages.map((String page) {
            return DropdownMenuItem<String>(value: page, child: Text(page));
          }).toList(),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          DropdownButton<String>(
            value: selectedCategory,
            onChanged: (String? newValue) {
              setState(() {
                selectedCategory = newValue!;
              });
            },
            items: categories.map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(selectedCategory)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No items available."));
                }

                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final bool inStock = data['inStock'] ?? true;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      elevation: 3,
                      child: ListTile(
                        leading: Image.network(
                          data['Image'] ?? '',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image),
                        ),
                        title: Text(data['Name'] ?? 'No Name'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "₹${data['Price'] ?? data['OriginalPrice'] ?? '0'}",
                            ),
                            Row(
                              children: [
                                const Text("In Stock: "),
                                Switch(
                                  value: inStock,
                                  onChanged: (value) async {
                                    await FirebaseFirestore.instance
                                        .collection(selectedCategory)
                                        .doc(doc.id)
                                        .update({'inStock': value});
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final deletedDoc = doc;
                            final deletedData = Map<String, dynamic>.from(data);

                            await FirebaseFirestore.instance
                                .collection(selectedCategory)
                                .doc(doc.id)
                                .delete();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("${deletedData['Name']} deleted"),
                                action: SnackBarAction(
                                  label: 'UNDO',
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection(selectedCategory)
                                        .doc(deletedDoc.id)
                                        .set(deletedData);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
