import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';
import 'package:event_ticket_maker/helper/string_helper.dart';
import 'package:event_ticket_maker/models/payment_model.dart';
import 'package:event_ticket_maker/provider/device_info_provider.dart';
import 'package:event_ticket_maker/provider/select_image.dart';
import 'package:event_ticket_maker/provider/verification_state.dart';
import 'package:event_ticket_maker/screens/success_screen.dart';
import 'package:event_ticket_maker/services/storage_services.dart';
import 'package:event_ticket_maker/widgets/developer_info.dart';
import 'package:event_ticket_maker/widgets/glass_fields.dart';
import 'package:event_ticket_maker/widgets/loading_widget.dart';
import 'package:event_ticket_maker/widgets/payment_button.dart';
import 'package:event_ticket_maker/widgets/premium_image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_razorpay_web/flutter_razorpay_web.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:js' as js;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  
  RazorpayWeb razorpayWeb = RazorpayWeb();

  void _handlePaymentSuccess(RpaySuccessResponse response) {
    log(response.toJson().toString());
    final Map<String, dynamic> resp = response.toMap();
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final paymentResponse = RazorpayPaymentModel.fromJson(resp);
    verifyAndSaveTicket(response: paymentResponse, name: name, phone: phone);
  }

  void _handlePaymentError(RpayFailedResponse response) {
    log(response.toJson().toString());
    StringHelper.showError("Payment failed: $response", context);
  }

  void _handleOnCancel(RpayCancelResponse response) {
    log(response.toJson().toString());
  }

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
      makePayment(
        orderId: orderId,
        keyId: "rzp_test_lfbXLnyT9SLgph",
        amount: 705 * 100,
        name: name,
        phone: phone,
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
    required RazorpayPaymentModel response,
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
    final deviceProvider = Provider.of<DeviceInfoProvider>(
      context,
      listen: false,
    );

    paymentProvider.setLoading(true);
    final payload = {
      'payment_info': response.toJson(),
      'name': name,
      'phone': phone,
      'device_info': {
        'device_model': deviceProvider.deviceModel,
        'os': deviceProvider.os,
        'user_agent': deviceProvider.userAgent,
        'language': deviceProvider.language,
      },
      'ip_address': deviceProvider.ipAddress,
    };
    log(name: "PAYLOAD", payload.toString());
    try {
      final backendResponse = await http.post(
        Uri.parse(
          'https://us-central1-event-ticket-maker-8e724.cloudfunctions.net/api/verify-payment',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final result = jsonDecode(backendResponse.body);

      if (result['status'] == 'success') {
        paymentProvider.setPayment(true);
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
            MaterialPageRoute(
              builder: (_) => SuccessScreen(ticketId: ticketId),
            ),
          );
        }
      } else {
        log("Payment verification failed");
        log("Backend response: ${backendResponse.body}");

        paymentProvider.setLoading(false);
      }
    } catch (e) {
      log("Error in verifying payment: $e");
      paymentProvider.setLoading(false);
    }
  }

  void makePayment({
    required String orderId,
    required String keyId,
    required int amount,
    required String name,
    required String phone,
  }) {
    final Map<String, dynamic> options = {
      "key": keyId,
      "amount": "$amount",
      "currency": "INR",
      "name": "Onam Celebration",
      "description": "Ticket Payment",
      "order_id": orderId,
      "send_sms_hash": true,
      'readonly': {'contact': true, 'email': true},
      'method': {
        'upi': true,
        'card': false,
        'netbanking': false,
        'wallet': false,
        'emi': false,
        'paylater': false,
      },
      "prefill": {"name": name, "contact": phone},
      "theme": {"color": "#F37254"},
    };
    razorpayWeb.open(options);
  }

  final _textStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    fontFamily: "newbo",
    fontStyle: FontStyle.italic,
  );
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  void initializeRazorpay() {
    razorpayWeb = RazorpayWeb(
      onSuccess: _handlePaymentSuccess,
      onCancel: _handleOnCancel,
      onFailed: _handlePaymentError,
    );
  }

  @override
  void initState() {
    super.initState();
    initializeRazorpay();
  }

  @override
  void dispose() {
    razorpayWeb.clear();
    super.dispose();
  }

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
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF2c6cbc),
                      Color(0xFF71c3f7),
                      Color(0xFFf6f6f6),
                    ],
                  ),
                ),
                child: LayoutBuilder(
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
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Card(
                                shadowColor: Colors.transparent,
                                surfaceTintColor: Colors.transparent,
                                elevation: 12,
                                borderOnForeground: true,
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    color: Colors.white54,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                color: Colors.white12,
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Onam Celebration 2025',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Join us for a day of culture, tradition, and joy!',
                                        style: _textStyle,
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.calendar_today_rounded,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Thursday, 28 August 2025',
                                            style: _textStyle,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.location_on_rounded,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Krupanidhi College, Bengaluru',
                                            style: _textStyle,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.confirmation_num_rounded,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '₹705 per person',
                                            style: _textStyle,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      const Text(
                                        'Book Your Ticket',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          fontFamily: "newbo",
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
                                              : userProvider
                                                        .selectedImageFile !=
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
                                              PremiumImagePicker(
                                                imageSelected: imageSelected,
                                                userProvider: userProvider,
                                              ),
                                            ],
                                          );
                                        },
                                      ),

                                      const SizedBox(height: 24),

                                      PaymentButton(onPressed: startPayment),
                                      DeveloperInfo(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (paymentProvider.isLoading)
                Positioned.fill(
                  child: LoadingWidget(
                    isLoading: true,
                    isPaymentDone: paymentProvider.isPaymentDone,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
