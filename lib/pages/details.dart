import 'package:flutter/material.dart';
import 'package:food_delivery/service/database.dart';
import 'package:food_delivery/service/shared_pref.dart';
import 'package:food_delivery/widgets/widget_support.dart';

class Details extends StatefulWidget {
  final String image, name, detail;
  final double? originalPrice, discountedPrice;
  final bool inStock;

  Details({
    required this.image,
    required this.name,
    required this.detail,
    required this.originalPrice,
    required this.discountedPrice,
    required this.inStock,
  });

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  int quantity = 1;
  String? id;
  bool isAddingToCart = false;

  getSharedPrefs() async {
    id = await SharedPrefrenceHelper().getUserId();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getSharedPrefs();
  }

  double getPerItemPrice() {
    final original = widget.originalPrice ?? 0;
    final discounted = widget.discountedPrice ?? original;
    return discounted;
  }

  double getTotalPrice() {
    return getPerItemPrice() * quantity;
  }

  double getSavedAmount() {
    final original = widget.originalPrice ?? 0;
    return (original - getPerItemPrice()) * quantity;
  }

  @override
  Widget build(BuildContext context) {
    final double perItemPrice = getPerItemPrice();
    final double totalPrice = getTotalPrice();
    final double savedAmount = getSavedAmount();
    final bool hasDiscount = savedAmount > 0;

    return Scaffold(
      body: Container(
        margin: EdgeInsets.only(top: 60, left: 20, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.arrow_back_ios_new_outlined),
            ),
            SizedBox(height: 15),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                widget.image,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 2.5,
                fit: BoxFit.fill,
              ),
            ),
            SizedBox(height: 15),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: AppWidget.semiboldTextFeildStyle(),
                      ),
                      SizedBox(height: 6),
                      if (!widget.inStock)
                        Text(
                          'Out of Stock',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else ...[
                        if (hasDiscount)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${widget.originalPrice!.toStringAsFixed(2)} INR",
                                style: AppWidget.lightTextFeildStyle().copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                "${perItemPrice.toStringAsFixed(2)} INR per item",
                                style: AppWidget.boldTextFeildStyle().copyWith(
                                  color: Colors.green,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            "${perItemPrice.toStringAsFixed(2)} INR",
                            style: AppWidget.boldTextFeildStyle(),
                          ),
                      ],
                    ],
                  ),
                ),
                if (widget.inStock)
                  Row(
                    children: [
                      _quantityControlButton(Icons.remove, () {
                        if (quantity > 1) setState(() => quantity--);
                      }),
                      SizedBox(width: 20),
                      Text(
                        quantity.toString(),
                        style: AppWidget.semiboldTextFeildStyle(),
                      ),
                      SizedBox(width: 10),
                      _quantityControlButton(Icons.add, () {
                        setState(() => quantity++);
                      }),
                    ],
                  ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              widget.detail,
              style: AppWidget.lightTextFeildStyle(),
              maxLines: 4,
            ),
            SizedBox(height: 30),
            Row(
              children: [
                Text(
                  'Delivery Time',
                  style: AppWidget.semiboldTextFeildStyle(),
                ),
                SizedBox(width: 5),
                Icon(Icons.alarm, color: Colors.black),
                SizedBox(width: 5),
                Text('30 min', style: AppWidget.semiboldTextFeildStyle()),
              ],
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Price',
                        style: AppWidget.semiboldTextFeildStyle(),
                      ),
                      if (!widget.inStock)
                        Text(
                          "Out of Stock",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else if (hasDiscount)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${(widget.originalPrice! * quantity).toStringAsFixed(2)} INR",
                              style: AppWidget.lightTextFeildStyle().copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.red,
                              ),
                            ),
                            Text(
                              '${totalPrice.toStringAsFixed(2)} INR',
                              style: AppWidget.headlineTextFeildStyle(),
                            ),
                            Text(
                              'You saved ${savedAmount.toStringAsFixed(2)} INR!',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          '${totalPrice.toStringAsFixed(2)} INR',
                          style: AppWidget.headlineTextFeildStyle(),
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: (!widget.inStock || isAddingToCart)
                      ? null
                      : () async {
                          setState(() => isAddingToCart = true);
                          Map<String, dynamic> cartItem = {
                            "Name": widget.name,
                            'Quantity': quantity.toString(),
                            'Total': totalPrice.toDouble(),
                            'Image': widget.image,
                            'PricePerItem': perItemPrice.toStringAsFixed(2),
                            'OriginalPrice':
                                widget.originalPrice?.toStringAsFixed(2) ?? '',
                            'DiscountApplied': hasDiscount
                                ? 'Discount'
                                : 'None',
                            'Saved': savedAmount.toStringAsFixed(2),
                          };
                          await DatabaseMethods().addFoodtoCart(cartItem, id!);
                          setState(() => isAddingToCart = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.red,
                              content: Text('Food added to cart'),
                            ),
                          );
                        },
                  child: Container(
                    width: MediaQuery.of(context).size.width / 2,
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: widget.inStock ? Colors.black : Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: isAddingToCart
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.inStock ? 'Add to Cart' : 'Out of Stock',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              if (widget.inStock) ...[
                                SizedBox(width: 20),
                                Container(
                                  padding: EdgeInsets.all(3),
                                  margin: EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.shopping_cart_outlined,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quantityControlButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
