import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../db/database_helper.dart';
import '../models/assessment.dart';

class BackupImportResult {
  final int imported;
  final int skipped;

  const BackupImportResult({
    required this.imported,
    required this.skipped,
  });
}

class BackupService {
  static const _schemaVersion = 1;

  Future<void> exportBackup() async {
    final assessments = await DatabaseHelper.instance.readAll();
    final backup = {
      'app': 'smp_site_assessment',
      'schemaVersion': _schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'assessments': assessments.map(_toBackupMap).toList(),
    };

    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file = File(
      p.join(directory.path, 'site_assessment_backup_$timestamp.json'),
    );
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(backup));

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Site assessment backup',
      text: 'Site assessment backup exported from SMP Site Assessment.',
    );
  }

  Future<BackupImportResult?> importBackup() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: false,
    );
    final path = picked?.files.single.path;
    if (path == null) return null;

    final raw = await File(path).readAsString();
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid backup file.');
    }

    final records = decoded['assessments'];
    if (records is! List) {
      throw const FormatException('Backup file has no assessments list.');
    }

    final existing = await DatabaseHelper.instance.readAll();
    final fingerprints = existing
        .map((assessment) => _fingerprint(_toBackupMap(assessment)))
        .toSet();
    final incomingFingerprints = <String>{};
    var imported = 0;
    var skipped = 0;

    for (final record in records) {
      if (record is! Map) {
        skipped++;
        continue;
      }

      final map = Map<String, dynamic>.from(record);
      final fingerprint = _fingerprint(map);
      if (fingerprints.contains(fingerprint) ||
          incomingFingerprints.contains(fingerprint)) {
        skipped++;
        continue;
      }

      await DatabaseHelper.instance.create(_fromBackupMap(map));
      fingerprints.add(fingerprint);
      incomingFingerprints.add(fingerprint);
      imported++;
    }

    return BackupImportResult(imported: imported, skipped: skipped);
  }

  Map<String, dynamic> _toBackupMap(Assessment assessment) {
    final map = Map<String, dynamic>.from(assessment.toMap())..remove('id');
    map['inventory'] = assessment.inventoryRows.map((row) => row.toMap()).toList();
    map.remove('inventoryJson');
    return map;
  }

  Assessment _fromBackupMap(Map<String, dynamic> map) {
    final assessment = Assessment.fromMap({
      'gridNo': map['gridNo'] ?? '',
      'centroidNo': map['centroidNo'] ?? '',
      'elevation': map['elevation'] ?? '',
      'date': map['date'] ?? '',
      'location': map['location'] ?? '',
      'coordsTarget': map['coordsTarget'] ?? '',
      'coordsActual': map['coordsActual'] ?? '',
      'teamMembers': map['teamMembers'] ?? '',
      'landCover': map['landCover'] ?? '',
      'treeCrownCover': map['treeCrownCover'] ?? '',
      'forestCondition': map['forestCondition'] ?? '',
      'forestConditionNotes': map['forestConditionNotes'] ?? '',
      'forestLitterGroundCover': map['forestLitterGroundCover'] ?? '',
      'forestLitterAvgDepth': map['forestLitterAvgDepth'] ?? '',
      'threats': map['threats'] ?? '',
      'inventoryJson': map['inventoryJson'] ?? '[]',
      'restorationApproach': map['restorationApproach'] ?? '',
    });

    final inventory = map['inventory'];
    if (inventory is List) {
      assessment.setInventoryRows(
        inventory
            .whereType<Map>()
            .map((row) => InventoryRow.fromMap(Map<String, dynamic>.from(row)))
            .toList(),
      );
    }

    return assessment;
  }

  String _fingerprint(Map<String, dynamic> map) {
    return jsonEncode(_normalize(map));
  }

  Object? _normalize(Object? value) {
    if (value is Map) {
    final sortedKeys = value.keys.map((key) => key.toString()).toList()
      ..sort();
      return {
        for (final key in sortedKeys)
          if (key != 'id') key: _normalize(value[key]),
      };
    }
    if (value is List) {
      return value.map(_normalize).toList();
    }
    return value ?? '';
  }
}
