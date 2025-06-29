import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_delivery/pages/details.dart';
import 'package:food_delivery/service/database.dart';
import 'package:food_delivery/widgets/widget_support.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String selectedCategory = "Vegetable";
  Stream? fooditemStream;
  String? Name;

  onTheLoad(String category) async {
    fooditemStream = await DatabaseMethods().getFoodItem(category);
    setState(() {});
  }

  Future<String?> getUserName() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData['Name'];
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting user name: $e');
      return null;
    }
  }

  @override
  void initState() {
    getUserName().then((value) {
      setState(() {
        Name = value ?? "User";
      });
    });
    onTheLoad(selectedCategory);
    super.initState();
  }

  Widget allitemsVertically() {
    return StreamBuilder(
      stream: fooditemStream,
      builder: (context, AsyncSnapshot snapshot) {
        return snapshot.hasData
            ? ListView.builder(
                itemCount: snapshot.data.docs.length,
                padding: EdgeInsets.zero,
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.docs[index];
                  bool outOfStock = ds['inStock'] ?? false;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Details(
                            detail: ds['Detail'] ?? '',
                            image: ds['Image'] ?? '',
                            name: ds['Name'] ?? '',
                            originalPrice: (ds['OriginalPrice'] as num?)
                                ?.toDouble(),
                            discountedPrice: (ds['DiscountedPrice'] as num?)
                                ?.toDouble(),
                            inStock: outOfStock,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.only(bottom: 10),
                      child: Material(
                        elevation: 5,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: EdgeInsets.all(10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  ds['Image'],
                                  height: 120,
                                  width: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ds['Name'],
                                      style: AppWidget.semiboldTextFeildStyle(),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      ds['Detail'],
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: AppWidget.lightTextFeildStyle(),
                                    ),
                                    SizedBox(height: 5),
                                    !outOfStock
                                        ? Text(
                                            "Out of Stock",
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : _buildPriceTag(
                                            (ds['OriginalPrice'] as num?)
                                                ?.toDouble(),
                                            (ds['DiscountedPrice'] as num?)
                                                ?.toDouble(),
                                          ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              )
            : Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildPriceTag(double? original, double? discounted) {
    if (discounted != null && discounted != 0 && discounted != original) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${original?.toStringAsFixed(2)} INR",
            style: AppWidget.lightTextFeildStyle().copyWith(
              decoration: TextDecoration.lineThrough,
              color: Colors.red,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 2),
          Text(
            "${discounted.toStringAsFixed(2)} INR",
            style: AppWidget.boldTextFeildStyle(),
          ),
        ],
      );
    } else {
      return Text(
        "${original?.toStringAsFixed(2) ?? discounted?.toStringAsFixed(2) ?? 'N/A'} INR",
        style: AppWidget.boldTextFeildStyle(),
      );
    }
  }

  Widget showItem() {
    List<Map<String, dynamic>> categories = [
      {"name": "Vegetable", "icon": "lib/images/vegetables.png"},
      {"name": "Fruit", "icon": "lib/images/fruit.png"},
      {"name": "Dairy", "icon": "lib/images/dairy-products.png"},
      {"name": "Chicken", "icon": "lib/images/christmas-dinner.png"},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: categories.map((category) {
        bool selected = selectedCategory == category["name"];
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedCategory = category["name"];
              onTheLoad(selectedCategory);
            });
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: selected ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? Colors.black : Colors.grey.shade300,
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            padding: EdgeInsets.all(10),
            child: Image.asset(
              category["icon"],
              height: 40,
              width: 40,
              fit: BoxFit.contain,
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: EdgeInsets.only(top: 60, left: 20, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hello ${Name ?? ""}',
                  style: AppWidget.boldTextFeildStyle(),
                ),
                Container(
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.shopping_cart, color: Colors.white),
                ),
              ],
            ),
            SizedBox(height: 15),
            Text(
              'Nutritious Veggies!',
              style: AppWidget.headlineTextFeildStyle(),
            ),
            Text(
              'Discover and Get Products',
              style: AppWidget.lightTextFeildStyle(),
            ),
            SizedBox(height: 20),
            showItem(),
            SizedBox(height: 30),
            Expanded(
              child: SingleChildScrollView(
                child: Column(children: [allitemsVertically()]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
