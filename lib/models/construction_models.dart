class ConstructionActivity {
  final String key;  // Format: "PhaseName::GroupName::ActivityName"
  final String name;
  final bool isCustom;
  bool isSelected; // used in add_project for scope selection

  ConstructionActivity({
    required this.key,
    required this.name,
    this.isCustom = false,
    this.isSelected = false,
  });
}

class ConstructionActivityGroup {
  final String name;
  final List<ConstructionActivity> activities;
  ConstructionActivityGroup({required this.name, required this.activities});
}

class ConstructionPhase {
  final String name;
  final bool isCustom;
  final List<ConstructionActivity> activities;
  final List<ConstructionActivityGroup> groups;
  bool isExpanded;

  ConstructionPhase({
    required this.name,
    this.isCustom = false,
    List<ConstructionActivity>? activities,
    List<ConstructionActivityGroup>? groups,
    this.isExpanded = false,
  })  : activities = activities ?? [],
        groups = groups ?? [];

  List<ConstructionActivity> get allActivities => [
        ...activities,
        ...groups.expand((g) => g.activities),
      ];

  int get selectedCount => allActivities.where((a) => a.isSelected).length;
  int get totalCount    => allActivities.length;
}

// ── Helpers ────────────────────────────────────────────────────────────────

ConstructionActivity _a(String phase, String group, String name) =>
    ConstructionActivity(key: '$phase::$group::$name', name: name);

ConstructionActivityGroup _g(String phase, String grp, List<String> names) =>
    ConstructionActivityGroup(
      name: grp,
      activities: names.map((n) => _a(phase, grp, n)).toList(),
    );

// ── Static phase catalogue ─────────────────────────────────────────────────

List<ConstructionPhase> buildDefaultPhases() => [
      ConstructionPhase(name: 'Pre-Construction', activities: [
        _a('Pre-Construction', 'General', 'Site Survey'),
        _a('Pre-Construction', 'General', 'Soil Testing'),
        _a('Pre-Construction', 'General', 'Architectural Planning'),
        _a('Pre-Construction', 'General', 'Structural Design'),
        _a('Pre-Construction', 'General', 'Approval Processing'),
        _a('Pre-Construction', 'General', 'Budget Estimation'),
      ]),
      ConstructionPhase(name: 'Site Preparation', activities: [
        _a('Site Preparation', 'General', 'Site Cleaning'),
        _a('Site Preparation', 'General', 'Temporary Fencing'),
        _a('Site Preparation', 'General', 'Excavation Marking'),
        _a('Site Preparation', 'General', 'Utility Setup'),
        _a('Site Preparation', 'General', 'Leveling'),
        _a('Site Preparation', 'General', 'Excavation'),
      ]),
      ConstructionPhase(name: 'Foundation', activities: [
        _a('Foundation', 'General', 'Footing Excavation'),
        _a('Foundation', 'General', 'PCC'),
        _a('Foundation', 'General', 'Footing Reinforcement'),
        _a('Foundation', 'General', 'Footing Casting'),
        _a('Foundation', 'General', 'Foundation Wall'),
        _a('Foundation', 'General', 'Waterproofing'),
      ]),
      ConstructionPhase(name: 'Plinth', activities: [
        _a('Plinth', 'General', 'Plinth Beam Reinforcement'),
        _a('Plinth', 'General', 'Plinth Beam Casting'),
        _a('Plinth', 'General', 'Backfilling'),
        _a('Plinth', 'General', 'Compaction'),
        _a('Plinth', 'General', 'DPC Layer'),
      ]),
      ConstructionPhase(name: 'Superstructure', activities: [
        _a('Superstructure', 'General', 'Column Reinforcement'),
        _a('Superstructure', 'General', 'Column Shuttering'),
        _a('Superstructure', 'General', 'Column Casting'),
        _a('Superstructure', 'General', 'Beam Reinforcement'),
        _a('Superstructure', 'General', 'Beam Casting'),
        _a('Superstructure', 'General', 'Slab Shuttering'),
        _a('Superstructure', 'General', 'Slab Reinforcement'),
        _a('Superstructure', 'General', 'Slab Casting'),
        _a('Superstructure', 'General', 'Curing'),
      ]),
      ConstructionPhase(name: 'Masonry', activities: [
        _a('Masonry', 'General', 'External Wall Blockwork'),
        _a('Masonry', 'General', 'Internal Wall Blockwork'),
        _a('Masonry', 'General', 'Lintel Casting'),
        _a('Masonry', 'General', 'Door Opening'),
      ]),
      ConstructionPhase(name: 'MEP', groups: [
        _g('MEP', 'Electrical', ['Conduit Laying', 'Switch Box Fixing', 'Wiring', 'DB Installation']),
        _g('MEP', 'Plumbing',   ['Pipe Laying', 'Drainage Line', 'Water Line Testing']),
      ]),
      ConstructionPhase(name: 'Plastering', activities: [
        _a('Plastering', 'General', 'Internal Plaster'),
        _a('Plastering', 'General', 'External Plaster'),
        _a('Plastering', 'General', 'Ceiling Plaster'),
        _a('Plastering', 'General', 'Surface Finishing'),
      ]),
      ConstructionPhase(name: 'Finishing', activities: [
        _a('Finishing', 'General', 'Putty'),
        _a('Finishing', 'General', 'Primer'),
        _a('Finishing', 'General', 'Painting'),
        _a('Finishing', 'General', 'Tile Installation'),
        _a('Finishing', 'General', 'False Ceiling'),
      ]),
      ConstructionPhase(name: 'Fixtures', activities: [
        _a('Fixtures', 'General', 'Door Installation'),
        _a('Fixtures', 'General', 'Window Installation'),
        _a('Fixtures', 'General', 'Sanitary Fixtures'),
        _a('Fixtures', 'General', 'Electrical Fixtures'),
      ]),
      ConstructionPhase(name: 'Handover', activities: [
        _a('Handover', 'General', 'Final Inspection'),
        _a('Handover', 'General', 'Snag Rectification'),
        _a('Handover', 'General', 'Cleaning'),
        _a('Handover', 'General', 'Documentation'),
        _a('Handover', 'General', 'Client Handover'),
      ]),
    ];
