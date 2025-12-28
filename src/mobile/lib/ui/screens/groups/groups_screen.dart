import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/groups/groups.dart';
import 'package:flutterquiz/features/topics/topics.dart';
import 'package:flutterquiz/ui/screens/battles/group_battle_screen.dart';

/// Groups Screen - Shows user's groups with tabs
class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  static Route route() {
    return MaterialPageRoute(builder: (_) => const GroupsScreen());
  }

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Group> _publicGroups = [];
  bool _loadingPublicGroups = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<GroupsCubit>().loadMyGroups();
    _loadPublicGroups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPublicGroups() async {
    setState(() => _loadingPublicGroups = true);
    try {
      final groups = await context.read<GroupsCubit>().getPublicGroups();
      setState(() {
        _publicGroups = groups;
        _loadingPublicGroups = false;
      });
    } catch (e) {
      setState(() => _loadingPublicGroups = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Groups'),
            Tab(text: 'Discover'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // My Groups Tab
          BlocBuilder<GroupsCubit, GroupsState>(
            builder: (context, state) {
              if (state is GroupsLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is GroupsError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.read<GroupsCubit>().loadMyGroups(forceRefresh: true),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (state is GroupsLoaded) {
                if (state.groups.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildGroupsList(state.groups);
              }

              return const SizedBox();
            },
          ),
          // Discover Tab
          _buildDiscoverTab(),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'join',
            onPressed: () => _showJoinDialog(),
            child: const Icon(Icons.group_add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'create',
            onPressed: () => _showCreateDialog(),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverTab() {
    if (_loadingPublicGroups) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_publicGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Public Groups',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to create a public group!',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showCreateDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Create Public Group'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPublicGroups,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _publicGroups.length,
        itemBuilder: (context, index) {
          final group = _publicGroups[index];
          return _PublicGroupCard(
            group: group,
            onJoin: () => _joinPublicGroup(group),
            onTap: () => _openGroup(group),
          );
        },
      ),
    );
  }

  Future<void> _joinPublicGroup(Group group) async {
    final joinedGroup = await context.read<GroupsCubit>().joinPublicGroup(group.id);
    if (joinedGroup != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joined "${joinedGroup.name}"!')),
      );
      // Switch to My Groups tab
      _tabController.animateTo(0);
      // Refresh public groups list
      _loadPublicGroups();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Groups Yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Create a group or join one with an invite code',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showJoinDialog(),
                icon: const Icon(Icons.group_add),
                label: const Text('Join Group'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showCreateDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Create Group'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsList(List<Group> groups) {
    return RefreshIndicator(
      onRefresh: () => context.read<GroupsCubit>().loadMyGroups(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return _GroupCard(
            group: group,
            onTap: () => _openGroup(group),
          );
        },
      ),
    );
  }

  void _openGroup(Group group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupDetailScreen(group: group),
      ),
    );
  }

  void _showCreateDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    bool isPublic = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Group'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    hintText: 'Enter group name',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'What is this group about?',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Public Group'),
                  subtitle: const Text('Anyone can find and join'),
                  value: isPublic,
                  onChanged: (v) => setState(() => isPublic = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                final group = await context.read<GroupsCubit>().createGroup(
                  name: nameController.text.trim(),
                  description: descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
                  isPublic: isPublic,
                );
                if (group != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Group "${group.name}" created!')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinDialog() {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join Group'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            labelText: 'Invite Code',
            hintText: 'Enter the group invite code',
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final group = await context.read<GroupsCubit>().joinGroup(
                codeController.text.trim().toUpperCase(),
              );
              if (group != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Joined "${group.name}"!')),
                );
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    final searchController = TextEditingController();
    List<Group> searchResults = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Search Groups'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: 'Search',
                    hintText: 'Enter group name',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () async {
                        if (searchController.text.trim().isEmpty) return;
                        final results = await context
                            .read<GroupsCubit>()
                            .searchGroups(searchController.text.trim());
                        setState(() => searchResults = results);
                      },
                    ),
                  ),
                  onSubmitted: (value) async {
                    if (value.trim().isEmpty) return;
                    final results = await context
                        .read<GroupsCubit>()
                        .searchGroups(value.trim());
                    setState(() => searchResults = results);
                  },
                ),
                const SizedBox(height: 16),
                if (searchResults.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final group = searchResults[index];
                        return ListTile(
                          title: Text(group.name),
                          subtitle: Text('${group.memberCount} members'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pop(ctx);
                            _openGroup(group);
                          },
                        );
                      },
                    ),
                  )
                else
                  const Text('Search for public groups'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Group Card Widget
class _GroupCard extends StatelessWidget {
  final Group group;
  final VoidCallback onTap;

  const _GroupCard({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.purple.shade100,
                child: Text(
                  group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (group.isOwner)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Owner',
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${group.memberCount} members',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

/// Public Group Card Widget (for Discover tab)
class _PublicGroupCard extends StatelessWidget {
  final Group group;
  final VoidCallback onJoin;
  final VoidCallback onTap;

  const _PublicGroupCard({
    required this.group,
    required this.onJoin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.teal.shade100,
                child: Text(
                  group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (group.description != null && group.description!.isNotEmpty)
                      Text(
                        group.description!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      '${group.memberCount}/${group.maxMembers} members',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!group.isFull)
                ElevatedButton(
                  onPressed: onJoin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Join'),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Full',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Group Detail Screen
class GroupDetailScreen extends StatefulWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late Group group;

  @override
  void initState() {
    super.initState();
    group = widget.group;
  }

  Future<void> _joinPublicGroup() async {
    final joinedGroup = await context.read<GroupsCubit>().joinPublicGroup(group.id);
    if (joinedGroup != null && mounted) {
      setState(() => group = joinedGroup);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joined "${joinedGroup.name}"!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          if (group.isMember && group.inviteCode != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareInviteCode(context),
            ),
          if (group.isMember)
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(context, value),
              itemBuilder: (context) => [
                if (!group.isOwner)
                  const PopupMenuItem(
                    value: 'leave',
                    child: Text('Leave Group'),
                  ),
                if (group.isOwner)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete Group', style: TextStyle(color: Colors.red)),
                  ),
                if (group.isAdmin)
                  const PopupMenuItem(
                    value: 'settings',
                    child: Text('Group Settings'),
                  ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (group.description != null) ...[
                      Text(
                        group.description!,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.people,
                          label: '${group.memberCount}/${group.maxMembers}',
                        ),
                        const SizedBox(width: 12),
                        _InfoChip(
                          icon: group.isPublic ? Icons.public : Icons.lock,
                          label: group.isPublic ? 'Public' : 'Private',
                        ),
                      ],
                    ),
                    if (group.inviteCode != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Invite Code: '),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              group.inviteCode!,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: group.inviteCode!),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Invite code copied!'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Members Section (only show for members or public groups)
            if (group.isMember || group.isPublic) ...[
              Text(
                'Members',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (group.members != null)
                ...group.members!.map((member) => _MemberTile(member: member))
              else
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.people),
                    title: Text('Loading members...'),
                  ),
                ),
              const SizedBox(height: 24),
            ],

            // Battle Section (only for members)
            if (group.isMember) ...[
              Text(
                'Group Battles',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (group.isAdmin)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.add_circle, color: Colors.green),
                    title: const Text('Create New Battle'),
                    subtitle: const Text('Challenge your group members'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to create battle screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateGroupBattleScreen(group: group),
                        ),
                      );
                    },
                  ),
                ),
            ],
            if (group.isMember)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Battle History'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to battle history
                  },
                ),
              ),

            // Join button for non-members viewing public groups
            if (!group.isMember && group.isPublic) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: group.isFull ? null : _joinPublicGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  icon: const Icon(Icons.group_add),
                  label: Text(group.isFull ? 'Group is Full' : 'Join This Group'),
                ),
              ),
            ],

            // Message for private groups where user is not a member
            if (!group.isMember && !group.isPublic)
              Card(
                color: Colors.orange.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.lock, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This is a private group. You need an invite code to join.',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _shareInviteCode(BuildContext context) {
    if (group.inviteCode == null) return;
    Clipboard.setData(ClipboardData(text: group.inviteCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invite code ${group.inviteCode} copied to clipboard!'),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'leave':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Leave Group?'),
            content: Text('Are you sure you want to leave "${group.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final success = await context.read<GroupsCubit>().leaveGroup(group.id);
                  if (success && context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Left group')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Leave'),
              ),
            ],
          ),
        );
        break;
      case 'delete':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Group?'),
            content: Text(
              'Are you sure you want to delete "${group.name}"?\n\n'
              'This will remove all members and cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final success = await context.read<GroupsCubit>().deleteGroup(group.id);
                  if (success && context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Group deleted')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        break;
      case 'settings':
        // Navigate to settings
        break;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final GroupMember member;

  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: member.profile != null && member.profile!.isNotEmpty
              ? NetworkImage(member.profile!)
              : null,
          child: member.profile == null || member.profile!.isEmpty
              ? Text(member.name?.isNotEmpty == true
                  ? member.name![0].toUpperCase()
                  : '?')
              : null,
        ),
        title: Text(member.name ?? 'Unknown'),
        subtitle: Text(member.role.toUpperCase()),
        trailing: member.isOwner
            ? const Icon(Icons.star, color: Colors.amber)
            : null,
      ),
    );
  }
}

/// Create Group Battle Screen
class CreateGroupBattleScreen extends StatefulWidget {
  final Group group;

  const CreateGroupBattleScreen({super.key, required this.group});

  @override
  State<CreateGroupBattleScreen> createState() =>
      _CreateGroupBattleScreenState();
}

class _CreateGroupBattleScreenState extends State<CreateGroupBattleScreen> {
  Topic? _selectedTopic;
  TopicCategory? _selectedCategory;
  int _questionCount = 10;
  int _timePerQuestion = 15;

  @override
  void initState() {
    super.initState();
    context.read<TopicsCubit>().loadTopics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Battle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Battle Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Topic Selection
            Text(
              'Select Topic',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            BlocBuilder<TopicsCubit, TopicsState>(
              builder: (context, state) {
                if (state is TopicsLoaded) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: state.topics.map((topic) {
                      final isSelected = _selectedTopic?.id == topic.id;
                      return ChoiceChip(
                        label: Text(topic.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedTopic = selected ? topic : null;
                            _selectedCategory = null;
                          });
                          if (selected) {
                            context.read<TopicsCubit>().loadCategories(topic.id);
                          }
                        },
                      );
                    }).toList(),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
            const SizedBox(height: 24),

            // Category Selection
            if (_selectedTopic != null) ...[
              Text(
                'Select Category',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              BlocBuilder<TopicsCubit, TopicsState>(
                builder: (context, state) {
                  if (state is TopicsLoaded && state.categories != null) {
                    final categories = state.categories!
                        .where((c) => c.questionCount > 0)
                        .toList();
                    
                    if (categories.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No categories with questions available'),
                      );
                    }

                    return SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected = _selectedCategory?.id == category.id;

                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: InkWell(
                              onTap: () {
                                setState(() => _selectedCategory = category);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 120,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.teal.shade100
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: isSelected
                                      ? Border.all(color: Colors.teal, width: 2)
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      category.name,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${category.questionCount} Q',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
              const SizedBox(height: 24),
            ],

            // Question Count
            Text('Questions: $_questionCount'),
            Slider(
              value: _questionCount.toDouble(),
              min: 5,
              max: 30,
              divisions: 5,
              label: _questionCount.toString(),
              onChanged: (v) => setState(() => _questionCount = v.toInt()),
            ),

            // Time Per Question
            Text('Time per question: $_timePerQuestion seconds'),
            Slider(
              value: _timePerQuestion.toDouble(),
              min: 10,
              max: 60,
              divisions: 10,
              label: '${_timePerQuestion}s',
              onChanged: (v) => setState(() => _timePerQuestion = v.toInt()),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedTopic != null && _selectedCategory != null
                    ? () => _createBattle()
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('Create Battle'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createBattle() {
    if (_selectedTopic == null || _selectedCategory == null) return;

    Navigator.pushReplacement(
      context,
      GroupBattleScreen.route(
        battleId: '', // Will be created
        groupId: widget.group.id,
        topicId: _selectedTopic!.id,
        categoryId: _selectedCategory!.id,
        isCreator: true,
      ),
    );
  }
}

