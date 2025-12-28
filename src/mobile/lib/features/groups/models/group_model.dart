/// Group Model
class Group {
  final String id;
  final String name;
  final String? description;
  final String? image;
  final String ownerId;
  final String? inviteCode;
  final bool isPublic;
  final int maxMembers;
  final int memberCount;
  final String status;
  final String? role; // User's role in the group
  final bool isMember; // Whether the current user is a member
  final String? joinedAt;
  final List<GroupMember>? members;

  Group({
    required this.id,
    required this.name,
    this.description,
    this.image,
    required this.ownerId,
    this.inviteCode,
    this.isPublic = false,
    this.maxMembers = 50,
    this.memberCount = 1,
    this.status = 'active',
    this.role,
    this.isMember = false,
    this.joinedAt,
    this.members,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    List<GroupMember>? members;
    if (json['members'] != null) {
      members = (json['members'] as List<dynamic>)
          .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    return Group(
      id: json['id']?.toString() ?? '',
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      image: json['image'] as String?,
      ownerId: json['owner_id']?.toString() ?? '',
      inviteCode: json['invite_code'] as String?,
      isPublic: json['is_public'] == '1' || json['is_public'] == true || json['is_public'] == 1,
      maxMembers: int.tryParse(json['max_members']?.toString() ?? '50') ?? 50,
      memberCount: int.tryParse(json['member_count']?.toString() ?? '1') ?? 1,
      status: (json['status'] as String?) ?? 'active',
      role: json['role'] as String?,
      isMember: json['is_member'] == true || json['is_member'] == '1' || json['role'] != null,
      joinedAt: json['joined_at'] as String?,
      members: members,
    );
  }

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin' || role == 'owner';
  bool get isFull => memberCount >= maxMembers;
}

/// Group Member Model
class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final String role;
  final String status;
  final String? joinedAt;
  final String? name;
  final String? profile;
  final String? email;

  GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.role,
    this.status = 'active',
    this.joinedAt,
    this.name,
    this.profile,
    this.email,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id']?.toString() ?? '',
      groupId: json['group_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      role: (json['role'] as String?) ?? 'member',
      status: (json['status'] as String?) ?? 'active',
      joinedAt: json['joined_at'] as String?,
      name: json['name'] as String?,
      profile: json['profile'] as String?,
      email: json['email'] as String?,
    );
  }

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin' || role == 'owner';
}

