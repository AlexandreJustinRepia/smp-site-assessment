import 'package:flutter/material.dart';

import '../services/user_access_service.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  static const _roles = ['viewer', 'editor', 'admin'];

  @override
  Widget build(BuildContext context) {
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
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final user = users[index];
              return _UserAccessTile(user: user, roles: _roles);
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

  const _UserAccessTile({
    required this.user,
    required this.roles,
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
    final role = widget.roles.contains(user.role) ? user.role : 'viewer';

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
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                    ),
                    items: widget.roles
                        .map(
                          (role) => DropdownMenuItem(
                            value: role,
                            child: Text(role),
                          ),
                        )
                        .toList(),
                    onChanged: _busy
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
                      _busy ? null : (value) => _save(approved: value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
