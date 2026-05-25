import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/assessment.dart';
import '../services/backup_service.dart';
import 'form_screen.dart';
import 'detail_screen.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  List<Assessment> _assessments = [];
  bool _loading = true;
  bool _backupBusy = false;
  final _backupService = BackupService();

  @override
  void initState() {
    super.initState();
    _loadAssessments();
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

  Future<void> _deleteAssessment(int id, int index) async {
    final deleted = _assessments[index];
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

  Future<void> _exportBackup() async {
    setState(() => _backupBusy = true);
    try {
      await _backupService.exportBackup();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Backup exported with ${_assessments.length} record${_assessments.length == 1 ? '' : 's'}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<void> _importBackup() async {
    setState(() => _backupBusy = true);
    try {
      final result = await _backupService.importBackup();
      if (!mounted) return;
      if (result == null) {
        return;
      }
      await _loadAssessments();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported ${result.imported}; skipped ${result.skipped} duplicate${result.skipped == 1 ? '' : 's'}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _backupBusy = false);
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
              IconButton(
                onPressed: _backupBusy ? null : _importBackup,
                icon: const Icon(Icons.upload_file),
                tooltip: 'Import backup',
              ),
              IconButton(
                onPressed: _backupBusy ? null : _exportBackup,
                icon: const Icon(Icons.ios_share),
                tooltip: 'Export backup',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Site Assessment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Biak-Na-Bato National Park',
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
                    // DENR / NGP branding
                    Positioned(
                      top: 50,
                      left: 16,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.eco,
                              color: Color(0xFFF9A825),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DENR',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                ),
                              ),
                              Text(
                                'National Greening Program',
                                style: TextStyle(
                                  color: Color(0xFFF9A825).withValues(alpha: 0.85),
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
                  const Icon(Icons.assessment, color: Color(0xFF1B5E20), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${_assessments.length} Record${_assessments.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8E9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off, size: 14, color: Color(0xFF33691E)),
                        SizedBox(width: 4),
                        Text(
                          'Offline',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF33691E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                    Icon(Icons.forest, size: 80, color: const Color(0xFF1B5E20).withValues(alpha: 0.25)),
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
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final a = _assessments[index];
                  return Dismissible(
                    key: Key('assessment_${a.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete_forever, color: Colors.white, size: 28),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Text('Delete Assessment'),
                          content: const Text('Are you sure you want to delete this assessment?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (_) => _deleteAssessment(a.id!, index),
                    child: GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DetailScreen(assessment: a)),
                        );
                        if (!mounted) return;
                        _loadAssessments();
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                            left: BorderSide(
                              color: const Color(0xFF1B5E20).withValues(alpha: 0.7),
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
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _getLandCoverIcon(a.landCover),
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          a.gridNo.isNotEmpty ? 'Grid: ${a.gridNo}' : 'No Grid No.',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1B5E20),
                                          ),
                                        ),
                                        if (a.location.isNotEmpty)
                                          Text(
                                            a.location,
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
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                              if (a.landCover.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9A825).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    a.landCover,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF33691E),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: _assessments.length,
              ),
            ),
          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
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
      ),
    );
  }
}
