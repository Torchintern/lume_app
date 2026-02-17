import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://192.168.0.3:5000/api";
  // "http://10.0.2.2:5000/api"
  static const Map<String, String> headers = {
    "Content-Type": "application/json",
  };
  // ================= CURRENT USER CACHE =================
static int? currentUserRegId;
static String? currentUserMobile;
static String? currentUserName;
static String? currentUserProfileImage;

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

    final data = jsonDecode(res.body);
    currentUserRegId = data["reg_id"];
    currentUserMobile = data["mobile"];
    currentUserName = data["full_name"];

    try {
  final profile = await getUserProfile(data["reg_id"]);
  currentUserProfileImage = profile["profile_image"];
} catch (_) {
  currentUserProfileImage = null;
}

return data;


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
    "college": data["college"] ?? "",
    "upi_id": data["upi_id"],
    "profile_image": data["profile_image"],
    "aadhaar_verified": data["aadhaar_verified"],
    "aadhaar_last4": data["aadhaar_last4"],
    "pan_verified": data["pan_verified"],
    "pan_masked": data["pan_masked"],
    "wallet_status": data["wallet_status"],
    "kyc_completion_percent": data["kyc_completion_percent"] ?? 0,
    "reward_points": data["reward_points"] ?? 0,
    "tier": data["tier"] ?? "silver",
    "tier_cycle_start": data["tier_cycle_start"],
    "total_spent": data["total_spent"] ?? 0,
    "server_time": data["server_time"] ?? "",
    "weather_temp": data["weather_temp"] ?? 0,
    "weather_condition": data["weather_condition"] ?? "",

  };
}

// ====== Get User Profile ==========
static Future<Map<String, dynamic>> getUserProfile(int regId) async {
  final res = await http.get(
    Uri.parse("$baseUrl/student/details/$regId"),
  );

  if (res.statusCode == 200) {
    return json.decode(res.body);
  } else {
    throw Exception("Failed to load user profile");
  }
}

// ===== Upload profile Image =========
static Future<void> uploadProfileImage({
  required int regId,
  required File imageFile,
}) async {
  final uri = Uri.parse("$baseUrl/profile/upload");

  final request = http.MultipartRequest("POST", uri)
    ..fields["reg_id"] = regId.toString()
    ..files.add(
      await http.MultipartFile.fromPath(
        "image",
        imageFile.path,
      ),
    );

  final response = await request.send();

  if (response.statusCode != 200) {
    throw Exception("Profile image upload failed");
  }
}



  // ================= AADHAAR KYC =================
  static Future<bool> verifyAadhaarKyc({
  required int registeredStudentId,
  required String aadhaarNumber,
  required String otp,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/kyc/aadhaar'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'registered_student_id': registeredStudentId,
      'aadhaar_number': aadhaarNumber,
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

// ============= get recent payees ==========
static Future<List<dynamic>> getRecentPayees(int regId) async {
  final res = await http.get(
    Uri.parse("$baseUrl/payments/recent/$regId"),
  );

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    return data is List ? data : [];
  }
  return [];
}


// ========================= Wallet - wallet transfer ============================
static Future<Map<String, dynamic>?> walletToWalletTransfer({
  required int senderRegId,
  required String receiverMobile,
  required double amount,
}) async {

  final res = await http.post(
    Uri.parse("$baseUrl/wallet/transfer"),
    headers: headers,
    body: jsonEncode({
      "sender_reg_id": senderRegId,
      "receiver_mobile": receiverMobile,
      "amount": amount,
    }),
  );

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    await refreshRewardsAfterSpend(senderRegId);
    await getUnreadNotificationCount(senderRegId);

    return data;
  }

  return null;
}


// ===================== wallet to UPI ================
static Future<Map<String, dynamic>?> payViaUpi(
  int senderRegId,
  String upiId,
  double amount,
  String name,
) async {

  final res = await http.post(
    Uri.parse("$baseUrl/pay/upi"),
    headers: headers,
    body: jsonEncode({
      "sender_reg_id": senderRegId,
      "upi_id": upiId,
      "amount": amount,
      "name": name,
    }),
  );

    if (res.statusCode == 200) {
    final data = jsonDecode(res.body);

    await refreshRewardsAfterSpend(senderRegId);
    await getUnreadNotificationCount(senderRegId);

    return data;
  }


  return null;
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
 static Future<List<dynamic>> getAllNotifications(int regId) async {
  final res = await http.get(
    Uri.parse("$baseUrl/notifications/$regId"),
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  }

  return [];
}

 static Future<List<dynamic>> getUnreadNotifications(int regId) async {
  final res = await http.get(
    Uri.parse("$baseUrl/notifications/unread/$regId"),
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  }

  return [];
}


static Future<void> markAllNotificationsRead(int regId) async {
  await http.post(
    Uri.parse("$baseUrl/notifications/mark-read/$regId"),
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

static Future markNotificationRead(int notifId) async {
  await http.post(
    Uri.parse("$baseUrl/notifications/read/$notifId"),
  );
}

static Future<bool> deleteNotification(int id) async {
  try {
    final res = await http.delete(
      Uri.parse("$baseUrl/notifications/delete/$id"),
    );

    return res.statusCode == 200;

  } catch (e) {
    print("DELETE NOTIFICATION ERROR: $e");
    return false;
  }
}

static Future<void> deleteAllNotifications(int regId) async {
  final list = await getAllNotifications(regId);

  for (var n in list) {
    await deleteNotification(n["id"]);
  }
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
// ================= PIN RESET – SEND OTP =================
static Future<void> sendPinResetOtp({
  required int regId,
}) async {
  final res = await http.post(
    Uri.parse("$baseUrl/pin/send-otp"),
    headers: headers,
    body: jsonEncode({
      "reg_id": regId,
    }),
  );

  if (res.statusCode != 200) {
    throw Exception("FAILED_TO_SEND_PIN_OTP");
  }
}
// ================= PIN RESET – VERIFY OTP =================
static Future<void> verifyPinResetOtp({
  required String otp,
}) async {
  final res = await http.post(
    Uri.parse("$baseUrl/pin/verify-otp"),
    headers: headers,
    body: jsonEncode({
      "otp": otp,
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
      "wallet": data["wallet"],
      "card": data["card"],
      "wallet_locked": data["wallet_locked"],
      "card_locked": data["card_locked"],
    };

  }

  return {
    "wallet": false,
    "card": false,
  };
}





// ====== wallet to UPI =============
//static Future<void> walletToUpiPayment({
  //required int senderRegId,
  //required String upiId,
  //required double amount,
///}) async {
  //final res = await http.post(
   // Uri.parse("$baseUrl/pay/upi"),
  //  headers: headers,
   // body: jsonEncode({
   //   "sender_reg_id": senderRegId,
   //   "upi_id": upiId,
   //   "amount": amount,
   // }),
 // );

 //if (res.statusCode != 200) {
   // throw Exception(jsonDecode(res.body)["message"]);
 // }
//}

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
// ======= 2nd call to add money ============a
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
  required int regId,
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

  if (data["status"] == "success") {
    await Future.wait([
      getWalletBalance(regId),
      getTransactionHistory(regId),
      getCardTransactions(regId),
      getUnreadNotificationCount(regId),
    ]);

  }

  return data["status"] ?? "failed";
}

// ====== Cancel add money =======
static Future<void> cancelAddMoney(int txnId) async {
  await http.post(
    Uri.parse("$baseUrl/wallet/add-money/cancel"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"txn_id": txnId}),
  );
}
// ======= Scholar Data =======
static Future<bool> submitScholarApplication(
      Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse("$baseUrl/scholar/application"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );
    return response.statusCode == 201;
  }

static Future<Map<String, dynamic>> getScholarApplicationStatus(int regId) async {
  final res = await http.get(
    Uri.parse("$baseUrl/scholar/application/status/$regId"),
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  }

  return {
    "hasApplication": false,
    "status": null,
  };
}
// ======= Points History ========
static Future<List<dynamic>> getPointsHistory(int regId) async {
  final res = await http.get(
    Uri.parse("$baseUrl/rewards/points-history/$regId"),
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  }

  return [];
}
// ====== Reward Cycle ==========
static Future<Map<String, dynamic>> getRewardCycle() async {
  final res = await http.get(
    Uri.parse("$baseUrl/rewards/cycle"),
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  }

  return {};
}

// ================= SPLIT CREATE =================
static Future<Map<String, dynamic>> createSplit({
  required int creatorRegId,
  required List<int> memberRegIds,
  required double totalAmount,
  required String splitType,
  String? note,
  List<double>? individualAmounts,

}) async {
  final Map<String, dynamic> body = {
    "creator_reg_id": creatorRegId,
    "members": memberRegIds,
    "total_amount": totalAmount,
    "split_type": splitType,

  };
  if (note != null && note.isNotEmpty) {
    body["note"] = note;
  }
  if (individualAmounts != null && individualAmounts.isNotEmpty) {
    body["individual_amounts"] = individualAmounts;
  }
  final res = await http.post(
    Uri.parse("$baseUrl/split/create"),
    headers: headers,
    body: jsonEncode(body),
  );
  if (res.statusCode != 200) {
  print("CREATE SPLIT FAILED");
  print("STATUS: ${res.statusCode}");
  print("BODY: ${res.body}"); 
  throw Exception("FAILED_TO_CREATE_SPLIT");
}

  return jsonDecode(res.body);
}

// ================= GET MY SPLITS =================
static Future<List<dynamic>> getMySplits(int regId) async {
  final res = await http.get(
    Uri.parse("$baseUrl/split/my/$regId"),
    headers: headers,
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  }

  return [];
}
// ================= PAY SPLIT =================
static Future<Map<String, dynamic>?> paySplit({
  required int splitMemberId,
  required int payerRegId,
}) async {

  final res = await http.post(
    Uri.parse("$baseUrl/split/pay"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "split_member_id": splitMemberId,
      "payer_reg_id": payerRegId,
    }),
  );

    if (res.statusCode == 200) {
    final data = jsonDecode(res.body);

    await refreshRewardsAfterSpend(payerRegId);
    await getUnreadNotificationCount(payerRegId);


    return data;
  }


  return null;
}


static Future<bool> closeSplit({
  required int splitId,
  required int creatorRegId,
}) async {

  final res = await http.post(
    Uri.parse("$baseUrl/split/close"),
    headers: headers,
    body: jsonEncode({
      "split_id": splitId,
      "creator_reg_id": creatorRegId,
    }),
  );

  return res.statusCode == 200;
}



// split api req
static Future<List<dynamic>> getSplitRequests(int regId) async {

  final res = await http.get(
    Uri.parse("$baseUrl/split/requests/$regId"),
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  }

  return [];
}
// Get Split Members status
static Future<Map<String, dynamic>> getSplitMemberStatus(int regId) async {
  final res = await http.get(
    Uri.parse("$baseUrl/split/member-status/$regId"),
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  }

  return {};
}

// Get Created Splits
static Future<List<dynamic>> getCreatedSplits(
  int regId,
  String splitType,
) async {

  final res = await http.get(
    Uri.parse("$baseUrl/split/created/$regId?type=$splitType"),
  );

  return jsonDecode(res.body);
}

// ================= REVEAL REWARD =================
static Future<Map<String, dynamic>?> revealReward({
  required String token,
  required int regId,
}) async {

  final res = await http.post(
    Uri.parse("$baseUrl/rewards/reveal"),
    headers: headers,
    body: jsonEncode({
      "token": token,
      "reg_id": regId,
    }),
  );

    if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    await Future.wait([
    getCashWon(regId),
    getPendingDragRewards(regId),
    getUnreadNotificationCount(regId),
  ]);


    return data;
  }


  return null;
}



// ================= CASH WON =================
static Future<List<dynamic>> getCashWon(int regId) async {
  try {
    final res = await http.get(
      Uri.parse("$baseUrl/rewards/cashwon/$regId"),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data["cashwon"] ?? [];
    }

    return [];
  } catch (e) {
    print("getCashWon error: $e");
    return [];
  }
}



// ================= COUPONS =================
static Future<List<dynamic>> getCoupons(int regId) async {
  try {
    final res = await http.get(
      Uri.parse("$baseUrl/rewards/coupons/$regId"),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data["coupons"] ?? [];
    }

    return [];
  } catch (e) {
    print("getCoupons error: $e");
    return [];
  }
}

//  ============== Vouchers ======================
static Future<List<dynamic>> getVouchers(int regId) async {
  try {
    final res = await http.get(
      Uri.parse("$baseUrl/rewards/vouchers/$regId"),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data["vouchers"] ?? [];
    }

    return [];
  } catch (e) {
    print("getVouchers error: $e");
    return [];
  }
}

 // ================= PENDING DRAG REWARDS =================
static Future<List<dynamic>> getPendingDragRewards(int regId) async {
  try {
    final res = await http.get(
      Uri.parse("$baseUrl/rewards/pending-drag/$regId"),
      headers: headers,
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      if (data is Map && data["rewards"] != null) {
        return data["rewards"];
      }

      if (data is List) {
        return data;
      }

      return [];
    }

    return [];
  } catch (e) {
    return [];
  }
}

static Future<void> refreshRewardsAfterSpend(int regId) async {
  try {
    await Future.wait([
    getPendingDragRewards(regId),
    getUnreadNotificationCount(regId),
  ]);

  } catch (_) {}
}

// ============ CARD  ==========================
// ================= LUME CARD DETAILS =================
static Future<Map<String, dynamic>> getLumeCard(int regId) async {
  try {
    final res = await http.get(
      Uri.parse("$baseUrl/lume-card/$regId"),
      headers: headers,
    );

    if (res.statusCode != 200) {
      return {"card_exists": false};
    }

    final data = jsonDecode(res.body);

    if (data["card_exists"] != true) {
      return {"card_exists": false};
    }

    final card = data["card"];

    return {
      "card_exists": true,
      "card": {
        "last4": card["last4"],
        "expiry": card["expiry"],
        "network": card["network"],
        "is_locked": card["is_locked"] ?? false,
      }
    };

  } catch (e) {
    return {"card_exists": false};
  }
}


// ================= LUME CARD LOCK / UNLOCK =================
static Future<bool> toggleLumeCardLock(int regId) async {
  try {
    final res = await http.post(
      Uri.parse("$baseUrl/lume-card/lock"),
      headers: headers,
      body: jsonEncode({
        "reg_id": regId,
      }),
    );

    if (res.statusCode != 200) {
      print("CARD LOCK FAILED: ${res.body}");
    }

    return res.statusCode == 200;
  } catch (e) {
    print("CARD LOCK ERROR: $e");
    return false;
  }
}

// ================= LUME CARD DETAILS =================
static Future<Map<String, dynamic>> getLumeCardDetails(int regId) async {
  final res = await http.get(
    Uri.parse("$baseUrl/card/details/$regId"),
    headers: headers,
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  }

  throw Exception("FAILED_TO_FETCH_CARD_DETAILS");
}

// ============ get Card transactions ===============
static Future<List<dynamic>> getCardTransactions(int regId) async {
  final res = await http.get(
    Uri.parse("$baseUrl/card/transactions/$regId"),
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  }
  return [];
}

// For refresh Purpose
static Future<void> refreshAllRewardsData(int regId) async {
  try {
    await Future.wait([
      getPendingDragRewards(regId),
      getCashWon(regId),
      getCoupons(regId),
      getVouchers(regId),
    ]);
  } catch (_) {}
}

// ======== Get card Status ============
static Future<Map<String, dynamic>> getCardStatus(int regId) async {
  final response = await http.get(
    Uri.parse("$baseUrl/lume-card/status/$regId"),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to fetch card status");
  }
}


// ======= Toggle Card Lock ============
static Future<bool> toggleCardLock(int regId) async {
  final res = await http.post(
    Uri.parse("$baseUrl/lume-card/lock"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"reg_id": regId}),
  );

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    return data["is_locked"] == true;
  } else {
    throw Exception("Failed to toggle card lock");
  }
}

static Future<String?> getCardLast4(int regId) async {
  final response = await http.get(
    Uri.parse("$baseUrl/lume-card/$regId"),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    if (data["card_exists"] == true) {
      return data["card"]["card_last4"];
    }
  }

  return null;
}


// TAP & PAY
// ================= TAP & PAY =================
static Future<bool> getTapPayStatus(int regId) async {
  final res = await http.get(
    Uri.parse("$baseUrl/lume-card/tap-pay/$regId"),
    headers: headers,
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body)["enabled"] == true;
  }
  return false;
}


static Future<void> toggleTapPay(int regId, bool enabled) async {
  final res = await http.post(
    Uri.parse("$baseUrl/lume-card/tap-pay/toggle"),
    headers: headers,
    body: jsonEncode({
      "reg_id": regId,
      "enabled": enabled,
    }),
  );

  if (res.statusCode != 200) {
    throw Exception("Failed to update Tap & Pay");
  }
}

// ================= NCMC =================
static Future<bool> getNcmcStatus(int regId) async {
  final res = await http.get(
    Uri.parse("$baseUrl/lume-card/ncmc/$regId"),
    headers: headers,
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body)["enabled"] == true;
  }
  return false;
}

static Future<void> toggleNcmc(int regId, bool enabled) async {
  final res = await http.post(
    Uri.parse("$baseUrl/lume-card/ncmc/toggle"),
    headers: headers,
    body: jsonEncode({
      "reg_id": regId,
      "enabled": enabled,
    }),
  );

  if (res.statusCode != 200) {
    throw Exception("Failed to update NCMC");
  }
}


// ================= CREATE CARD FEATURE NOTIFICATION =================
static Future<void> createCardFeatureNotification({
  required int regId,
  required String title,
  required String body,
}) async {
  try {
    await http.post(
      Uri.parse("$baseUrl/notifications/create"),
      headers: headers,
      body: jsonEncode({
        "reg_id": regId,
        "title": title,
        "body": body,
        "type": "card_security",
      }),
    );
    await getUnreadNotificationCount(regId);

  } catch (_) {}
}

// ================= BLOCK CARD =================
static Future<bool> blockCard(int regId) async {
  final res = await http.post(
    Uri.parse("$baseUrl/lume-card/block"),
    headers: headers,
    body: jsonEncode({
      "reg_id": regId,
    }),
  );

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    return data["is_blocked"] == true;
  }
  throw Exception("Failed to block card");
}

 // ========= Replace Card =============
static Future<void> replaceCard(int regId) async {
  final res = await http.post(
    Uri.parse("$baseUrl/lume-card/replace"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"reg_id": regId}),
  );

  if (res.statusCode != 200) {
    throw Exception("Replace card failed");
  }
}


}