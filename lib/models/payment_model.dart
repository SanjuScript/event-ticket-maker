class RazorpayPaymentModel {
  final String? status;
  final String? desc;
  final String? paymentId;
  final String? orderId;
  final String? signature;

  RazorpayPaymentModel({
    this.status,
    this.desc,
    this.paymentId,
    this.orderId,
    this.signature,
  });

  factory RazorpayPaymentModel.fromJson(Map<String, dynamic> json) {
    return RazorpayPaymentModel(
      status: json['status'] as String?,
      desc: json['desc'] as String?,
      paymentId: json['paymentId'] as String?,
      orderId: json['orderId'] as String?,
      signature: json['signature'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'desc': desc,
      'paymentId': paymentId,
      'orderId': orderId,
      'signature': signature,
    };
  }
}
