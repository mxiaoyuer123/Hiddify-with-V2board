// 文件路径: lib/features/login/service/auth_service.dart
import 'package:hiddify/features/panel/v2board/models/invite_code_model.dart';
import 'package:hiddify/features/panel/v2board/models/plan_model.dart';
import 'package:hiddify/features/panel/v2board/models/user_info_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class AuthService {
  static const _baseUrl = "https://net.misakra.art";
  static const _inviteLinkBase = "$_baseUrl/#/register?code=";

  // 获取完整邀请码链接的方法
  static String getInviteLink(String code) {
    return '$_inviteLinkBase$code';
  }
  // 统一的 POST 请求方法
  Future<Map<String, dynamic>> _postRequest(
      String endpoint, Map<String, dynamic> body,
      {Map<String, String>? headers}) async {
    final url = Uri.parse("$_baseUrl$endpoint");
    final response = await http.post(
      url,
      headers: headers ?? {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Request to $endpoint failed: ${response.statusCode}");
    }
  }

  // 统一的 GET 请求方法
  Future<Map<String, dynamic>> _getRequest(String endpoint,
      {Map<String, String>? headers}) async {
    final url = Uri.parse("$_baseUrl$endpoint");
    final response = await http.get(
      url,
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Request to $endpoint failed: ${response.statusCode}");
    }
  }
    // 划转佣金到余额的方法
  Future<bool> transferCommission(
      String accessToken, int transferAmount) async {
    final response = await _postRequest(
      '/api/v1/user/transfer',
      {'transfer_amount': transferAmount},
      headers: {'Authorization': accessToken}, // 需要用户的认证令牌
    );

    return response['status'] == 'success';
  }

    // 生成邀请码的方法
  Future<bool> generateInviteCode(String accessToken) async {
    final url = Uri.parse("$_baseUrl/api/v1/user/invite/save");
    final response = await http.get(
      url,
      headers: {'Authorization': accessToken},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data["status"] == "success") {
        return true; // 生成成功
      } else {
        throw Exception("Failed to generate invite code: ${data["message"]}");
      }
    } else {
      throw Exception(
          "Request to generate invite code failed: ${response.statusCode}");
    }
  }

  // 获取邀请码数据
  Future<List<InviteCode>> fetchInviteCodes(String accessToken) async {
    final result = await _getRequest("/api/v1/user/invite/fetch", headers: {
      'Authorization': accessToken,
    });

    if (result["status"] == "success") {
      final codes = result["data"]["codes"] as List;
      return codes.map((json) => InviteCode.fromJson(json)).toList();
    } else {
      throw Exception("Failed to retrieve invite codes: ${result["message"]}");
    }
  }
  // 登录请求
  Future<Map<String, dynamic>> login(String email, String password) async {
    return await _postRequest(
      "/api/v1/passport/auth/login",
      {"email": email, "password": password},
    );
  }

  // 注册请求
  Future<Map<String, dynamic>> register(String email, String password,
      String inviteCode, String emailCode) async {
    return await _postRequest(
      "/api/v1/passport/auth/register",
      {
        "email": email,
        "password": password,
        "invite_code": inviteCode,
        "email_code": emailCode,
      },
    );
  }

  // 发送验证码请求
  Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    final url = Uri.parse("$_baseUrl/api/v1/passport/comm/sendEmailVerify");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'email': email},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
          "Failed to send verification code: ${response.statusCode}");
    }
  }

  // 重置密码请求
  Future<Map<String, dynamic>> resetPassword(
      String email, String password, String emailCode) async {
    return await _postRequest(
      "/api/v1/passport/auth/forget",
      {
        "email": email,
        "password": password,
        "email_code": emailCode,
      },
    );
  }

  // 获取订阅链接请求
  Future<String?> getSubscriptionLink(String accessToken) async {
    final url = Uri.parse("$_baseUrl/api/v1/user/getSubscribe");
    final response = await http.get(
      url,
      headers: {'Authorization': accessToken},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data["status"] == "success") {
        return data["data"]["subscribe_url"];
      } else {
        throw Exception(
            "Failed to retrieve subscription link: ${data["message"]}");
      }
    } else {
      throw Exception(
          "Failed to retrieve subscription link: ${response.statusCode}");
    }
  }

  // 获取套餐计划数据请求
  Future<List<Plan>> fetchPlanData(String accessToken) async {
    final result = await _getRequest("/api/v1/user/plan/fetch", headers: {
      'Authorization': accessToken,
    });

    if (result["status"] == "success") {
      return (result["data"] as List)
          .map((json) => Plan.fromJson(json))
          .toList();
    } else {
      throw Exception("Failed to retrieve plan data: ${result["message"]}");
    }
  }
  
    // 验证token的方法
  Future<bool> validateToken(String token) async {
    final url = Uri.parse("$_baseUrl/api/v1/user/getSubscribe");
    final response = await http.get(
      url,
      headers: {'Authorization': token},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data["status"] == "success";
    } else if (response.statusCode == 401) {
      // 处理 token 过期的情况
      return false;
    } else {
      // 处理其他可能的错误
      return false;
    }
  }

    // 获取用户信息
  Future<UserInfo?> fetchUserInfo(String accessToken) async {
    final result = await _getRequest("/api/v1/user/info", headers: {
      'Authorization': accessToken,
    });

    if (result["status"] == "success") {
      return UserInfo.fromJson(result["data"]);
    } else {
      throw Exception("Failed to retrieve user info: ${result["message"]}");
    }
  }

    Future<String?> resetSubscriptionLink(String accessToken) async {
    final url = Uri.parse("$_baseUrl/api/v1/user/resetSecurity");
    final response = await http.get(
      url,
      headers: {'Authorization': accessToken},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data["status"] == "success") {
        return data["data"];
      } else {
        throw Exception(
            "Failed to reset subscription link: ${data["message"]}");
      }
    } else {
      throw Exception(
          "Failed to reset subscription link: ${response.statusCode}");
    }
  }


}
