import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_model.dart';
import '../models/message_model.dart';
import 'shared.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';

  // Hapus method register karena tidak akan digunakan
  // static Future<Map<String, dynamic>> register(...) { ... }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('Raw Response Body: ${response.body}');
      print('Status Code: ${response.statusCode}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData['status'] == true) {
          final userData = responseData['user'] as Map<String, dynamic>;

          print('Token from API: ${responseData['token']}');
          print('User from API: $userData');

          final role = userData['role']?.toString().toLowerCase() ?? '';

          if (role != 'admin') {
            return {
              'status': false,
              'message': 'Akses ditolak. Hanya admin yang dapat login.',
            };
          }

          final token = responseData['token']?.toString();

          if (token == null || token.isEmpty) {
            return {
              'status': false,
              'message': 'Token tidak ditemukan dalam response',
            };
          }

          // Return Map bukan User object
          return {
            'status': true,
            'token': token,
            'user': userData, // Kirim Map, bukan User object
          };
        } else {
          return {
            'status': false,
            'message': responseData['message'] ?? 'Login gagal',
          };
        }
      } else {
        return {
          'status': false,
          'message': responseData['message'] ?? 'Server error',
        };
      }
    } catch (e) {
      print('Login Error: $e');
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // services/api.dart - Tambahkan method debug
  static Future<Map<String, dynamic>> testAdminAccess() async {
    try {
      final token = await SharedService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('No token available');
      }

      print('🧪 Testing admin access...');
      print('🔗 URL: $baseUrl/admin/test');
      print('🔑 Token: ${token.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse('$baseUrl/admin/test'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('📥 Test Response Status: ${response.statusCode}');
      print('📥 Test Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('❌ Test failed: ${response.statusCode}');
        return {
          'status': false,
          'message': 'Test failed with status ${response.statusCode}',
          'body': response.body,
        };
      }
    } catch (e) {
      print('❌ Test admin access error: $e');
      return {'status': false, 'message': 'Test error: $e'};
    }
  }

  // Method untuk logout (opsional)
  static Future<Map<String, dynamic>> logout(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);
      return {
        'status': response.statusCode == 200,
        'message': responseData['message'] ?? 'Logout berhasil',
      };
    } catch (e) {
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // Method untuk get admin profile (opsional)
  static Future<Map<String, dynamic>> getAdminProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'status': true, 'profile': data['profile']};
      } else {
        return {'status': false, 'message': 'Gagal mengambil profil admin'};
      }
    } catch (e) {
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // Method lainnya tetap sama...
  static Future<List<SensorData>> fetchSensorData(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_sensor_data'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body)['data'];
        return data.map((e) => SensorData.fromJson(e)).toList();
      } else {
        throw Exception('Gagal load sensor: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<Map<String, dynamic>> controlActuator(
    String name,
    bool state,
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/control_actuator'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({"name": name, "state": state ? "ON" : "OFF"}),
      );

      final responseData = jsonDecode(response.body);
      return responseData;
    } catch (e) {
      return {"status": false, "message": "Gagal mengirim perintah: $e"};
    }
  }

  static Future<List<UserMessage>> getUserMessages(String token) async {
    final res = await http.get(
      Uri.parse("$baseUrl/user/messages"),
      headers: {"Authorization": "Bearer $token"},
    );

    final data = jsonDecode(res.body);
    List messages = data["messages"];

    return messages.map((m) => UserMessage.fromJson(m)).toList();
  }
}
