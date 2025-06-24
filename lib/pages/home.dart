import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_delivery/pages/details.dart';
import 'package:food_delivery/service/database.dart';
import 'package:food_delivery/service/shared_pref.dart';
import 'package:food_delivery/widgets/widget_support.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String selectedCategory = "Vegetable"; // default category
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
        print("User document does not exist.");
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
        Name = value ?? "User"; // fallback if name is null
      });
    });
    onTheLoad(selectedCategory);
    super.initState();
  }

  Widget allitems() {
    return StreamBuilder(
      stream: fooditemStream,
      builder: (context, AsyncSnapshot snapshot) {
        return snapshot.hasData
            ? ListView.builder(
                itemCount: snapshot.data.docs.length,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.docs[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Details(
                            detail: ds['Detail'],
                            image: ds["Image"],
                            price: ds["Price"],
                            name: ds['Name'],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: 12),
                      child: Material(
                        elevation: 7,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 14,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  ds['Image'],
                                  height: 150,
                                  width: 150,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                ds['Name'],
                                style: AppWidget.boldTextFeildStyle(),
                              ),
                              SizedBox(height: 5),
                              Text(
                                ds['Detail'],
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: AppWidget.lightTextFeildStyle(),
                              ),
                              SizedBox(height: 5),
                              Text(
                                "${ds['Price']} INR",
                                style: AppWidget.boldTextFeildStyle(),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
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
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Details(
                            detail: ds['Detail'],
                            image: ds["Image"],
                            price: ds["Price"],
                            name: ds['Name'],
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
                                    Text(
                                      "${ds['Price']} INR",
                                      style: AppWidget.boldTextFeildStyle(),
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
                child: Column(
                  children: [
                    //SizedBox(height: 300, child: allitems()),
                    SizedBox(height: 30),
                    allitemsVertically(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
