class AcquirerData {
    AcquirerData({
        required this.authCode,
        required this.arn,
        required this.rrn,
    });

    final String authCode;
    static const String authCodeKey = "auth_code";
    
    final String arn;
    static const String arnKey = "arn";
    
    final String rrn;
    static const String rrnKey = "rrn";
    

    AcquirerData copyWith({
        String? authCode,
        String? arn,
        String? rrn,
    }) {
        return AcquirerData(
            authCode: authCode ?? this.authCode,
            arn: arn ?? this.arn,
            rrn: rrn ?? this.rrn,
        );
    }

    factory AcquirerData.fromJson(Map<String, dynamic> json){ 
        return AcquirerData(
            authCode: json["auth_code"] ?? "",
            arn: json["arn"] ?? "",
            rrn: json["rrn"] ?? "",
        );
    }

    Map<String, dynamic> toJson() => {
        "auth_code": authCode,
        "arn": arn,
        "rrn": rrn,
    };

    @override
    String toString(){
        return "$authCode, $arn, $rrn, ";
    }
}
