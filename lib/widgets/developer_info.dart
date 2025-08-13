import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;

class DeveloperInfo extends StatelessWidget {
  const DeveloperInfo({super.key});

  void _launchURL(String url) async {
    if (kIsWeb) {
      html.window.open(url, "_blank");
    } else {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) {
                  return DraggableScrollableSheet(
                    initialChildSize: 0.6,
                    minChildSize: 0.4,
                    maxChildSize: 0.9,
                    builder: (context, scrollController) {
                      return Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF2196F3),
                                      Color(0xFF1565C0),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(24),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      "Help & Developer Info",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Contact us for support or inquiries",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              ListTile(
                                leading: const Icon(
                                  Icons.code,
                                  color: Colors.blue,
                                ),
                                title: const Text("Developer"),
                                subtitle: const Text("Sanjay NP"),
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.email_outlined,
                                  color: Colors.blue,
                                ),
                                title: const Text("Email"),
                                subtitle: const Text(
                                  "dev.sanju.codes@gmail.com",
                                ),
                                onTap: () => _launchURL(
                                  "mailto:dev.sanju.codes@gmail.com",
                                ),
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.phone,
                                  color: Colors.blue,
                                ),
                                title: const Text("Phone"),
                                subtitle: const Text("+91 8590902246"),
                                onTap: () => _launchURL("tel:+918590902246"),
                              ),

                              const Divider(),

                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  "Event Support",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.event,
                                  color: Colors.orange,
                                ),
                                title: const Text("Event Name"),
                                subtitle: const Text("Onam Celebration 2025"),
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.access_time,
                                  color: Colors.orange,
                                ),
                                title: const Text("Event Start Date"),
                                subtitle: const Text("August 30, 2025"),
                              ),

                              const Divider(),

                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  "Payment Help",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.payment,
                                  color: Colors.green,
                                ),
                                title: const Text("Payment Method"),
                                subtitle: const Text(
                                  "Razorpay Secure Payments",
                                ),
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.help_outline,
                                  color: Colors.green,
                                ),
                                title: const Text("Payment Support"),
                                subtitle: const Text(
                                  "For any payment issues, contact the developer or event support.",
                                ),
                              ),

                              const SizedBox(height: 20),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text(
                                      "Close",
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
            child: const Text(
              "Help / Developer Info",
              style: TextStyle(
                color: Colors.black87,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
