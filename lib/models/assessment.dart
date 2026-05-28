import 'dart:convert';

class InventoryRow {
  String species;
  String dbh;
  String mh;
  String th;
  String remarks;

  InventoryRow({
    this.species = '',
    this.dbh = '',
    this.mh = '',
    this.th = '',
    this.remarks = '',
  });

  Map<String, dynamic> toMap() => {
        'species': species,
        'dbh': dbh,
        'mh': mh,
        'th': th,
        'remarks': remarks,
      };

  factory InventoryRow.fromMap(Map<String, dynamic> map) => InventoryRow(
        species: map['species'] ?? '',
        dbh: map['dbh'] ?? '',
        mh: map['mh'] ?? '',
        th: map['th'] ?? '',
        remarks: map['remarks'] ?? '',
      );
}

class Assessment {
  int? id;

  /// The Firestore document ID for this record, or null if not yet synced.
  /// Stored locally in SQLite; never written to Firestore itself.
  String? firestoreId;

  // Header fields
  String gridNo;
  String centroidNo;
  String elevation;
  String date;
  String location;
  String coordsTarget;
  String coordsActual;
  String teamMembers;

  // Section B – Land Cover (radio, one of 9 options)
  String landCover;

  // Section C – Tree Crown Cover (radio, one of 3)
  String treeCrownCover;

  // Section D – Forest Condition (radio + optional notes per choice)
  String forestCondition;
  String forestConditionNotes;

  // Section E – Forest Litter (fillable)
  String forestLitterGroundCover;
  String forestLitterAvgDepth;

  // Section F – Threats
  String threats;

  // Section G – Inventory rows (JSON-encoded list)
  String inventoryJson;

  // Section H – Recommended Restoration Approach (radio, one of 6)
  String restorationApproach;
  String restorationRationale;

  Assessment({
    this.id,
    this.firestoreId,
    this.gridNo = '',
    this.centroidNo = '',
    this.elevation = '',
    this.date = '',
    this.location = '',
    this.coordsTarget = '',
    this.coordsActual = '',
    this.teamMembers = '',
    this.landCover = '',
    this.treeCrownCover = '',
    this.forestCondition = '',
    this.forestConditionNotes = '',
    this.forestLitterGroundCover = '',
    this.forestLitterAvgDepth = '',
    this.threats = '',
    this.inventoryJson = '[]',
    this.restorationApproach = '',
    this.restorationRationale = '',
  });

  List<InventoryRow> get inventoryRows {
    final decoded = jsonDecode(inventoryJson) as List;
    return decoded.map((e) => InventoryRow.fromMap(e as Map<String, dynamic>)).toList();
  }

  void setInventoryRows(List<InventoryRow> rows) {
    inventoryJson = jsonEncode(rows.map((r) => r.toMap()).toList());
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (firestoreId != null) 'firestoreId': firestoreId,
        'gridNo': gridNo,
        'centroidNo': centroidNo,
        'elevation': elevation,
        'date': date,
        'location': location,
        'coordsTarget': coordsTarget,
        'coordsActual': coordsActual,
        'teamMembers': teamMembers,
        'landCover': landCover,
        'treeCrownCover': treeCrownCover,
        'forestCondition': forestCondition,
        'forestConditionNotes': forestConditionNotes,
        'forestLitterGroundCover': forestLitterGroundCover,
        'forestLitterAvgDepth': forestLitterAvgDepth,
        'threats': threats,
        'inventoryJson': inventoryJson,
        'restorationApproach': restorationApproach,
        'restorationRationale': restorationRationale,
      };

  factory Assessment.fromMap(Map<String, dynamic> map) => Assessment(
        id: map['id'] as int?,
        firestoreId: map['firestoreId'] as String?,
        gridNo: map['gridNo'] ?? '',
        centroidNo: map['centroidNo'] ?? '',
        elevation: map['elevation'] ?? '',
        date: map['date'] ?? '',
        location: map['location'] ?? '',
        coordsTarget: map['coordsTarget'] ?? '',
        coordsActual: map['coordsActual'] ?? '',
        teamMembers: map['teamMembers'] ?? '',
        landCover: map['landCover'] ?? '',
        treeCrownCover: map['treeCrownCover'] ?? '',
        forestCondition: map['forestCondition'] ?? '',
        forestConditionNotes: map['forestConditionNotes'] ?? '',
        forestLitterGroundCover: map['forestLitterGroundCover'] ?? '',
        forestLitterAvgDepth: map['forestLitterAvgDepth'] ?? '',
        threats: map['threats'] ?? '',
        inventoryJson: map['inventoryJson'] ?? '[]',
        restorationApproach: map['restorationApproach'] ?? '',
        restorationRationale: map['restorationRationale'] ?? '',
      );

  Assessment copyWith({
    int? id,
    String? firestoreId,
    String? gridNo,
    String? centroidNo,
    String? elevation,
    String? date,
    String? location,
    String? coordsTarget,
    String? coordsActual,
    String? teamMembers,
    String? landCover,
    String? treeCrownCover,
    String? forestCondition,
    String? forestConditionNotes,
    String? forestLitterGroundCover,
    String? forestLitterAvgDepth,
    String? threats,
    String? inventoryJson,
    String? restorationApproach,
    String? restorationRationale,
  }) =>
      Assessment(
        id: id ?? this.id,
        firestoreId: firestoreId ?? this.firestoreId,
        gridNo: gridNo ?? this.gridNo,
        centroidNo: centroidNo ?? this.centroidNo,
        elevation: elevation ?? this.elevation,
        date: date ?? this.date,
        location: location ?? this.location,
        coordsTarget: coordsTarget ?? this.coordsTarget,
        coordsActual: coordsActual ?? this.coordsActual,
        teamMembers: teamMembers ?? this.teamMembers,
        landCover: landCover ?? this.landCover,
        treeCrownCover: treeCrownCover ?? this.treeCrownCover,
        forestCondition: forestCondition ?? this.forestCondition,
        forestConditionNotes: forestConditionNotes ?? this.forestConditionNotes,
        forestLitterGroundCover: forestLitterGroundCover ?? this.forestLitterGroundCover,
        forestLitterAvgDepth: forestLitterAvgDepth ?? this.forestLitterAvgDepth,
        threats: threats ?? this.threats,
        inventoryJson: inventoryJson ?? this.inventoryJson,
        restorationApproach: restorationApproach ?? this.restorationApproach,
        restorationRationale: restorationRationale ?? this.restorationRationale,
      );
}
