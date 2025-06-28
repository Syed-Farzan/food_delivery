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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Items"), centerTitle: true),
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
                        subtitle: Text("₹${data['DiscountedPrice']}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            // Store item data before deletion
                            final deletedDoc = doc;
                            final deletedData = Map<String, dynamic>.from(data);

                            // Delete the document
                            await FirebaseFirestore.instance
                                .collection(selectedCategory)
                                .doc(doc.id)
                                .delete();

                            // Show snackbar with undo
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
