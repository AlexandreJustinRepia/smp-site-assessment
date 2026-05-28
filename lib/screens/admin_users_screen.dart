import 'package:flutter/material.dart';

import '../services/user_access_service.dart';

class AdminUsersScreen extends StatelessWidget {
  final AppUserAccess currentAccess;

  const AdminUsersScreen({
    super.key,
    required this.currentAccess,
  });

  static const _adminRoles = ['viewer', 'editor', 'access_manager', 'admin'];
  static const _accessManagerRoles = ['viewer', 'editor', 'access_manager'];

  @override
  Widget build(BuildContext context) {
    final roles = currentAccess.isAdmin ? _adminRoles : _accessManagerRoles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Access'),
      ),
      body: StreamBuilder<List<AppUserAccess>>(
        stream: UserAccessService.instance.watchUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load users: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const Center(
              child: Text('No users yet'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final user = users[index];
              return _UserAccessTile(
                user: user,
                roles: roles,
                currentAccess: currentAccess,
              );
            },
          );
        },
      ),
    );
  }
}

class _UserAccessTile extends StatefulWidget {
  final AppUserAccess user;
  final List<String> roles;
  final AppUserAccess currentAccess;

  const _UserAccessTile({
    required this.user,
    required this.roles,
    required this.currentAccess,
  });

  @override
  State<_UserAccessTile> createState() => _UserAccessTileState();
}

class _UserAccessTileState extends State<_UserAccessTile> {
  bool _busy = false;

  Future<void> _save({
    String? role,
    bool? approved,
  }) async {
    setState(() => _busy = true);
    try {
      await UserAccessService.instance.updateUser(
        uid: widget.user.uid,
        role: role ?? widget.user.role,
        approved: approved ?? widget.user.approved,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update user: $e'),
          backgroundColor: const Color(0xFFC62828),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final adminProtected = user.role == 'admin';
    final roleOptions = widget.roles.contains(user.role)
        ? widget.roles
        : [...widget.roles, user.role];
    final role = roleOptions.contains(user.role) ? user.role : 'viewer';
    final canUpdateUser = widget.currentAccess.canManageUsers && !adminProtected;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: user.approved
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF3E0),
                  foregroundColor: user.approved
                      ? const Color(0xFF1B5E20)
                      : const Color(0xFFE65100),
                  child: Icon(
                    user.approved
                        ? Icons.verified_user_outlined
                        : Icons.pending_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name.isEmpty ? 'No name' : user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.email.isEmpty ? 'No email' : user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.uid,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_busy)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (adminProtected) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Protected admin account',
                  style: TextStyle(
                    color: Color(0xFF1B5E20),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: role,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                    ),
                    items: roleOptions
                        .map(
                          (role) => DropdownMenuItem(
                            value: role,
                            child: Text(role),
                          ),
                        )
                        .toList(),
                    onChanged: _busy || !canUpdateUser
                        ? null
                        : (value) {
                            if (value != null) _save(role: value);
                          },
                  ),
                ),
                const SizedBox(width: 12),
                Switch(
                  value: user.approved,
                  onChanged:
                      _busy || !canUpdateUser
                          ? null
                          : (value) => _save(approved: value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
