import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../db/database_helper.dart';
import '../models/assessment.dart';
import '../services/sync_service.dart';
import '../services/user_access_service.dart';
import 'admin_users_screen.dart';
import 'form_screen.dart';
import 'detail_screen.dart';
import 'profile_screen.dart';

class ListScreen extends StatefulWidget {
  final AppUserAccess access;

  const ListScreen({super.key, required this.access});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  List<Assessment> _assessments = [];
  bool _loading = true;
  bool _syncBusy = false;
  bool _isOnline = true;
  final _searchCtrl = TextEditingController();
  final _syncService = SyncService();
  late final Stream<List<ConnectivityResult>> _connectivityStream;

  List<Assessment> get _filteredAssessments {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return _assessments;

    return _assessments.where((assessment) {
      final searchableText = [
        assessment.gridNo,
        assessment.centroidNo,
        assessment.date,
        assessment.location,
        assessment.coordsTarget,
        assessment.coordsActual,
        assessment.teamMembers,
        assessment.landCover,
        assessment.treeCrownCover,
        assessment.forestCondition,
        assessment.threats,
        assessment.restorationApproaches.join(' '),
      ].join(' ').toLowerCase();

      return searchableText.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    _loadAssessments();
    _initConnectivity();
    _connectivityStream = Connectivity().onConnectivityChanged;
    _connectivityStream.listen((results) {
      if (!mounted) return;
      setState(() {
        _isOnline = results.contains(ConnectivityResult.mobile) ||
            results.contains(ConnectivityResult.wifi) ||
            results.contains(ConnectivityResult.ethernet);
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _initConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (!mounted) return;
    setState(() {
      _isOnline = result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.ethernet);
    });
  }

  Future<void> _loadAssessments() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final list = await DatabaseHelper.instance.readAll();
    if (!mounted) return;
    setState(() {
      _assessments = list;
      _loading = false;
    });
  }

  Future<void> _deleteAssessment(Assessment assessment) async {
    final deleted = assessment;
    final id = assessment.id;
    if (id == null) return;

    await DatabaseHelper.instance.delete(id);
    if (!mounted) return;
    await _loadAssessments();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Assessment deleted'),
        backgroundColor: const Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: const Color(0xFFF9A825),
          onPressed: () async {
            await DatabaseHelper.instance.create(deleted);
            _loadAssessments();
          },
        ),
      ),
    );
  }

  Future<void> _syncAssessments() async {
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No internet connection. Please connect and try again.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFE65100),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _syncBusy = true);
    try {
      final result = await _syncService.syncAssessments();
      if (!mounted) return;
      if (result == null) return;
      await _loadAssessments();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sync complete: ${result.uploaded} uploaded, ${result.downloaded} downloaded, ${result.deleted} deleted, ${result.skipped} skipped, ${result.total} total',
          ),
        ),
      );
    } on SyncNoInternetException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text(
                'No internet connection. Please connect and try again.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFE65100),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
    } finally {
      if (mounted) setState(() => _syncBusy = false);
    }
  }

  String _getLandCoverIcon(String landCover) {
    switch (landCover) {
      case 'Open Forest':
        return '🌲';
      case 'Brushland/Shrub':
        return '🌿';
      case 'Grassland':
        return '🌾';
      case 'Annual Crop':
        return '🌽';
      case 'Perennial Crop':
        return '🥥';
      case 'Open/Barren':
        return '🏜️';
      case 'Built-up':
        return '🏘️';
      case 'Fishpond':
        return '🐟';
      case 'Inland Water':
        return '💧';
      case 'Monoculture':
        return '🌴';
      case 'Plantation':
        return '🌳';
      default:
        return '📋';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredAssessments = _filteredAssessments;
    final isSearching = _searchCtrl.text.trim().isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Gradient AppBar
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            elevation: 4,
            actions: [
              if (widget.access.canManageUsers)
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminUsersScreen(
                          currentAccess: widget.access,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  tooltip: 'User access',
                ),
              IconButton(
                onPressed: _syncBusy ? null : _syncAssessments,
                icon: _syncBusy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.sync),
                tooltip: 'Sync assessments',
              ),
              PopupMenuButton<String>(
                tooltip: 'Profile',
                offset: const Offset(0, 46),
                color: Colors.white,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onSelected: (value) {
                  if (value == 'profile') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(access: widget.access),
                      ),
                    );
                  }
                  if (value == 'logout') {
                    UserAccessService.instance.signOut();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          color: Color(0xFF1B5E20),
                          size: 22,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Profile',
                          style: TextStyle(
                            color: Color(0xFF143D18),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout,
                          color: Color(0xFFC62828),
                          size: 22,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Logout',
                          style: TextStyle(
                            color: Color(0xFF143D18),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, left: 4),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFF9A825),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.account_circle,
                      color: Color(0xFF1B5E20),
                      size: 30,
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SMP Site Assessment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Biak-Na-Bato National Park (BNBNP)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFF9A825),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1B5E20),
                      Color(0xFF2E7D32),
                      Color(0xFF33691E),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 20,
                      right: 50,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.04),
                        ),
                      ),
                    ),
                    // App branding
                    Positioned(
                      top: 50,
                      left: 16,
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Image.asset(
                              'assets/images/logo/logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SMP',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                ),
                              ),
                              Text(
                                'Site Assessment',
                                style: TextStyle(
                                  color: Color(
                                    0xFFF9A825,
                                  ).withValues(alpha: 0.85),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Stats bar
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.assessment,
                    color: Color(0xFF1B5E20),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isSearching
                        ? '${filteredAssessments.length} of ${_assessments.length} Records'
                        : '${_assessments.length} Record${_assessments.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _isOnline
                          ? const Color(0xFFF1F8E9)
                          : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isOnline ? Icons.cloud_done : Icons.wifi_off,
                          size: 14,
                          color: _isOnline
                              ? const Color(0xFF33691E)
                              : const Color(0xFFE65100),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _isOnline
                                ? const Color(0xFF33691E)
                                : const Color(0xFFE65100),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: TextField(
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search assessments',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF1B5E20),
                  ),
                  suffixIcon: isSearching
                      ? IconButton(
                          onPressed: _searchCtrl.clear,
                          icon: const Icon(Icons.close),
                          tooltip: 'Clear search',
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF1B5E20),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // List body
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
              ),
            )
          else if (_assessments.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.forest,
                      size: 80,
                      color: const Color(0xFF1B5E20).withValues(alpha: 0.25),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No assessments yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to create your first site assessment',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (filteredAssessments.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 72,
                        color: const Color(0xFF1B5E20).withValues(alpha: 0.22),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No matching assessments',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try another grid, location, date, team member, or land cover.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final a = filteredAssessments[index];
                final locationLine = [
                  if (a.location.isNotEmpty) a.location,
                  if (a.centroidNo.isNotEmpty) 'Centroid ${a.centroidNo}',
                ].join(' • ');

                return Dismissible(
                  key: Key('assessment_${a.id}'),
                  direction: widget.access.canDelete
                      ? DismissDirection.endToStart
                      : DismissDirection.none,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete_forever,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text('Delete Assessment'),
                        content: const Text(
                          'Are you sure you want to delete this assessment?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (_) => _deleteAssessment(a),
                  child: GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailScreen(
                            assessment: a,
                            access: widget.access,
                          ),
                        ),
                      );
                      if (!mounted) return;
                      _loadAssessments();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border(
                          left: BorderSide(
                            color: const Color(
                              0xFF1B5E20,
                            ).withValues(alpha: 0.7),
                            width: 4,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F8E9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _getLandCoverIcon(a.landCover),
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        a.gridNo.isNotEmpty
                                            ? 'Grid: ${a.gridNo}'
                                            : 'No Grid No.',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1B5E20),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        locationLine.isNotEmpty
                                            ? locationLine
                                            : 'No location details',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F8E9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    a.date.isNotEmpty ? a.date : '—',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF33691E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                if (a.landCover.isNotEmpty)
                                  _AssessmentTag(label: a.landCover),
                                if (a.forestCondition.isNotEmpty)
                                  _AssessmentTag(label: a.forestCondition),
                                if (a.inventoryRows.isNotEmpty)
                                  _AssessmentTag(
                                    label:
                                        '${a.inventoryRows.length} inventory row${a.inventoryRows.length == 1 ? '' : 's'}',
                                    icon: Icons.table_rows,
                                  ),
                              ],
                            ),
                            if (a.teamMembers.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.group,
                                    size: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      a.teamMembers,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }, childCount: filteredAssessments.length),
            ),
          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: widget.access.canEdit
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FormScreen()),
                );
                if (!mounted) return;
                _loadAssessments();
              },
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('New Assessment'),
              elevation: 4,
            )
          : null,
    );
  }
}

class _AssessmentTag extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _AssessmentTag({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF9A825).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: const Color(0xFF33691E)),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF33691E),
            ),
          ),
        ],
      ),
    );
  }
}
