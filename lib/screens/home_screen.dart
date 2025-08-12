import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';
import 'package:event_ticket_maker/helper/string_helper.dart';
import 'package:event_ticket_maker/provider/select_image.dart';
import 'package:event_ticket_maker/provider/verification_state.dart';
import 'package:event_ticket_maker/screens/success_screen.dart';
import 'package:event_ticket_maker/services/storage_services.dart';
import 'package:event_ticket_maker/widgets/footer.dart';
import 'package:event_ticket_maker/widgets/glass_fields.dart';
import 'package:event_ticket_maker/widgets/loading_widget.dart';
import 'package:event_ticket_maker/widgets/qr_reminder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:js' as js;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> startPayment() async {
    final paymentProvider = Provider.of<PaymentProvider>(
      context,
      listen: false,
    );
    final imgProvider = Provider.of<ImageUploadProvider>(
      context,
      listen: false,
    );
    paymentProvider.setLoading(true);

    try {
      final name = nameController.text.trim();
      final phone = phoneController.text.trim();

      final phoneRegex = RegExp(r'^[6-9]\d{9}$');

      final validationError = StringHelper.validateFields(
        name,
        phone,
        phoneRegex,
      );
      if (validationError != null) {
        StringHelper.showError(validationError, context);
        paymentProvider.setLoading(false);

        return;
      }
      if ((kIsWeb && imgProvider.webImage == null) ||
          (!kIsWeb && imgProvider.selectedImageFile == null)) {
        StringHelper.showError("No image selected!", context);
        paymentProvider.setLoading(false);
        return;
      }

      debugPrint("Proceeding to payment...");

      final response = await http.post(
        Uri.parse(
          'https://us-central1-event-ticket-maker-8e724.cloudfunctions.net/api/create-order',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': 705 * 100,
          'receipt': 'receipt_${DateTime.now().millisecondsSinceEpoch}',
        }),
      );

      final responseData = jsonDecode(response.body);
      if (responseData['status'] != 'success') {
        if (mounted) {
          StringHelper.showError(
            "Order creation failed. Please try again.",
            context,
          );
        }
        paymentProvider.setLoading(false);

        return;
      }

      final orderId = responseData['body']['id'];
      openRazorpayCheckout(
        orderId: orderId,
        keyId: "rzp_test_lfbXLnyT9SLgph",
        amount: 705 * 100,
        name: name,
        phone: phone,
        onSuccess: (paymentId) =>
            verifyAndSaveTicket(paymentId: paymentId, name: name, phone: phone),
        onError: (err) =>
            StringHelper.showError("Payment failed: $err", context),
      );
    } catch (e) {
      if (mounted) {
        StringHelper.showError("An unexpected error occurred.", context);
      }
      debugPrint("Payment error: $e");
      paymentProvider.setLoading(false);
    } finally {
      paymentProvider.setLoading(false);
    }
  }

  Future<void> verifyAndSaveTicket({
    required String paymentId,
    required String name,
    required String phone,
  }) async {
    final paymentProvider = Provider.of<PaymentProvider>(
      context,
      listen: false,
    );
    final imageProvider = Provider.of<ImageUploadProvider>(
      context,
      listen: false,
    );

    paymentProvider.setLoading(true);

    final backendResponse = await http.post(
      Uri.parse(
        'https://us-central1-event-ticket-maker-8e724.cloudfunctions.net/api/verify-payment',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'payment_id': paymentId, 'name': name, 'phone': phone}),
    );

    final result = jsonDecode(backendResponse.body);

    if (result['status'] == 'success') {
      final ticketId = result['ticket_id'];
      String? imageUrl;
      if (kIsWeb && imageProvider.webImage != null) {
        imageUrl = await StorageService.uploadWebImage(
          data: imageProvider.webImage!,
          path:
              'id_cards/$ticketId/${imageProvider.webFileName ?? 'id_card.jpg'}',
        );
      } else if (!kIsWeb && imageProvider.selectedImageFile != null) {
        imageUrl = await StorageService.uploadImageFile(
          file: imageProvider.selectedImageFile!,
          path:
              'id_cards/$ticketId/${imageProvider.selectedImageFile!.path.split('/').last}',
        );
      }
      if (imageUrl != null) {
        StorageService.updateID(ticketId, imageUrl);
      }

      paymentProvider.setLoading(false);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SuccessScreen(ticketId: ticketId)),
        );
      }
    } else {
      log("Payment verification failed");
      log("Backend response: ${backendResponse.body}");

      paymentProvider.setLoading(false);
    }
  }

  void openRazorpayCheckout({
    required String orderId,
    required String keyId,
    required int amount,
    required String name,
    required String phone,
    required Function(String paymentId) onSuccess,
    required Function(String error) onError,
  }) {
    js.context.callMethod('eval', [
      """
    var options = {
      "key": "$keyId",
      "amount": "$amount",
      "currency": "INR",
      "name": "Onam Celebration",
      "description": "Ticket Payment",
      "order_id": "$orderId",
      "send_sms_hash": true,
      'readonly': {
        'contact': true,
        'email': true,
      },
      "handler": function (response){
        window.onFlutterPaymentSuccess(response.razorpay_payment_id);
      },
      'method': {
        'upi': true,
        'card': false,
        'netbanking': false,
        'wallet': false,
        'emi': false,
        'paylater': false
      },
      "prefill": {
        "name": "$name",
        "contact": "$phone"
      },
      "theme": {
        "color": "#F37254"
      }
    };
    var rzp = new Razorpay(options);
    rzp.open();
    rzp.on('payment.failed', function (response){
      window.onFlutterPaymentError(response.error.description);
    });
  """,
    ]);

    js.context["onFlutterPaymentSuccess"] = (String paymentId) {
      onSuccess(paymentId);
    };

    js.context["onFlutterPaymentError"] = (String error) {
      onError(error);
    };
  }

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: Consumer<PaymentProvider>(
        builder: (context, paymentProvider, _) {
          return Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  'https://cdn.dribbble.com/userupload/9637157/file/original-67f4815f35a54c02a49213d55e7f019b.jpg?resize=800x0',
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),

              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,

                      colors: [
                        Color.fromARGB(115, 253, 251, 251),
                        Color(0xFFE2D1C3),
                      ],
                    ),
                  ),

                  // color: Colors.black.withValues(alpha: .1),
                ),
              ),

              LayoutBuilder(
                builder: (context, constraints) {
                  final viewInsets = MediaQuery.of(context).viewInsets.bottom;

                  return SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          24,
                          30,
                          24,
                          viewInsets + 30,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Card(
                            elevation: 12,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Onam Celebration 2025',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Date: Aug 28, 2025\nVenue: Krupanidhi college\nTicket: ₹705 per person',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14,
                                      fontFamily: 'Quicksanju',
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  const Text(
                                    'Book Your Ticket',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                      fontFamily: "Quicksanju",
                                      letterSpacing: 0,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  PremiumTextField(
                                    controller: nameController,
                                    label: 'Full Name',
                                    icon: Icons.person,
                                  ),
                                  const SizedBox(height: 12),
                                  PremiumTextField(
                                    controller: phoneController,
                                    label: 'Phone Number',
                                    icon: Icons.phone,
                                    keyboardType: TextInputType.phone,
                                    prefixText: '+91 ',
                                  ),

                                  const SizedBox(height: 24),
                                  Consumer<ImageUploadProvider>(
                                    builder: (context, userProvider, _) {
                                      final bool imageSelected = kIsWeb
                                          ? userProvider.webImage != null
                                          : userProvider.selectedImageFile !=
                                                null;

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Upload Your College ID Card",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 8),

                                          Row(
                                            children: [
                                              Icon(
                                                imageSelected
                                                    ? Icons.check_circle
                                                    : Icons.warning,
                                                color: imageSelected
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                              const SizedBox(width: 8),
                                              SizedBox(
                                                width:
                                                    MediaQuery.sizeOf(
                                                      context,
                                                    ).width *
                                                    .60,
                                                height: 20,
                                                child: Text(
                                                  imageSelected
                                                      ? kIsWeb
                                                            ? userProvider
                                                                      .webFileName ??
                                                                  'web_image.jpg'
                                                            : userProvider
                                                                      .selectedImageFile
                                                                      ?.path
                                                                      .split(
                                                                        '/',
                                                                      )
                                                                      .last ??
                                                                  ''
                                                      : "No image selected",
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    fontSize: 16,
                                                    color: imageSelected
                                                        ? Colors.green
                                                        : Colors.black87,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 12),

                                          ElevatedButton.icon(
                                            onPressed: () =>
                                                userProvider.pickImage(context),
                                            icon: const Icon(Icons.upload_file),
                                            label: Text(
                                              imageSelected
                                                  ? "Change Image"
                                                  : "Select Image",
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 24),

                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.deepOrangeAccent,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        elevation: 4,
                                      ),
                                      onPressed: startPayment,
                                      child: const Text(
                                        'Proceed to Payment (₹705)',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // qrReminder(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Positioned(bottom: 50, left: 24, right: 24, child: qrReminder()),

              // showFooterWidget(),
              LoadingWidget(isLoading: paymentProvider.isLoading),
            ],
          );
        },
      ),
    );
  }
}
