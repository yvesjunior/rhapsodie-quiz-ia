import 'dart:convert';
import 'dart:developer';

import 'package:flutterquiz/core/constants/api_endpoints_constants.dart';
import 'package:flutterquiz/core/constants/api_exception.dart';
import 'package:flutterquiz/features/foundation/models/foundation_models.dart';
import 'package:flutterquiz/utils/api_utils.dart';
import 'package:http/http.dart' as http;

class FoundationRemoteDataSource {
  FoundationRemoteDataSource();

  /// Get all Foundation School classes
  Future<List<FoundationClass>> getFoundationClasses() async {
    try {
      final response = await http.post(
        Uri.parse(getFoundationClassesUrl),
        body: {},
        headers: await ApiUtils.getHeaders(),
      );

      log(name: 'FoundationRemoteDataSource', 'getFoundationClasses response: ${response.body}');

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['error'] == true) {
        throw ApiException(data['message']?.toString() ?? 'Failed to load classes');
      }

      final List<dynamic> classesJson = (data['data'] as List<dynamic>?) ?? [];
      return classesJson
          .map((json) => FoundationClass.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      log(name: 'FoundationRemoteDataSource', 'Error: $e');
      throw ApiException('Failed to load Foundation classes: $e');
    }
  }

  /// Get Foundation School class detail
  Future<FoundationClass> getFoundationClassDetail(String classId) async {
    try {
      final response = await http.post(
        Uri.parse(getFoundationClassDetailUrl),
        body: {'class_id': classId},
        headers: await ApiUtils.getHeaders(),
      );

      log(name: 'FoundationRemoteDataSource', 'getFoundationClassDetail response: ${response.body}');

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['error'] == true) {
        throw ApiException(data['message']?.toString() ?? 'Failed to load class detail');
      }

      return FoundationClass.fromJson(data['data'] as Map<String, dynamic>);
    } catch (e) {
      log(name: 'FoundationRemoteDataSource', 'Error: $e');
      throw ApiException('Failed to load Foundation class detail: $e');
    }
  }
}

