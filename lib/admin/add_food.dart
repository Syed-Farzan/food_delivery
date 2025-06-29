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
          padding: EdgeInsets.symmetric(horizontal: 10),
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: Color(0xFFececf8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumber
                ? TextInputType.numberWithOptions(decimal: true)
                : null,
            maxLines: maxLines,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Enter $label',
              hintStyle: AppWidget.lightTextFeildStyle(),
            ),
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload the Item Picture',
                      style: AppWidget.semiboldTextFeildStyle(),
                    ),
                    SizedBox(height: 20),
                    selectedImage == null
                        ? GestureDetector(
                            onTap: getImage,
                            child: Center(
                              child: Material(
                                elevation: 5,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Material(
                              elevation: 5,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.file(
                                    selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                    SizedBox(height: 30),
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
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        color: Color(0xFFececf8),
                        borderRadius: BorderRadius.circular(10),
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
                    SizedBox(height: 30),
                    GestureDetector(
                      onTap: uploadItems,
                      child: Center(
                        child: Material(
                          elevation: 5,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            width: 150,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Add',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
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
