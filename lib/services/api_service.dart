import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api';

  static Future<dynamic> get(String path) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl$path'));
      return jsonDecode(res.body);
    } catch (e) {
      return {'error': 'Cannot connect to backend. Run: dart run bin/server.dart'};
    }
  }

  static Future<dynamic> post(String path, [Map<String, dynamic>? body]) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: {'Content-Type': 'application/json'},
        body: body != null ? jsonEncode(body) : null,
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'error': 'Cannot connect to backend.'};
    }
  }
}
