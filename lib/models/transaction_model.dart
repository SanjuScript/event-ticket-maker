
import 'package:event_ticket_maker/models/aquire_data_model.dart';

class TransactionModel {
    TransactionModel({
        required this.id,
        required this.entity,
        required this.amount,
        required this.currency,
        required this.status,
        required this.orderId,
        required this.invoiceId,
        required this.international,
        required this.method,
        required this.amountRefunded,
        required this.refundStatus,
        required this.captured,
        required this.description,
        required this.cardId,
        required this.bank,
        required this.wallet,
        required this.vpa,
        required this.email,
        required this.contact,
        required this.customerId,
        required this.tokenId,
        required this.notes,
        required this.fee,
        required this.tax,
        required this.errorCode,
        required this.errorDescription,
        required this.errorSource,
        required this.errorStep,
        required this.errorReason,
        required this.acquirerData,
        required this.createdAt,
    });

    final String id;
    static const String idKey = "id";
    
    final String entity;
    static const String entityKey = "entity";
    
    final num amount;
    static const String amountKey = "amount";
    
    final String currency;
    static const String currencyKey = "currency";
    
    final String status;
    static const String statusKey = "status";
    
    final String orderId;
    static const String orderIdKey = "order_id";
    
    final dynamic invoiceId;
    static const String invoiceIdKey = "invoice_id";
    
    final bool international;
    static const String internationalKey = "international";
    
    final String method;
    static const String methodKey = "method";
    
    final num amountRefunded;
    static const String amountRefundedKey = "amount_refunded";
    
    final dynamic refundStatus;
    static const String refundStatusKey = "refund_status";
    
    final bool captured;
    static const String capturedKey = "captured";
    
    final String description;
    static const String descriptionKey = "description";
    
    final String cardId;
    static const String cardIdKey = "card_id";
    
    final dynamic bank;
    static const String bankKey = "bank";
    
    final dynamic wallet;
    static const String walletKey = "wallet";
    
    final dynamic vpa;
    static const String vpaKey = "vpa";
    
    final String email;
    static const String emailKey = "email";
    
    final String contact;
    static const String contactKey = "contact";
    
    final String customerId;
    static const String customerIdKey = "customer_id";
    
    final String tokenId;
    static const String tokenIdKey = "token_id";
    
    final List<dynamic> notes;
    static const String notesKey = "notes";
    
    final num fee;
    static const String feeKey = "fee";
    
    final num tax;
    static const String taxKey = "tax";
    
    final dynamic errorCode;
    static const String errorCodeKey = "error_code";
    
    final dynamic errorDescription;
    static const String errorDescriptionKey = "error_description";
    
    final dynamic errorSource;
    static const String errorSourceKey = "error_source";
    
    final dynamic errorStep;
    static const String errorStepKey = "error_step";
    
    final dynamic errorReason;
    static const String errorReasonKey = "error_reason";
    
    final AcquirerData? acquirerData;
    static const String acquirerDataKey = "acquirer_data";
    
    final num createdAt;
    static const String createdAtKey = "created_at";
    

    TransactionModel copyWith({
        String? id,
        String? entity,
        num? amount,
        String? currency,
        String? status,
        String? orderId,
        dynamic invoiceId,
        bool? international,
        String? method,
        num? amountRefunded,
        dynamic refundStatus,
        bool? captured,
        String? description,
        String? cardId,
        dynamic bank,
        dynamic wallet,
        dynamic vpa,
        String? email,
        String? contact,
        String? customerId,
        String? tokenId,
        List<dynamic>? notes,
        num? fee,
        num? tax,
        dynamic errorCode,
        dynamic errorDescription,
        dynamic errorSource,
        dynamic errorStep,
        dynamic errorReason,
        AcquirerData? acquirerData,
        num? createdAt,
    }) {
        return TransactionModel(
            id: id ?? this.id,
            entity: entity ?? this.entity,
            amount: amount ?? this.amount,
            currency: currency ?? this.currency,
            status: status ?? this.status,
            orderId: orderId ?? this.orderId,
            invoiceId: invoiceId ?? this.invoiceId,
            international: international ?? this.international,
            method: method ?? this.method,
            amountRefunded: amountRefunded ?? this.amountRefunded,
            refundStatus: refundStatus ?? this.refundStatus,
            captured: captured ?? this.captured,
            description: description ?? this.description,
            cardId: cardId ?? this.cardId,
            bank: bank ?? this.bank,
            wallet: wallet ?? this.wallet,
            vpa: vpa ?? this.vpa,
            email: email ?? this.email,
            contact: contact ?? this.contact,
            customerId: customerId ?? this.customerId,
            tokenId: tokenId ?? this.tokenId,
            notes: notes ?? this.notes,
            fee: fee ?? this.fee,
            tax: tax ?? this.tax,
            errorCode: errorCode ?? this.errorCode,
            errorDescription: errorDescription ?? this.errorDescription,
            errorSource: errorSource ?? this.errorSource,
            errorStep: errorStep ?? this.errorStep,
            errorReason: errorReason ?? this.errorReason,
            acquirerData: acquirerData ?? this.acquirerData,
            createdAt: createdAt ?? this.createdAt,
        );
    }

    factory TransactionModel.fromJson(Map<String, dynamic> json){ 
        return TransactionModel(
            id: json["id"] ?? "",
            entity: json["entity"] ?? "",
            amount: json["amount"] ?? 0,
            currency: json["currency"] ?? "",
            status: json["status"] ?? "",
            orderId: json["order_id"] ?? "",
            invoiceId: json["invoice_id"],
            international: json["international"] ?? false,
            method: json["method"] ?? "",
            amountRefunded: json["amount_refunded"] ?? 0,
            refundStatus: json["refund_status"],
            captured: json["captured"] ?? false,
            description: json["description"] ?? "",
            cardId: json["card_id"] ?? "",
            bank: json["bank"],
            wallet: json["wallet"],
            vpa: json["vpa"],
            email: json["email"] ?? "",
            contact: json["contact"] ?? "",
            customerId: json["customer_id"] ?? "",
            tokenId: json["token_id"] ?? "",
            notes: json["notes"] == null ? [] : List<dynamic>.from(json["notes"]!.map((x) => x)),
            fee: json["fee"] ?? 0,
            tax: json["tax"] ?? 0,
            errorCode: json["error_code"],
            errorDescription: json["error_description"],
            errorSource: json["error_source"],
            errorStep: json["error_step"],
            errorReason: json["error_reason"],
            acquirerData: json["acquirer_data"] == null ? null : AcquirerData.fromJson(json["acquirer_data"]),
            createdAt: json["created_at"] ?? 0,
        );
    }

    Map<String, dynamic> toJson() => {
        "id": id,
        "entity": entity,
        "amount": amount,
        "currency": currency,
        "status": status,
        "order_id": orderId,
        "invoice_id": invoiceId,
        "international": international,
        "method": method,
        "amount_refunded": amountRefunded,
        "refund_status": refundStatus,
        "captured": captured,
        "description": description,
        "card_id": cardId,
        "bank": bank,
        "wallet": wallet,
        "vpa": vpa,
        "email": email,
        "contact": contact,
        "customer_id": customerId,
        "token_id": tokenId,
        "notes": notes.map((x) => x).toList(),
        "fee": fee,
        "tax": tax,
        "error_code": errorCode,
        "error_description": errorDescription,
        "error_source": errorSource,
        "error_step": errorStep,
        "error_reason": errorReason,
        "acquirer_data": acquirerData?.toJson(),
        "created_at": createdAt,
    };

    @override
    String toString(){
        return "$id, $entity, $amount, $currency, $status, $orderId, $invoiceId, $international, $method, $amountRefunded, $refundStatus, $captured, $description, $cardId, $bank, $wallet, $vpa, $email, $contact, $customerId, $tokenId, $notes, $fee, $tax, $errorCode, $errorDescription, $errorSource, $errorStep, $errorReason, $acquirerData, $createdAt, ";
    }
}

