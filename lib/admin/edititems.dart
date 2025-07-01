import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
      backgroundColor: Colors.grey.shade300,
      appBar: AppBar(
        backgroundColor: const Color(0xFFededeb),
        elevation: 4,
        title: const Text(
          'Edit Items',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          // Navigation bar for categories
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white, // Light background for visibility
              borderRadius: BorderRadius.circular(18),
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
              children: categories.map((cat) {
                final bool isSelected = selectedCategory == cat;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.ease,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF232526)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: !isSelected
                        ? Border.all(color: Colors.grey.shade300)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() {
                          selectedCategory = cat;
                        });
                      },
                      child: AnimatedPadding(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(
                          horizontal: isSelected ? 26 : 18,
                          vertical: 10,
                        ),
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
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
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(selectedCategory)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No items available.",
                        style: TextStyle(fontSize: 18, color: Colors.black54),
                      ),
                    );
                  }

                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final bool inStock = data['inStock'] ?? true;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              data['Image'] ?? '',
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image, size: 40),
                            ),
                          ),
                          title: Text(
                            data['Name'] ?? 'No Name',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                "₹${data['Price'] ?? data['OriginalPrice'] ?? '0'}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Text(
                                    "In Stock: ",
                                    style: TextStyle(fontSize: 15),
                                  ),
                                  Switch(
                                    value: inStock,
                                    activeColor: Colors.green,
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
                              final deletedData = Map<String, dynamic>.from(
                                data,
                              );

                              await FirebaseFirestore.instance
                                  .collection(selectedCategory)
                                  .doc(doc.id)
                                  .delete();

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "${deletedData['Name']} deleted",
                                  ),
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
                          // Add this onTap to open the edit page
                          onTap: () async {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditFoodPage(
                                  category: selectedCategory,
                                  docId: doc.id,
                                  initialData: data,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Now create a new file: edit_food.dart

// filepath: c:\Users\fasci\Programming_Files\Flutter\sabzr\food_delivery\lib\admin\edit_food.dart
class EditFoodPage extends StatefulWidget {
  final String category;
  final String docId;
  final Map<String, dynamic> initialData;

  const EditFoodPage({
    super.key,
    required this.category,
    required this.docId,
    required this.initialData,
  });

  @override
  State<EditFoodPage> createState() => _EditFoodPageState();
}

class _EditFoodPageState extends State<EditFoodPage> {
  late TextEditingController nameController;
  late TextEditingController detailController;
  late TextEditingController originalPriceController;
  late TextEditingController discountedPriceController;
  bool inStock = true;
  String? imageUrl;
  File? selectedImage;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: widget.initialData['Name'] ?? '',
    );
    detailController = TextEditingController(
      text: widget.initialData['Detail'] ?? '',
    );
    originalPriceController = TextEditingController(
      text: (widget.initialData['OriginalPrice'] ?? '').toString(),
    );
    discountedPriceController = TextEditingController(
      text: (widget.initialData['DiscountedPrice'] ?? '').toString(),
    );
    inStock = widget.initialData['inStock'] ?? true;
    imageUrl = widget.initialData['Image'];
  }

  Future<void> updateItem() async {
    setState(() {
      isUploading = true;
    });

    String? newImageUrl = imageUrl;

    if (selectedImage != null) {
      String fileName = widget.docId;
      Reference firebaseStorageRef = FirebaseStorage.instance
          .ref()
          .child('blogImages')
          .child(fileName);
      final UploadTask task = firebaseStorageRef.putFile(selectedImage!);
      newImageUrl = await (await task).ref.getDownloadURL();
    }

    Map<String, dynamic> updatedData = {
      'Name': nameController.text,
      'Detail': detailController.text,
      'OriginalPrice': double.tryParse(originalPriceController.text) ?? 0,
      'DiscountedPrice': double.tryParse(discountedPriceController.text) ?? 0,
      'inStock': inStock,
      'Image': newImageUrl,
    };

    await FirebaseFirestore.instance
        .collection(widget.category)
        .doc(widget.docId)
        .update(updatedData);

    setState(() {
      isUploading = false;
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Item updated successfully')));
  }

  Future<void> pickImage() async {
    // Use your preferred image picker here
    // For example, using image_picker package:
    // final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    // if (picked != null) {
    //   setState(() {
    //     selectedImage = File(picked.path);
    //   });
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFededeb),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_ios_new_outlined,
            color: Color(0xFF373866),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Edit Item',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.1,
          ),
        ),
      ),
      body: isUploading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Edit Item Picture',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onTap: pickImage,
                        child: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.black,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              color: Colors.white,
                            ),
                            child: selectedImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: Image.file(
                                      selectedImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : (imageUrl != null && imageUrl!.isNotEmpty)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: Image.network(
                                      imageUrl!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.black54,
                                    size: 50,
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Item Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: originalPriceController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: "Original Price",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: discountedPriceController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: "Discounted Price",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: detailController,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: "Item Detail",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        const Text("In Stock:", style: TextStyle(fontSize: 16)),
                        Switch(
                          value: inStock,
                          activeColor: Colors.green,
                          onChanged: (value) {
                            setState(() {
                              inStock = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),
                    Center(
                      child: GestureDetector(
                        onTap: updateItem,
                        child: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 170,
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF232526), Color(0xFF414345)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: Text(
                                'Update',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
