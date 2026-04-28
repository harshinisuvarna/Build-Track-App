enum EntryType { material, labour, equipment }
enum EntryStatus { pending, approved, rejected }
class Entry {
  Entry({
    required this.id,
    required this.type,
    required this.projectId,
    required this.createdBy,
    this.status = EntryStatus.pending,
    this.approvedBy,
    this.approvedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // ── Core fields ───────────────────────────────────────────────────────────

  final String id;
  final EntryType type;
  final String projectId;
  final String createdBy;
  final DateTime createdAt;

  // ── Status fields (mutable) ───────────────────────────────────────────────

  EntryStatus status;
  String? approvedBy;
  DateTime? approvedAt;

  // ── Convenience getters ───────────────────────────────────────────────────

  bool get isPending  => status == EntryStatus.pending;
  bool get isApproved => status == EntryStatus.approved;
  bool get isRejected => status == EntryStatus.rejected;

  /// Human-readable type label (e.g. 'Material').
  String get typeLabel {
    switch (type) {
      case EntryType.material:  return 'Material';
      case EntryType.labour:    return 'Labour';
      case EntryType.equipment: return 'Equipment';
    }
  }

  /// Human-readable status label (e.g. 'Pending').
  String get statusLabel {
    switch (status) {
      case EntryStatus.pending:  return 'Pending';
      case EntryStatus.approved: return 'Approved';
      case EntryStatus.rejected: return 'Rejected';
    }
  }

  // ── Serialisation ─────────────────────────────────────────────────────────

  /// Constructs an [Entry] from a plain [Map] (e.g. from local storage / API).
  factory Entry.fromMap(Map<String, dynamic> map) {
    return Entry(
      id:          map['id'] as String,
      type:        EntryType.values.firstWhere(
                     (e) => e.name == map['type'],
                     orElse: () => EntryType.material,
                   ),
      projectId:   map['projectId'] as String,
      createdBy:   map['createdBy'] as String,
      status:      EntryStatus.values.firstWhere(
                     (e) => e.name == map['status'],
                     orElse: () => EntryStatus.pending,
                   ),
      approvedBy:  map['approvedBy'] as String?,
      approvedAt:  map['approvedAt'] != null
                     ? DateTime.parse(map['approvedAt'] as String)
                     : null,
      createdAt:   map['createdAt'] != null
                     ? DateTime.parse(map['createdAt'] as String)
                     : null,
    );
  }

  /// Converts this [Entry] to a plain [Map] (e.g. for local storage / API).
  Map<String, dynamic> toMap() {
    return {
      'id':         id,
      'type':       type.name,
      'projectId':  projectId,
      'createdBy':  createdBy,
      'status':     status.name,
      'createdAt':  createdAt.toIso8601String(),
      if (approvedBy != null) 'approvedBy': approvedBy,
      if (approvedAt != null) 'approvedAt': approvedAt!.toIso8601String(),
    };
  }

  /// Returns a copy with updated fields (immutable update pattern).
  Entry copyWith({
    EntryStatus? status,
    String? approvedBy,
    DateTime? approvedAt,
  }) {
    return Entry(
      id:         id,
      type:       type,
      projectId:  projectId,
      createdBy:  createdBy,
      createdAt:  createdAt,
      status:     status     ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }

  @override
  String toString() =>
      'Entry(id: $id, type: $typeLabel, status: $statusLabel, project: $projectId)';
}
