import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class Raz extends StatefulWidget {
  const Raz({super.key});

  @override
  State<Raz> createState() => _RazState();
}

class _RazState extends State<Raz> {
  late Razorpay _razorpay;

  void _handlePaymentsucess(PaymentSuccessResponse response) {
    //  do something on sucess
  }

  void _handlePaymenterror(PaymentFailureResponse response) {
    // do something on error
  }

  void _handleExternalWalletResponse(ExternalWalletResponse response) {
    // do something on external wallet response
  }

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentsucess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymenterror);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWalletResponse);
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }

  void openCheckkout() async {
    var options = {
      'key': 'rzp_test_icUYkQuoZmE36O',
      'amount': 100,
      'name': 'Arhan',
      'descryption': 'Flutter Cource',
      'prefil': {'contact': '6005077810', 'email': '123@gmail.com'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Razor Pay')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            openCheckkout();
          },
          child: Text('pay '),
        ),
      ),
    );
  }
}
