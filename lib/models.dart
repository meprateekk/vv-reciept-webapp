class ReceiptData {
  String receiptNo;
  String date;
  String projectName;
  String projectAddress;
  String buyerName;
  String address;
  String phone;
  String panNo;
  String flatNo;
  String floor;
  String type;
  String superArea;
  String totalConsideration;
  String amountReceived;
  String amountInWords;
  String paymentTowards;
  String paymentMode;
  String balanceAmount;

  ReceiptData({
    required this.receiptNo,
    required this.date,
    required this.projectName,
    required this.projectAddress,
    required this.buyerName,
    required this.address,
    required this.phone,
    required this.panNo,
    required this.flatNo,
    required this.floor,
    required this.type,
    required this.superArea,
    required this.totalConsideration,
    required this.amountReceived,
    required this.amountInWords,
    required this.paymentTowards,
    required this.paymentMode,
    required this.balanceAmount,
  });

  // Convert Object to JSON (For Database)
  Map<String, dynamic> toMap() {
    return {
      'receiptNo': receiptNo,
      'date': date,
      'projectName': projectName,
      'projectAddress': projectAddress,
      'buyerName': buyerName,
      'address': address,
      'phone': phone,
      'panNo': panNo,
      'flatNo': flatNo,
      'floor': floor,
      'type': type,
      'superArea': superArea,
      'totalConsideration': totalConsideration,
      'amountReceived': amountReceived,
      'amountInWords': amountInWords,
      'paymentTowards': paymentTowards,
      'paymentMode': paymentMode,
      'balanceAmount': balanceAmount,
    };
  }

  // Convert JSON to Object (For PDF Generation)
  factory ReceiptData.fromMap(Map<String, dynamic> map) {
    return ReceiptData(
      receiptNo: map['receiptNo'] ?? '',
      date: map['date'] ?? '',
      projectName: map['projectName'] ?? '',
      projectAddress: map['projectAddress'] ?? '',
      buyerName: map['buyerName'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      panNo: map['panNo'] ?? '',
      flatNo: map['flatNo'] ?? '',
      floor: map['floor'] ?? '',
      type: map['type'] ?? '',
      superArea: map['superArea'] ?? '',
      totalConsideration: map['totalConsideration'] ?? '',
      amountReceived: map['amountReceived'] ?? '',
      amountInWords: map['amountInWords'] ?? '',
      paymentTowards: map['paymentTowards'] ?? '',
      paymentMode: map['paymentMode'] ?? '',
      balanceAmount: map['balanceAmount'] ?? '',
    );
  }
}