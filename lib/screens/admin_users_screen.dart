import 'package:flutter/material.dart';

import '../services/user_access_service.dart';

class AdminUsersScreen extends StatefulWidget {
  final AppUserAccess currentAccess;

  const AdminUsersScreen({
    super.key,
    required this.currentAccess,
  });

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  static const _adminRoles = ['viewer', 'editor', 'access_manager', 'admin'];
  static const _accessManagerRoles = ['viewer', 'editor', 'access_manager'];

  late final Stream<List<AppUserAccess>> _usersStream;

  @override
  void initState() {
    super.initState();
    _usersStream = UserAccessService.instance.watchUsers();
  }

  @override
  Widget build(BuildContext context) {
    final roles = widget.currentAccess.isAdmin ? _adminRoles : _accessManagerRoles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Access'),
      ),
      body: StreamBuilder<List<AppUserAccess>>(
        stream: _usersStream,
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
            return RefreshIndicator(
              color: const Color(0xFF1B5E20),
              onRefresh: () async {
                setState(() {
                  _usersStream = UserAccessService.instance.watchUsers();
                });
                await Future.delayed(const Duration(seconds: 1));
              },
              child: const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Center(
                  heightFactor: 10,
                  child: Text('No users yet'),
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFF1B5E20),
            onRefresh: () async {
              setState(() {
                _usersStream = UserAccessService.instance.watchUsers();
              });
              await Future.delayed(const Duration(seconds: 1));
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final user = users[index];
                return _UserAccessTile(
                  user: user,
                  roles: roles,
                  currentAccess: widget.currentAccess,
                );
              },
            ),
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
      if (!mounted) return;
      String msg = 'User updated successfully';
      if (approved != null) {
        msg = approved ? 'User approved successfully!' : 'User rejected successfully!';
      } else if (role != null) {
        msg = 'User role updated to ${_formatRole(role)}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFF1B5E20),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update user: $e'),
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showApprovalModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Review Approval Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set the approval status for ${widget.user.name.isEmpty ? 'this user' : widget.user.name} (${widget.user.email}).',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _save(approved: true);
                  },
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('Approve User'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _save(approved: false);
                  },
                  icon: const Icon(Icons.close, color: Color(0xFFC62828)),
                  label: const Text('Reject User'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC62828),
                    side: const BorderSide(color: Color(0xFFC62828)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                if (widget.currentAccess.canManageUsers && widget.user.role != 'admin') ...[
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDelete(context);
                    },
                    icon: const Icon(Icons.delete_forever, color: Colors.white),
                    label: const Text('Delete User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC62828),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete User Account'),
        content: Text(
          'Are you sure you want to permanently delete the user account for ${widget.user.name.isEmpty ? 'this user' : widget.user.name}?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFC62828),
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _busy = true);
      try {
        await UserAccessService.instance.deleteUser(widget.user.uid);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('User deleted successfully!'),
            backgroundColor: Color(0xFF1B5E20),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Unable to delete user: $e'),
            backgroundColor: const Color(0xFFC62828),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  String _formatRole(String role) {
    switch (role) {
      case 'access_manager':
        return 'Access Manager';
      case 'admin':
        return 'Admin';
      case 'editor':
        return 'Editor';
      case 'viewer':
        return 'Viewer';
      default:
        return role;
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.name.isEmpty ? 'No name' : user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (!user.approved)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE65100),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                        ],
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
                  )
                else if (widget.currentAccess.canManageUsers && !adminProtected)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFC62828),
                    ),
                    tooltip: 'Delete User',
                    onPressed: () => _confirmDelete(context),
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
                    isExpanded: true,
                    initialValue: role,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: roleOptions
                        .map(
                          (role) => DropdownMenuItem(
                            value: role,
                            child: Text(
                              _formatRole(role),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
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
                ElevatedButton.icon(
                  onPressed: _busy || !canUpdateUser
                      ? null
                      : () => _showApprovalModal(context),
                  icon: Icon(
                    user.approved ? Icons.verified : Icons.pending,
                    size: 16,
                  ),
                  label: Text(user.approved ? 'Approved' : 'Review'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: user.approved
                        ? const Color(0xFF1B5E20)
                        : const Color(0xFFE65100),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
