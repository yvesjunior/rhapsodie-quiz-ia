import 'dart:convert';
import 'dart:io';

import 'package:flutterquiz/core/constants/api_exception.dart';
import 'package:flutterquiz/core/constants/constants.dart';
import 'package:flutterquiz/utils/api_utils.dart';
import 'package:http/http.dart' as http;

final class SystemConfigRemoteDataSource {
  Future<Map<String, dynamic>> getSystemConfig() async {
    try {
      final url = getSystemConfigUrl;
      print('🔗 Calling API: $url');
      
      final response = await http.post(
        Uri.parse(url),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw ApiException('Request timeout: Unable to connect to server');
        },
      );
      
      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body length: ${response.body.length}');
      
      if (response.statusCode != 200) {
        throw ApiException('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
      
      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;

      if (responseJson['error'] as bool) {
        throw ApiException(responseJson['message'].toString());
      }
      
      print('✅ System config loaded successfully');
      return responseJson['data'] as Map<String, dynamic>;
    } on SocketException catch (e) {
      print('❌ SocketException: ${e.message}');
      throw ApiException('${errorCodeNoInternet}: ${e.message}');
    } on FormatException catch (e) {
      print('❌ FormatException: ${e.message}');
      throw ApiException('JSON Parse Error: ${e.message}');
    } on ApiException {
      rethrow;
    } on Exception catch (e) {
      print('❌ Exception: ${e.toString()}');
      throw ApiException('${errorCodeDefaultMessage}: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getSupportedQuestionLanguages() async {
    try {
      final response = await http.post(
        Uri.parse(getSupportedQuestionLanguageUrl),
      );

      if (response.statusCode != 200) {
        throw ApiException('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }

      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;

      if (responseJson['error'] as bool) {
        throw ApiException(responseJson['message'].toString());
      }
      return (responseJson['data'] as List).cast<Map<String, dynamic>>();
    } on SocketException catch (e) {
      throw ApiException('${errorCodeNoInternet}: ${e.message}');
    } on FormatException catch (e) {
      throw ApiException('JSON Parse Error: ${e.message}');
    } on ApiException {
      rethrow;
    } on Exception catch (e) {
      throw ApiException('${errorCodeDefaultMessage}: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getSupportedLanguageList() async {
    try {
      final response = await http.post(
        Uri.parse(getSupportedLanguageListUrl),
        //from :: 1 - App, 2 - Web
        body: {'from': '1'},
      );

      if (response.statusCode != 200) {
        throw ApiException('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }

      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;

      if (responseJson['error'] as bool) {
        throw ApiException(responseJson['message'].toString());
      }
      return (responseJson['data'] as List).cast<Map<String, dynamic>>();
    } on SocketException catch (e) {
      throw ApiException('${errorCodeNoInternet}: ${e.message}');
    } on FormatException catch (e) {
      throw ApiException('JSON Parse Error: ${e.message}');
    } on ApiException {
      rethrow;
    } on Exception catch (e) {
      throw ApiException('${errorCodeDefaultMessage}: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getSystemLanguage(
    String name,
    String title,
  ) async {
    try {
      final body = {
        'language': name,
        //from :: 1 - App, 2 - Web
        'from': '1',
      };

      final response = await http.post(
        Uri.parse(getSystemLanguageJson),
        body: body,
      );

      if (response.statusCode != 200) {
        throw ApiException('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

      if (jsonData['error'] as bool) {
        throw ApiException(jsonData['message'] as String);
      }

      final translations = (jsonData['data'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v.toString()),
      );

      return {
        'name': name,
        'title': title,
        'app_rtl_support': jsonData['rtl_support'] as String,
        'app_version': jsonData['version'] as String,
        'app_default': jsonData['default'] as String,
        'translations': translations,
      };
    } on SocketException catch (e) {
      throw ApiException('${errorCodeNoInternet}: ${e.message}');
    } on FormatException catch (e) {
      throw ApiException('JSON Parse Error: ${e.message}');
    } on ApiException {
      rethrow;
    } on Exception catch (e) {
      throw ApiException('${errorCodeDefaultMessage}: ${e.toString()}');
    }
  }

  Future<String> getAppSettings(String type) async {
    try {
      final body = {typeKey: type};
      final response = await http.post(
        Uri.parse(getAppSettingsUrl),
        body: body,
        headers: await ApiUtils.getHeaders(),
      );
      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;

      if (responseJson['error'] as bool) {
        throw ApiException(responseJson['message'].toString());
      }
      return responseJson['data'].toString();
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on ApiException {
      rethrow;
    } on Exception {
      throw const ApiException(errorCodeDefaultMessage);
    }
  }
}
