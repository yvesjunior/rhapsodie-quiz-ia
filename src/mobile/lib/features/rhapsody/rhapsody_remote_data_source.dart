import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutterquiz/core/constants/api_endpoints_constants.dart';
import 'package:flutterquiz/utils/api_utils.dart';
import 'models/rhapsody_models.dart';

class RhapsodyRemoteDataSource {
  /// Get all available Rhapsody years
  Future<List<RhapsodyYear>> getRhapsodyYears() async {
    try {
      final response = await http.post(
        Uri.parse(getRhapsodyYearsUrl),
        body: {},
        headers: await ApiUtils.getHeaders(),
      );

      final data = jsonDecode(response.body);
      if (data['error'] == true) {
        return [];
      }

      final List<dynamic> yearsJson = data['data'] ?? [];
      return yearsJson
          .map((json) => RhapsodyYear.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load Rhapsody years: $e');
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

      final data = jsonDecode(response.body);
      if (data['error'] == true) {
        return [];
      }

      final List<dynamic> monthsJson = data['data'] ?? [];
      return monthsJson
          .map((json) => RhapsodyMonth.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load Rhapsody months: $e');
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

      final data = jsonDecode(response.body);
      if (data['error'] == true) {
        return [];
      }

      final List<dynamic> daysJson = data['data'] ?? [];
      return daysJson
          .map((json) => RhapsodyDay.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load Rhapsody days: $e');
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

      final data = jsonDecode(response.body);
      if (data['error'] == true || data['data'] == null) {
        return null;
      }

      return RhapsodyDayDetail.fromJson(data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load Rhapsody day detail: $e');
    }
  }
}

