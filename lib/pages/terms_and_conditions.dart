import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Terms and Conditions')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome to SabZr! By using our app and services, you agree to the following terms and conditions. Please read them carefully.\n\n"
                "1. Refunds and Replacements\n"
                "Customers are eligible for a refund or replacement for any damaged or unsatisfactory items on the day of delivery. Requests must be made within 3 hours of receiving the order. Approved refunds will be credited to the customer's bank account, with processing taking up to 3 working days.\n\n"
                "2. Order Cancellations\n"
                "If a customer chooses to cancel an order after it has been placed, 10% of the total amount will be deducted as a cancellation fee. The remaining amount will be refunded as per our standard refund processing timeline.\n\n"
                "3. Account Responsibility\n"
                "Users are responsible for maintaining the confidentiality of their SabZr account credentials. It is the user’s duty to promptly update any personal information to ensure accurate service and communication.\n\n"
                "4. Customer Support\n"
                "For assistance, feedback, or concerns, users can reach our Customer Care team at +91 88250 33089.\n\n"
                "By continuing to use the SabZr app, you acknowledge and agree to these terms. SabZr reserves the right to update or modify these conditions at any time without prior notice.",
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
