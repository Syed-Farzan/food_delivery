import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:food_delivery/service/database.dart';
import 'package:food_delivery/widgets/widget_support.dart';
import 'package:image_picker/image_picker.dart';
import 'package:random_string/random_string.dart';

class AddFood extends StatefulWidget {
  const AddFood({super.key});

  @override
  State<AddFood> createState() => _AddFoodState();
}

class _AddFoodState extends State<AddFood> {
  final List<String> items = ['Vegetable', 'Fruit', 'Dairy', 'Chicken'];
  String? value;

  // Controllers
  TextEditingController originalPriceController = TextEditingController();
  TextEditingController discountedPriceController = TextEditingController();
  TextEditingController itemdetailController = TextEditingController();
  TextEditingController itemnameController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? selectedImage;
  bool isUploading = false;

  Future getImage() async {
    var image = await _picker.pickImage(source: ImageSource.gallery);
    selectedImage = File(image!.path);
    setState(() {});
  }

  uploadItems() async {
    if (selectedImage != null &&
        itemdetailController.text.isNotEmpty &&
        itemnameController.text.isNotEmpty &&
        originalPriceController.text.isNotEmpty &&
        discountedPriceController.text.isNotEmpty) {
      double? originalPrice = double.tryParse(originalPriceController.text);
      double? discountedPrice = double.tryParse(discountedPriceController.text);

      // Validation
      if (originalPrice == null || discountedPrice == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Please enter valid numbers.'),
          ),
        );
        return;
      }

      if (originalPrice < 0 || discountedPrice < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Values cannot be negative.'),
          ),
        );
        return;
      }

      setState(() {
        isUploading = true;
      });

      // Firebase image upload
      String addID = randomAlphaNumeric(10);
      Reference firebaseStorageRef = FirebaseStorage.instance
          .ref()
          .child('blogImages')
          .child(addID);
      final UploadTask task = firebaseStorageRef.putFile(selectedImage!);
      var downloadURL = await (await task).ref.getDownloadURL();

      // Firebase map to upload
      Map<String, dynamic> addItem = {
        'Image': downloadURL,
        'Name': itemnameController.text,
        'Detail': itemdetailController.text,
        'OriginalPrice': originalPrice,
        'DiscountedPrice': discountedPrice,
        'inStock': true,
      };

      await DatabaseMethods().addFoodItems(addItem, value!).then((_) {
        setState(() {
          isUploading = false;
          selectedImage = null;
          itemnameController.clear();
          itemdetailController.clear();
          originalPriceController.clear();
          discountedPriceController.clear();
          value = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('The Item has been added successfully'),
          ),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Please fill all fields'),
        ),
      );
    }
  }

  Widget buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppWidget.semiboldTextFeildStyle()),
        SizedBox(height: 10),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumber
                ? TextInputType.numberWithOptions(decimal: true)
                : null,
            maxLines: maxLines,
            style: TextStyle(fontSize: 17, color: Colors.black87),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Enter $label',
              hintStyle: AppWidget.lightTextFeildStyle(),
            ),
          ),
        ),
        SizedBox(height: 22),
      ],
    );
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
          child: Icon(
            Icons.arrow_back_ios_new_outlined,
            color: Color(0xFF373866),
          ),
        ),
        centerTitle: true,
        title: Text('Add Items', style: AppWidget.headlineTextFeildStyle()),
      ),
      body: isUploading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Upload the Item Picture',
                        style: AppWidget.semiboldTextFeildStyle().copyWith(
                          fontSize: 20,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onTap: getImage,
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
                            child: selectedImage == null
                                ? Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.black54,
                                    size: 50,
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: Image.file(
                                      selectedImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                    buildTextField("Item Name", itemnameController),
                    buildTextField(
                      "Original Price",
                      originalPriceController,
                      isNumber: true,
                    ),
                    buildTextField(
                      "Discounted Price",
                      discountedPriceController,
                      isNumber: true,
                    ),
                    buildTextField(
                      "Item Detail",
                      itemdetailController,
                      maxLines: 6,
                    ),
                    Text(
                      'Select category',
                      style: AppWidget.semiboldTextFeildStyle(),
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          items: items
                              .map(
                                (item) => DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setState(() {
                            this.value = value;
                          }),
                          dropdownColor: Colors.white,
                          hint: Text('Select Category'),
                          iconSize: 36,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: Colors.black,
                          ),
                          value: value,
                        ),
                      ),
                    ),
                    SizedBox(height: 36),
                    Center(
                      child: GestureDetector(
                        onTap: uploadItems,
                        child: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 170,
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF232526), Color(0xFF414345)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                'Add',
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
