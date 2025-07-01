import 'package:flutter/material.dart';
import 'package:food_delivery/service/database.dart';
import 'package:food_delivery/service/shared_pref.dart';

class Details extends StatefulWidget {
  final String image, name, detail;
  final double? originalPrice, discountedPrice;
  final bool inStock;

  const Details({
    super.key,
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
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_outlined,
                        color: Colors.black87,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    if (!widget.inStock)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Out of Stock',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                // Product image
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(
                      widget.image,
                      width: MediaQuery.of(context).size.width * 0.85,
                      height: MediaQuery.of(context).size.height / 2.7,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                // Name & price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (hasDiscount)
                            Row(
                              children: [
                                Text(
                                  "${widget.originalPrice!.toStringAsFixed(2)} INR",
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.red,
                                    fontSize: 15,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "${perItemPrice.toStringAsFixed(2)} INR",
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              "${perItemPrice.toStringAsFixed(2)} INR",
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                                fontFamily: 'Poppins',
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (widget.inStock)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _quantityControlButton(Icons.remove, () {
                              if (quantity > 1) setState(() => quantity--);
                            }),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Text(
                                quantity.toString(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                            _quantityControlButton(Icons.add, () {
                              setState(() => quantity++);
                            }),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Description
                Text(
                  widget.detail,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    fontFamily: 'Poppins',
                    height: 1.5,
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 28),
                // Delivery info
                Row(
                  children: [
                    const Icon(Icons.alarm, color: Colors.green, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Delivery within 2 Hrs',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // Total price and Add to Cart
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 16,
                  ),
                  margin: const EdgeInsets.only(bottom: 12, top: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Total price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Price',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
                              color: Colors.black87,
                            ),
                          ),
                          if (hasDiscount)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${(widget.originalPrice! * quantity).toStringAsFixed(2)} INR",
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.red,
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                Text(
                                  '${totalPrice.toStringAsFixed(2)} INR',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                Text(
                                  'You saved ${savedAmount.toStringAsFixed(2)} INR!',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              '${totalPrice.toStringAsFixed(2)} INR',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontFamily: 'Poppins',
                              ),
                            ),
                        ],
                      ),
                      // Add to Cart button
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
                                  'PricePerItem': perItemPrice.toStringAsFixed(
                                    2,
                                  ),
                                  'OriginalPrice':
                                      widget.originalPrice?.toStringAsFixed(
                                        2,
                                      ) ??
                                      '',
                                  'DiscountApplied': hasDiscount
                                      ? 'Discount'
                                      : 'None',
                                  'Saved': savedAmount.toStringAsFixed(2),
                                };
                                await DatabaseMethods().addFoodtoCart(
                                  cartItem,
                                  id!,
                                );
                                setState(() => isAddingToCart = false);
                                // No SnackBar for add to cart
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: MediaQuery.of(context).size.width / 2.2,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: widget.inStock ? Colors.green : Colors.grey,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              if (widget.inStock)
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                            ],
                          ),
                          child: isAddingToCart
                              ? const Center(
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      widget.inStock
                                          ? 'Add to Cart'
                                          : 'Out of Stock',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (widget.inStock)
                                      const SizedBox(width: 16),
                                    if (widget.inStock)
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.shopping_cart_outlined,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                  ],
                                ),
                        ),
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
  }

  Widget _quantityControlButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
