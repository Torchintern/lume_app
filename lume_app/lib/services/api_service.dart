import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.0.2.2:5000/api";
  static const Map<String, String> headers = {
    "Content-Type": "application/json",
  };
  // ================= Universities =================
  static Future<List<dynamic>> getUniversities() async {
    final res = await http.get(Uri.parse("$baseUrl/universities"));
    if (res.statusCode != 200) {
      throw Exception("FAILED_TO_LOAD_UNIVERSITIES");
    }
    return jsonDecode(res.body);
  }

  // ================= REGISTER OTP =================
  static Future<void> sendRegisterOtp({
    required String mobile,
    required String email,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/register/send-otp"),
      headers: headers,
      body: jsonEncode({
        "mobile": mobile,
        "email": email,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("FAILED_TO_SEND_REGISTER_OTP");
    }
  }

  static Future<void> verifyRegisterOtp({
    required String mobileOtp,
    required String emailOtp,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/register/verify-otp"),
      headers: headers,
      body: jsonEncode({
        "mobile_otp": mobileOtp,
        "email_otp": emailOtp,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("INVALID_REGISTER_OTP");
    }
  }

  // ================= LOGIN =================
  static Future<void> sendLoginOtp(String value) async {
    final body =
        value.contains("@") ? {"email": value} : {"mobile": value};

    final res = await http.post(
      Uri.parse("$baseUrl/login/send-otp"),
      headers: headers,
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw Exception("FAILED_TO_SEND_LOGIN_OTP");
    }
  }

  static Future<Map<String, dynamic>> verifyLoginOtp(
      String value, String otp) async {
    final body = value.contains("@")
        ? {"email": value, "otp": otp}
        : {"mobile": value, "otp": otp};

    final res = await http.post(
      Uri.parse("$baseUrl/login/verify-otp"),
      headers: headers,
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw Exception("INVALID_LOGIN_OTP");
    }

    return jsonDecode(res.body);
  }

  // ================= REGISTRATION =================
  static Future<void> registerStudent({
    required int universityId,
    required String mobile,
    required String email,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: headers,
      body: jsonEncode({
        "university_id": universityId,
        "mobile": mobile,
        "email": email,
      }),
    );

    if (res.statusCode == 409) {
      throw Exception("ALREADY_REGISTERED");
    }
    if (res.statusCode != 201) {
      throw Exception("REGISTRATION_FAILED");
    }
  }

  // ================= STUDENT DETAILS =================
  static Future<Map<String, dynamic>> getStudentDetails(
    int registeredStudentId) async {

  final res = await http.get(
    Uri.parse("$baseUrl/student/details/$registeredStudentId"),
    headers: {
      "Content-Type": "application/json",
    },
  );

  if (res.statusCode != 200) {
    throw Exception("FAILED_TO_FETCH_DETAILS");
  }

  final data = jsonDecode(res.body);

  return {
    "full_name": data["full_name"],
    "mobile": data["mobile"],
    "email": data["email"],
    "upi_id": data["upi_id"],
    "aadhaar_verified": data["aadhaar_verified"],
    "pan_verified": data["pan_verified"],
    "wallet_status": data["wallet_status"],
    "kyc_completion_percent": data["kyc_completion_percent"] ?? 0,
  };
}

  
static Future<Map<String, dynamic>> getUserProfile(int regId) async {
  final res = await http.get(
    Uri.parse("$baseUrl/user/profile/$regId"),
  );

  if (res.statusCode == 200) {
    return json.decode(res.body);
  } else {
    throw Exception("Failed to load user profile");
  }
}

  // ================= AADHAAR KYC =================
  static Future<bool> verifyAadhaarKyc({
  required int registeredStudentId,
  required String mobile,
  required String otp,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/kyc/aadhaar'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'registered_student_id': registeredStudentId,
      'mobile': mobile,
      'otp': otp,
    }),
  );

  return response.statusCode == 200;
}

// ============== Aadhaar OTP send ============
static Future<String> sendAadhaarOtp({
  required int registeredStudentId,
  required String mobile,
}) async {
  final res = await http.post(
    Uri.parse("$baseUrl/kyc/aadhaar"),
    headers: headers,
    body: jsonEncode({
      "registered_student_id": registeredStudentId,
      "mobile": mobile,
    }),
  );

  final data = jsonDecode(res.body);
  return data["message"];
}

  // ================= PAN KYC (OPTIONAL) =================
  static Future<bool> verifyPanKyc({
  required int registeredStudentId,
  required String mobile,
  required String panNumber,
  required String otp,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/kyc/pan'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'registered_student_id': registeredStudentId,
      'mobile': mobile,
      'otp': otp,
      'pan_number': panNumber,
    }),
  );
  if (response.statusCode == 200) {
    return true;
  }
  return false;
}

// ================== PAN OTP Send =================
static Future<String> sendPanOtp({
  required int registeredStudentId,
  required String mobile,
}) async {
  final res = await http.post(
    Uri.parse("$baseUrl/kyc/pan"),
    headers: headers,
    body: jsonEncode({
      "registered_student_id": registeredStudentId,
      "mobile": mobile,
    }),
  );

  final data = jsonDecode(res.body);
  return data["message"];
}

  // ================= UPDATE / CREATE UPI =================
  static Future<String> updateUpiId({
  required int registeredStudentId,
  required String upiId,
}) async {
  final res = await http.post(
    Uri.parse("$baseUrl/upi/update"),
    headers: headers,
    body: jsonEncode({
      "registered_student_id": registeredStudentId,
      "upi_id": upiId,
    }),
  );

  final data = jsonDecode(res.body);
  return data["message"];
}
// update
static Future<void> updateUpi({
  required int registeredStudentId,
  required String upiId,
}) async {
  final response = await http.post(
    Uri.parse("$baseUrl/upi/update"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "registered_student_id": registeredStudentId,
      "upi_id": upiId,
    }),
  );

  if (response.statusCode == 200) {
    return;
  }

  if (response.statusCode == 409) {
    throw Exception("UPI already exists");
  }

  throw Exception("Failed to update UPI");
}


  // ================= WALLET =================
 static Future<double> getWalletBalance(int regId) async {
  try {
    final res = await http.get(Uri.parse('$baseUrl/wallet/balance/$regId'),);
    if (res.statusCode != 200) {
      return 0.0;
    }
    final data = jsonDecode(res.body);
    return (data["balance"] ?? 0).toDouble();
  } catch (_) {
    return 0.0;
  }
}

// ============== Pay - Search Lume User ===================
static Future<List<dynamic>> searchLumeUserByMobile(String query) async {
  final res = await http.get(
    Uri.parse("$baseUrl/pay/search/mobile?q=$query"),
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  }
  return [];
}

// ========================= Wallet - wallet transfer ============================
static Future<bool> walletToWalletTransfer({
  required int senderRegId,
  required String receiverMobile,
  required double amount,
}) async {
  final res = await http.post(
    Uri.parse("$baseUrl/wallet/transfer"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "sender_reg_id": senderRegId,
      "receiver_mobile": receiverMobile,
      "amount": amount,
    }),
  );

  return res.statusCode == 200;
}
// ===================== wallet to UPI ================
static Future<bool> payViaUpi(
  int senderRegId,
  String upiId,
  double amount,
) async {
  final res = await http.post(
    Uri.parse("$baseUrl/pay/upi"),
    headers: headers,
    body: jsonEncode({
      "sender_reg_id": senderRegId,
      "upi_id": upiId,
      "amount": amount,
    }),
  );

  return res.statusCode == 200;
}
// ================= SEARCH LUME USER BY INTERNAL UPI =================
static Future<List<dynamic>> searchLumeUserByUpi(String query) async {
  final res = await http.get(
    Uri.parse("$baseUrl/pay/search/upi?q=$query"),
    headers: headers,
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    return [];
  }
}

// ================= Transaction History ====================
static Future<List<dynamic>> getTransactionHistory(int regId) async {
  final res = await http.get(
    Uri.parse("$baseUrl/transactions/$regId"),
  );
  if (res.statusCode != 200) {
    throw Exception("FAILED_TO_FETCH_TRANSACTIONS");
  }
  return jsonDecode(res.body);
}

 // =============== Add Money to Wallet =============
 static Future<bool> addMoneyToWallet({
  required int regId,
  required double amount,
}) async {
  final res = await http.post(
    Uri.parse("$baseUrl/wallet/add-money"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "registered_student_id": regId,
      "amount": amount,
    }),
  );

  return res.statusCode == 200;
}

// =============== Credit Wallet ====================
static Future<void> creditWallet({
  required String upiId,
  required double amount,
  required String fromUpi,
}) async {
  await http.post(
    Uri.parse("$baseUrl/wallet/credit"),
    headers: headers,
    body: jsonEncode({
      "upi_id": upiId,
      "amount": amount,
      "from_upi": fromUpi,
    }),
  );
}
 // ========== Notifications ====================
 static Future<List<dynamic>> getUnreadNotifications(int regId) async {
  final res = await http.get(
    Uri.parse("$baseUrl/transactions/unread/$regId"),
    headers: headers,
  );

  return jsonDecode(res.body);
}

static Future<void> markNotificationSeen(int txnId) async {
  await http.post(
    Uri.parse("$baseUrl/transactions/mark-seen"),
    headers: headers,
    body: jsonEncode({"transaction_id": txnId}),
  );
}

 static Future<int> getUnreadNotificationCount(int regId) async {
  final res = await http.get(
    Uri.parse("$baseUrl/notifications/unread-count/$regId"),
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body)["unread"];
  } else {
    return 0;
  }
}


static Future<void> markAllNotificationsRead(int regId) async {
  await http.post(
    Uri.parse("$baseUrl/notifications/mark-all-read"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"reg_id": regId}),
  );
}

// ================= PIN SET =================
static Future<bool> setPin({
  required int regId,
  required String type,
  required String pin,
}) async {
  final res = await http.post(
    Uri.parse("$baseUrl/pin/set"),
    headers: headers,
    body: jsonEncode({
      "reg_id": regId,
      "type": type,
      "pin": pin,
    }),
  );

  return res.statusCode == 200;
}

// ================= PIN VERIFY =================
static Future<Map<String, dynamic>> verifyPin({
  required int regId,
  required String type, // wallet | card
  required String pin,
}) async {
  final res = await http.post(
    Uri.parse("$baseUrl/pin/verify"),
    headers: headers,
    body: jsonEncode({
      "reg_id": regId,
      "type": type,
      "pin": pin,
    }),
  );

  final data = jsonDecode(res.body);

  return {
    "statusCode": res.statusCode,
    "message": data["message"],
    "attemptsLeft": data["attempts_left"],
    "locked": data["locked"] ?? false,
    "action": data["action"],
  };
}
// ================= PIN OTP VERIFY =================
static Future<void> verifyPinOtp({
  required int regId,
  required String otp,
}) async {
  final res = await http.post(
    Uri.parse("$baseUrl/login/verify-otp"),
    headers: headers,
    body: jsonEncode({
      "otp": otp,
      "reg_id": regId,
    }),
  );

  if (res.statusCode != 200) {
    throw Exception("INVALID_OTP");
  }
}

// ========== Get Pin Status ============
static Future<Map<String, bool>> getPinStatus(int regId) async {
  final res = await http.get(
    Uri.parse("$baseUrl/pin/status/$regId"),
  );

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    return {
      "wallet": data["wallet_pin_set"] == true,
      "card": data["card_pin_set"] == true,
    };
  }

  return {
    "wallet": false,
    "card": false,
  };
}

// ====== wallet to UPI =============
static Future<void> walletToUpiPayment({
  required int senderRegId,
  required String upiId,
  required double amount,
}) async {
  final res = await http.post(
    Uri.parse("$baseUrl/pay/upi"),
    headers: headers,
    body: jsonEncode({
      "sender_reg_id": senderRegId,
      "upi_id": upiId,
      "amount": amount,
    }),
  );

  if (res.statusCode != 200) {
    throw Exception(jsonDecode(res.body)["message"]);
  }
}
// ============== init add money transaction ============
static Future<int?> initAddMoneyTransaction({
  required int regId,
  required double amount,
  required String paymentMethod,
  int? savedCardId,
}) async {
  final res = await http.post(
    Uri.parse("$baseUrl/wallet/add-money/init"),
    headers: headers,
    body: jsonEncode({
      "reg_id": regId,
      "amount": amount,
      "method": paymentMethod,
      "saved_card_id": savedCardId,
    }),
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body)["txn_id"];
  }
  return null;
}
// ======== verify add money OTp =============
static Future<String> verifyAddMoneyOtp({
  required int txnId,
  required String otp,
  required bool saveCard,
  Map<String, String>? cardData,
}) async {
  final res = await http.post(
    Uri.parse("$baseUrl/wallet/add-money/verify"),
    headers: headers,
    body: jsonEncode({
      "txn_id": txnId,
      "otp": otp,
      "save_card": saveCard,
      "card_data": cardData,
    }),
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body)["status"];
  }
  return "failed";
}
//  =======    get saved cards ============
static Future<List<dynamic>> getSavedCards(int regId) async {
  final res = await http.get(
    Uri.parse("$baseUrl/cards/saved/$regId"),
    headers: headers,
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  }
  return [];
}

// ========== save card ============
static Future<bool> saveCard({
  required int regId,
  required String cardNumber,
  required String name,
  required String expiry,
  required String brand,
  required String cardType,
}) async {
  final response = await http.post(
    Uri.parse("$baseUrl/cards/save"),
    headers: headers,
    body: jsonEncode({
      "reg_id": regId,
      "card_number": cardNumber,
      "name": name,
      "expiry": expiry,
      "brand": brand,         
      "card_type": cardType,  
    }),
  );

  return response.statusCode == 200;
}

// ===== delete saved cards ============
static Future<void> deleteSavedCard(int cardId) async {
  await http.delete(
    Uri.parse("$baseUrl/cards/$cardId"),
    headers: headers,
  );
}
// ======= 2nd call to add money ============
static Future<int> initAddMoney({
  required int regId,
  required double amount,
  int? savedCardId,
}) async {
  final res = await http.post(
    Uri.parse("$baseUrl/wallet/add-money/init"),
    headers: headers,
    body: jsonEncode({
      "reg_id": regId,
      "amount": amount,
      "saved_card_id": savedCardId,
    }),
  );

  if (res.statusCode != 200) {
    throw Exception("FAILED_TO_INIT_PAYMENT");
  }

  return jsonDecode(res.body)["txn_id"];
}
//  ====== 2nd call for verify and add money ========
static Future<String> verifyAddMoney({
  required int txnId,
  required String otp,
  required bool saveCard,
  required Map<String, dynamic> cardData,
}) async {
  final res = await http.post(
    Uri.parse("$baseUrl/wallet/add-money/verify"), 
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "txn_id": txnId,
      "otp": otp,
      "save_card": saveCard,
      "card_data": cardData,
    }),
  );

  if (res.statusCode != 200) {
    return "failed";
  }

  final data = jsonDecode(res.body);

  return data["status"] ?? "failed"; // "success" | "failed"
}
// ====== Cancel add money =======
static Future<void> cancelAddMoney(int txnId) async {
  await http.post(
    Uri.parse("$baseUrl/wallet/add-money/cancel"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"txn_id": txnId}),
  );
}

}
