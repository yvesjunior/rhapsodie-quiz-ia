import 'dart:convert';
import 'dart:io';

import 'package:flutterquiz/core/constants/api_endpoints_constants.dart';
import 'package:flutterquiz/core/constants/api_exception.dart';
import 'package:flutterquiz/core/constants/error_message_keys.dart';
import 'package:flutterquiz/features/rhapsody/models/rhapsody_models.dart';
import 'package:flutterquiz/utils/api_utils.dart';
import 'package:http/http.dart' as http;

class RhapsodyRemoteDataSource {
  /// Get all available Rhapsody years
  Future<List<RhapsodyYear>> getRhapsodyYears() async {
    try {
      final response = await http.post(
        Uri.parse(getRhapsodyYearsUrl),
        body: <String, String>{},
        headers: await ApiUtils.getHeaders(),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['error'] == true) {
        return [];
      }

      final yearsJson = (data['data'] as List<dynamic>?) ?? [];
      return yearsJson
          .map((json) => RhapsodyYear.fromJson(json as Map<String, dynamic>))
          .toList();
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw const ApiException(errorCodeNoInternet);
    }
  }

  /// Get months for a specific year
  Future<List<RhapsodyMonth>> getRhapsodyMonths(int year) async {
    try {
      final response = await http.post(
        Uri.parse(getRhapsodyMonthsUrl),
        body: {'year': year.toString()},
        headers: await ApiUtils.getHeaders(),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['error'] == true) {
        return [];
      }

      final monthsJson = (data['data'] as List<dynamic>?) ?? [];
      return monthsJson
          .map((json) => RhapsodyMonth.fromJson(json as Map<String, dynamic>))
          .toList();
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw const ApiException(errorCodeNoInternet);
    }
  }

  /// Get days for a specific month
  Future<List<RhapsodyDay>> getRhapsodyDays(int year, int month) async {
    try {
      final response = await http.post(
        Uri.parse(getRhapsodyDaysUrl),
        body: {
          'year': year.toString(),
          'month': month.toString(),
        },
        headers: await ApiUtils.getHeaders(),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['error'] == true) {
        return [];
      }

      final daysJson = (data['data'] as List<dynamic>?) ?? [];
      return daysJson
          .map((json) => RhapsodyDay.fromJson(json as Map<String, dynamic>))
          .toList();
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw const ApiException(errorCodeNoInternet);
    }
  }

  /// Get full detail for a specific day
  Future<RhapsodyDayDetail?> getRhapsodyDayDetail(int year, int month, int day) async {
    try {
      final response = await http.post(
        Uri.parse(getRhapsodyDayDetailUrl),
        body: {
          'year': year.toString(),
          'month': month.toString(),
          'day': day.toString(),
        },
        headers: await ApiUtils.getHeaders(),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['error'] == true || data['data'] == null) {
        return null;
      }

      return RhapsodyDayDetail.fromJson(data['data'] as Map<String, dynamic>);
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw const ApiException(errorCodeNoInternet);
    }
  }
}


