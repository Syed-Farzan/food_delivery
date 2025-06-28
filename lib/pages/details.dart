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

    if (widget.threshold3 != null && quantity >= widget.threshold3!) {
      return widget.threshold3Amount ?? discounted;
    } else if (widget.threshold2 != null && quantity >= widget.threshold2!) {
      return widget.threshold2Amount ?? discounted;
    } else if (widget.threshold1 != null && quantity >= widget.threshold1!) {
      return widget.threshold1Amount ?? discounted;
    }
    return discounted;
  }

  double getTotalPrice() {
    return getPerItemPrice() * quantity;
  }

  double getSavedAmount() {
    final original = widget.originalPrice ?? 0;
    double totalWithoutDiscount = quantity * original;
    return totalWithoutDiscount - getTotalPrice();
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

  @override
  Widget build(BuildContext context) {
    final double totalPrice = getTotalPrice();
    final double savedAmount = getSavedAmount();
    final String? thresholdMessage = getActiveThresholdMessage();
    final bool hasDiscount = savedAmount > 0;
    final double perItemPrice = getPerItemPrice();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 20),
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
                // 1. Quantity controls area
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            style: AppWidget.semiboldTextFeildStyle(),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6),
                          if (hasDiscount)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${widget.originalPrice!.toStringAsFixed(2)} INR",
                                  style: AppWidget.lightTextFeildStyle()
                                      .copyWith(
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.red,
                                        fontSize: 14,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "${perItemPrice.toStringAsFixed(2)} INR per item",
                                  style: AppWidget.boldTextFeildStyle()
                                      .copyWith(
                                        color: Colors.green,
                                        fontSize: 15,
                                      ),
                                  overflow: TextOverflow.ellipsis,
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
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${widget.originalPrice!.toStringAsFixed(2)} INR",
                                  style: AppWidget.lightTextFeildStyle()
                                      .copyWith(
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.red,
                                        fontSize: 14,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "${perItemPrice.toStringAsFixed(2)} INR (Discounted)",
                                  style: AppWidget.boldTextFeildStyle()
                                      .copyWith(
                                        color: Colors.green,
                                        fontSize: 15,
                                      ),
                                  overflow: TextOverflow.ellipsis,
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
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    // Quantity controls
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _quantityControlButton(Icons.remove, () {
                          if (quantity > 1) setState(() => quantity--);
                        }),
                        SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: 24,
                            maxWidth: 40,
                          ),
                          child: Center(
                            child: Text(
                              quantity.toString(),
                              style: AppWidget.semiboldTextFeildStyle(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
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
                    Text(
                      'within 2Hrs',
                      style: AppWidget.semiboldTextFeildStyle(),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                // 2. "Add to Cart" button area
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
                          if (hasDiscount)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${(widget.originalPrice! * quantity).toStringAsFixed(2)} INR",
                                  style: AppWidget.lightTextFeildStyle()
                                      .copyWith(
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.red,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${totalPrice.toStringAsFixed(2)} INR',
                                  style: AppWidget.headlineTextFeildStyle(),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'You saved ${savedAmount.toStringAsFixed(2)} INR!',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            )
                          else
                            Text(
                              '${totalPrice.toStringAsFixed(2)} INR',
                              style: AppWidget.headlineTextFeildStyle(),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: GestureDetector(
                        onTap: isAddingToCart
                            ? null
                            : () async {
                                setState(() => isAddingToCart = true);

                                Map<String, dynamic> cartItem = {
                                  "Name": widget.name,
                                  'Quantity': quantity.toString(),
                                  'Total': totalPrice.toDouble(),
                                  'Image': widget.image,
                                  'PricePerItem': perItemPrice.toStringAsFixed(
                                    2,
                                  ),
                                  'OriginalPrice':
                                      widget.originalPrice?.toStringAsFixed(
                                        2,
                                      ) ??
                                      '',
                                  'DiscountApplied': hasDiscount
                                      ? 'Threshold Discount'
                                      : 'None',
                                  'Saved': savedAmount.toStringAsFixed(2),
                                };

                                await DatabaseMethods().addFoodtoCart(
                                  cartItem,
                                  id!,
                                );

                                setState(() => isAddingToCart = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.red,
                                    content: Text('Food added to cart'),
                                  ),
                                );
                              },
                        child: Container(
                          // Remove fixed width, use padding only
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: isAddingToCart
                              ? Center(
                                  child: SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Add to Cart',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontFamily: 'Poppins',
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.shopping_cart,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
