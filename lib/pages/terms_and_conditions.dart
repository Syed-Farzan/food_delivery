import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  Future<void> _launchPhoneDialer(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Show error if unable to launch
      debugPrint('Could not launch $phone');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String phoneNumber = "+91 88250 33089";
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      backgroundColor: const Color(0xFFF8F9FB),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          margin: const EdgeInsets.symmetric(vertical: 18, horizontal: 0),
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Welcome to SabZr!",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w500, // lighter than bold
                    color: Colors.green,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  "By using our app and services, you agree to the following terms and conditions. Please read them carefully.",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 22),
                _buildSectionTitle("1. Refunds and Replacements"),
                const SizedBox(height: 6),
                const Text(
                  "Customers are eligible for a refund or replacement for any damaged or unsatisfactory items on the day of delivery. Requests must be made within 3 hours of receiving the order. Approved refunds will be credited to the customer's bank account, with processing taking up to 3 working days.",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 18),
                _buildSectionTitle("2. Order Cancellations"),
                const SizedBox(height: 6),
                const Text(
                  "If a customer chooses to cancel an order after it has been placed, 10% of the total amount will be deducted as a cancellation fee. The remaining amount will be refunded as per our standard refund processing timeline.",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 18),
                _buildSectionTitle("3. Account Responsibility"),
                const SizedBox(height: 6),
                const Text(
                  "Users are responsible for maintaining the confidentiality of their SabZr account credentials. It is the user’s duty to promptly update any personal information to ensure accurate service and communication.",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 18),
                _buildSectionTitle("4. Customer Support"),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                    children: [
                      const TextSpan(
                        text:
                            "For assistance, feedback, or concerns, users can reach our Customer Care team at ",
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: GestureDetector(
                          onTap: () => _launchPhoneDialer(phoneNumber),
                          child: Text(
                            phoneNumber,
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                              fontFamily: 'Poppins',
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: "."),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "By continuing to use the SabZr app, you acknowledge and agree to these terms. SabZr reserves the right to update or modify these conditions at any time without prior notice.",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.black54,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18, // Slightly larger
        fontWeight: FontWeight.w500, // Medium weight for slick look
        color: Colors.black87,
        fontFamily: 'Poppins',
      ),
    );
  }
}
