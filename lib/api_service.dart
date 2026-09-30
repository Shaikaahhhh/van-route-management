import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'http://erpapi.niveosys.org';

  // GET VAN NUMBERS
  Future<List<Map<String, dynamic>>> getVanNumbers() async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/api/Utility/GetSelectListbyCode',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'typeCode': 'VAN',
        'name': '',
      }),
    );

    debugPrint('========== VAN API ==========');
    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('BODY: ${response.body}');
    debugPrint('=============================');

    return parseListResponse(response);
  }

  // GET ROUTE CODES
  Future<List<Map<String, dynamic>>> getRouteCodes() async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/api/Utility/GetSelectListbyCode',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'typeCode': 'ROT',
        'name': '',
      }),
    );

    debugPrint('========= ROUTE API =========');
    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('BODY: ${response.body}');
    debugPrint('=============================');

    return parseListResponse(response);
  }

  // GET ALL VAN ROUTES
  Future<List<Map<String, dynamic>>> getAllVanRoutes() async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/VanRoute/GetAllVanRoutes',
      ),
      headers: {
        'Accept': 'application/json',
      },
    );

    debugPrint('======== GET ALL API ========');
    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('BODY: ${response.body}');
    debugPrint('=============================');

    return parseListResponse(response);
  }

  // GET ONE VAN ROUTE
  Future<Map<String, dynamic>> getVanRoute(
      int id,
      ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/VanRoute/GetVanRoute'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'vanRouteId': id,
      }),
    );

    debugPrint('======== GET ONE API ========');
    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('BODY: ${response.body}');
    debugPrint('=============================');

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        if (decoded['data'] is Map) {
          return Map<String, dynamic>.from(
            decoded['data'],
          );
        }

        return decoded;
      }

      throw Exception('Unexpected response format');
    }

    throw Exception(
      'Failed to get van route: ${response.statusCode}',
    );
  }

  // CREATE VAN ROUTE
  Future<void> createVanRoute({
    required String vanNumber,
    required String routeCode,
    required bool isActive,
    required String assignedDate,
  }) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/api/VanRoute/CreateVanRoute',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'vanNumber': vanNumber,
        'routeCode': routeCode,
        'isActive': isActive,
        'assignedDate': assignedDate,
      }),
    );

    debugPrint('========= CREATE API =========');
    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('BODY: ${response.body}');
    debugPrint('==============================');

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'Create failed: ${response.statusCode}\n'
            '${response.body}',
      );
    }
  }

  // UPDATE VAN ROUTE
  Future<void> updateVanRoute({
    required int id,
    required String vanNumber,
    required String routeCode,
    required bool isActive,
    required String assignedDate,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/VanRoute/UpdateVanRoute?id=$id'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'vanNumber': vanNumber,
        'routeCode': routeCode,
        'isActive': isActive,
        'assignedDate': assignedDate,
      }),
    );

    debugPrint('========= UPDATE API =========');
    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('BODY: ${response.body}');
    debugPrint('===============================');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Update failed: ${response.statusCode}\n${response.body}',
      );
    }
  }

  // DELETE VAN ROUTE
  Future<void> deleteVanRoute(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/VanRoute/DeleteVanRoute'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'vanRouteId': id,
      }),
    );

    debugPrint('========= DELETE API =========');
    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('BODY: ${response.body}');
    debugPrint('===============================');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Delete failed: ${response.statusCode}\n${response.body}',
      );
    }
  }

  // COMMON RESPONSE PARSER
  List<Map<String, dynamic>> parseListResponse(
      http.Response response,
      ) {
    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'API Error: ${response.statusCode}\n'
            '${response.body}',
      );
    }

    if (response.body.trim().isEmpty) {
      return [];
    }

    final decoded = jsonDecode(response.body);

    debugPrint(
      'DECODED TYPE: ${decoded.runtimeType}',
    );

    debugPrint(
      'DECODED DATA: $decoded',
    );

    // Direct List
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map(
            (item) =>
        Map<String, dynamic>.from(item),
      )
          .toList();
    }

    // Object containing data/result/items
    if (decoded is Map<String, dynamic>) {
      final data =
          decoded['data'] ??
              decoded['result'] ??
              decoded['items'];

      if (data is List) {
        return data
            .whereType<Map>()
            .map(
              (item) =>
          Map<String, dynamic>.from(item),
        )
            .toList();
      }
    }

    return [];
  }
}