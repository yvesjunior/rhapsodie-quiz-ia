import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutterquiz/core/constants/api_endpoints_constants.dart';
import 'package:flutterquiz/utils/api_utils.dart';
import 'models/group_model.dart';

/// Remote Data Source for Groups
class GroupsRemoteDataSource {
  /// Create a new group
  Future<Group> createGroup({
    required String name,
    String? description,
    String? image,
    bool isPublic = false,
    int maxMembers = 50,
  }) async {
    try {
      final body = <String, String>{
        'name': name,
        'is_public': isPublic ? '1' : '0',
        'max_members': maxMembers.toString(),
      };
      if (description != null) body['description'] = description;
      if (image != null) body['image'] = image;

      final response = await http.post(
        Uri.parse(createGroupUrl),
        body: body,
        headers: await ApiUtils.getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (data['error'] == true) {
        throw Exception(data['message'] ?? 'Failed to create group');
      }

      return Group.fromJson(data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create group: $e');
    }
  }

  /// Get user's groups
  Future<List<Group>> getMyGroups() async {
    try {
      final response = await http.post(
        Uri.parse(getMyGroupsUrl),
        body: {},
        headers: await ApiUtils.getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (data['error'] == true) {
        return [];
      }

      final List<dynamic> groupsJson = (data['data'] as List<dynamic>?) ?? [];
      return groupsJson.map((json) => Group.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to load groups: $e');
    }
  }

  /// Get group by ID or invite code
  Future<Group> getGroup({String? groupId, String? inviteCode}) async {
    try {
      final body = <String, String>{};
      if (groupId != null) body['group_id'] = groupId;
      if (inviteCode != null) body['invite_code'] = inviteCode;

      final response = await http.post(
        Uri.parse(getGroupUrl),
        body: body,
        headers: await ApiUtils.getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (data['error'] == true) {
        throw Exception(data['message'] ?? 'Group not found');
      }

      return Group.fromJson(data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load group: $e');
    }
  }

  /// Join a group by invite code
  Future<Group> joinGroup(String inviteCode) async {
    try {
      final response = await http.post(
        Uri.parse(joinGroupUrl),
        body: {'invite_code': inviteCode},
        headers: await ApiUtils.getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (data['error'] == true) {
        throw Exception(data['message'] ?? 'Failed to join group');
      }

      return Group.fromJson(data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to join group: $e');
    }
  }

  /// Leave a group
  Future<bool> leaveGroup(String groupId) async {
    try {
      final response = await http.post(
        Uri.parse(leaveGroupUrl),
        body: {'group_id': groupId},
        headers: await ApiUtils.getHeaders(),
      );

      final data = jsonDecode(response.body);
      return data['error'] != true;
    } catch (e) {
      throw Exception('Failed to leave group: $e');
    }
  }

  /// Delete a group (owner only)
  Future<bool> deleteGroup(String groupId) async {
    try {
      final response = await http.post(
        Uri.parse(deleteGroupUrl),
        body: {'group_id': groupId},
        headers: await ApiUtils.getHeaders(),
      );

      final data = jsonDecode(response.body);
      if (data['error'] == true) {
        throw Exception(data['message'] ?? 'Failed to delete group');
      }
      return true;
    } catch (e) {
      throw Exception('Failed to delete group: $e');
    }
  }

  /// Search public groups
  Future<List<Group>> searchGroups(String query) async {
    try {
      final response = await http.post(
        Uri.parse(searchGroupsUrl),
        body: {'query': query},
        headers: await ApiUtils.getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (data['error'] == true) {
        return [];
      }

      final List<dynamic> groupsJson = (data['data'] as List<dynamic>?) ?? [];
      return groupsJson.map((json) => Group.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to search groups: $e');
    }
  }

  /// Get public groups for discovery (excludes groups user is already in)
  Future<List<Group>> getPublicGroups({int limit = 50, int offset = 0}) async {
    try {
      final response = await http.post(
        Uri.parse(getPublicGroupsUrl),
        body: {
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
        headers: await ApiUtils.getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (data['error'] == true) {
        return [];
      }

      final List<dynamic> groupsJson = (data['data'] as List<dynamic>?) ?? [];
      return groupsJson.map((json) => Group.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to load public groups: $e');
    }
  }

  /// Join a public group directly (no invite code needed)
  Future<Group> joinPublicGroup(String groupId) async {
    try {
      final response = await http.post(
        Uri.parse(joinPublicGroupUrl),
        body: {'group_id': groupId},
        headers: await ApiUtils.getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (data['error'] == true) {
        throw Exception(data['message'] ?? 'Failed to join group');
      }

      return Group.fromJson(data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to join public group: $e');
    }
  }
}

