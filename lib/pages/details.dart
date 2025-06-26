import 'package:flutter/material.dart';
import 'package:food_delivery/service/database.dart';
import 'package:food_delivery/service/shared_pref.dart';
import 'package:food_delivery/widgets/widget_support.dart';

class Details extends StatefulWidget {
  final String image, name, detail;
  final double? originalPrice, discountedPrice;
  final double? threshold1, threshold2, threshold3;
  final double? threshold1Amount, threshold2Amount, threshold3Amount;

  Details({
    required this.detail,
    required this.image,
    required this.name,
    required this.originalPrice,
    required this.discountedPrice,
    required this.threshold1,
    required this.threshold2,
    required this.threshold3,
    required this.threshold1Amount,
    required this.threshold2Amount,
    required this.threshold3Amount,
  });

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  int quantity = 1;
  String? id;
  bool isAddingToCart = false;

  double getEffectivePricePerItem() {
    if (widget.discountedPrice != null &&
        widget.discountedPrice != widget.originalPrice) {
      return widget.discountedPrice!;
    }
    return widget.originalPrice ?? 0;
  }

  double getActiveThresholdDiscount(double qty) {
    if (widget.threshold3 != null && qty >= widget.threshold3!) {
      return widget.threshold3Amount ?? 0;
    } else if (widget.threshold2 != null && qty >= widget.threshold2!) {
      return widget.threshold2Amount ?? 0;
    } else if (widget.threshold1 != null && qty >= widget.threshold1!) {
      return widget.threshold1Amount ?? 0;
    }
    return 0;
  }

  double getTotalPrice() {
    double pricePerItem = getEffectivePricePerItem();
    double subtotal = quantity * pricePerItem;
    double thresholdDiscount = getActiveThresholdDiscount(quantity.toDouble());
    return subtotal - thresholdDiscount;
  }

  String? getActiveThresholdMessage() {
    if (widget.threshold3 != null && quantity >= widget.threshold3!) {
      return "You've unlocked the highest discount!";
    } else if (widget.threshold2 != null && quantity >= widget.threshold2!) {
      return "You've unlocked a bigger discount!";
    } else if (widget.threshold1 != null && quantity >= widget.threshold1!) {
      return "You've unlocked a discount!";
    } else if (widget.threshold1 != null && quantity < widget.threshold1!) {
      int needed = (widget.threshold1! - quantity).ceil();
      return "Add $needed ${needed > 1 ? 'items' : 'item'} for a discount!";
    }
    return null;
  }

  getSharedPrefs() async {
    id = await SharedPrefrenceHelper().getUserId();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getSharedPrefs();
  }

  @override
  Widget build(BuildContext context) {
    final double itemPrice = getEffectivePricePerItem();
    final double totalPrice = getTotalPrice();
    final double thresholdDiscount = getActiveThresholdDiscount(
      quantity.toDouble(),
    );
    final bool hasRegularDiscount =
        widget.discountedPrice != null &&
        widget.discountedPrice != widget.originalPrice;
    final String? thresholdMessage = getActiveThresholdMessage();

    return Scaffold(
      body: Container(
        margin: EdgeInsets.only(top: 60, left: 20, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(
                Icons.arrow_back_ios_new_outlined,
                color: Colors.black,
              ),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: AppWidget.semiboldTextFeildStyle(),
                    ),
                    SizedBox(height: 6),
                    if (thresholdDiscount > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${(itemPrice * quantity).toStringAsFixed(2)} INR",
                            style: AppWidget.lightTextFeildStyle().copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "${totalPrice.toStringAsFixed(2)} INR",
                            style: AppWidget.boldTextFeildStyle(),
                          ),
                          if (thresholdMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                thresholdMessage,
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      )
                    else if (hasRegularDiscount)
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
                          SizedBox(height: 2),
                          Text(
                            "${widget.discountedPrice!.toStringAsFixed(2)} INR",
                            style: AppWidget.boldTextFeildStyle(),
                          ),
                        ],
                      )
                    else
                      Text(
                        "${itemPrice.toStringAsFixed(2)} INR",
                        style: AppWidget.boldTextFeildStyle(),
                      ),
                  ],
                ),
                Spacer(),
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
                      if (thresholdDiscount > 0)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${(itemPrice * quantity).toStringAsFixed(2)} INR",
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
                              'You saved ${thresholdDiscount.toStringAsFixed(2)} INR!',
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
                  onTap: isAddingToCart
                      ? null
                      : () async {
                          setState(() => isAddingToCart = true);

                          final double savedAmount = thresholdDiscount > 0
                              ? thresholdDiscount
                              : hasRegularDiscount
                              ? (widget.originalPrice! -
                                    widget.discountedPrice!)
                              : 0;

                          Map<String, dynamic> cartItem = {
                            "Name": widget.name,
                            'Quantity': quantity.toString(),
                            'Total': totalPrice.toStringAsFixed(2),
                            'Image': widget.image,
                            'PricePerItem': itemPrice.toStringAsFixed(2),
                            'OriginalPrice':
                                widget.originalPrice?.toStringAsFixed(2) ?? '',
                            'DiscountApplied': thresholdDiscount > 0
                                ? 'Threshold Discount'
                                : hasRegularDiscount
                                ? 'Regular Discount'
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
                      color: Colors.black,
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
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Add to Cart',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              SizedBox(width: 40),
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
                              SizedBox(width: 10),
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
