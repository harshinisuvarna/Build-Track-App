class ConstructionActivity {
  final String key; // Format: "PhaseName::GroupName::ActivityName"
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
  bool isSelected;

  ConstructionPhase({
    required this.name,
    this.isCustom = false,
    List<ConstructionActivity>? activities,
    List<ConstructionActivityGroup>? groups,
    this.isExpanded = false,
    this.isSelected = false,
  }) : activities = activities ?? [],
       groups = groups ?? [];

  List<ConstructionActivity> get allActivities => [
    ...activities,
    ...groups.expand((g) => g.activities),
  ];

  int get selectedCount => allActivities.where((a) => a.isSelected).length;
  int get totalCount => allActivities.length;
}

// ── Helpers ────────────────────────────────────────────────────────────────

ConstructionActivity _a(String phase, String group, String name) =>
    ConstructionActivity(key: '$phase::$group::$name', name: name);

// ── Static phase catalogue ─────────────────────────────────────────────────

List<ConstructionPhase> buildDefaultPhases() => [
  // ── 1. PRE-CONSTRUCTION ───────────────────────────────────────────────
  ConstructionPhase(
    name: 'Pre-Construction',
    activities: [
      _a('Pre-Construction', 'General', 'Surveying'),
      _a('Pre-Construction', 'General', 'Soil Testing'),
      _a('Pre-Construction', 'General', 'Architectural Designing'),
      _a('Pre-Construction', 'General', 'Structural Designing'),
      _a('Pre-Construction', 'General', 'Planning'),
      _a('Pre-Construction', 'General', 'Cost Estimation'),
      _a('Pre-Construction', 'General', 'BOQ Preparation'),
      _a('Pre-Construction', 'General', 'Approvals & Permissions'),
      _a('Pre-Construction', 'General', 'Site Marking'),
      _a('Pre-Construction', 'General', 'Temporary Site Setup'),
    ],
  ),

  // ── 2. SITE PREPARATION ───────────────────────────────────────────────
  ConstructionPhase(
    name: 'Site Preparation',
    activities: [
      _a('Site Preparation', 'General', 'Site Clearing'),
      _a('Site Preparation', 'General', 'Excavation'),
      _a('Site Preparation', 'General', 'Soil Levelling'),
      _a('Site Preparation', 'General', 'Site Grading'),
      _a('Site Preparation', 'General', 'Temporary Power Setup'),
      _a('Site Preparation', 'General', 'Temporary Water Setup'),
      _a('Site Preparation', 'General', 'Labour Shed Setup'),
    ],
  ),

  // ── 3. FOUNDATION & PLINTH WORK ──────────────────────────────────────
  ConstructionPhase(
    name: 'Foundation & Plinth Work',
    activities: [
      _a('Foundation & Plinth Work', 'General', 'Grid Line Marking'),
      _a('Foundation & Plinth Work', 'General', 'Footing Excavation'),
      _a('Foundation & Plinth Work', 'General', 'Soil Levelling'),
      _a('Foundation & Plinth Work', 'General', 'PCC Laying'),
      _a('Foundation & Plinth Work', 'General', 'Column Center Marking'),
      _a('Foundation & Plinth Work', 'General', 'Reinforcement - Footing'),
      _a('Foundation & Plinth Work', 'General', 'Shuttering - Footing'),
      _a('Foundation & Plinth Work', 'General', 'Reinforcement - Column'),
      _a('Foundation & Plinth Work', 'General', 'Concrete Pouring - Footing'),
      _a('Foundation & Plinth Work', 'General', 'Concrete Vibration - Footing'),
      _a('Foundation & Plinth Work', 'General', 'Deshuttering - Footing'),
      _a('Foundation & Plinth Work', 'General', 'Curing - Footing'),
      _a('Foundation & Plinth Work', 'General', 'Column Starter Preparation'),
      _a('Foundation & Plinth Work', 'General', 'Shuttering - Column'),
      _a(
        'Foundation & Plinth Work',
        'General',
        'Vertical Alignment Check (Plumb Bob)',
      ),
      _a(
        'Foundation & Plinth Work',
        'General',
        'Cover Block Placement - Column',
      ),
      _a('Foundation & Plinth Work', 'General', 'Concrete Pouring - Column'),
      _a('Foundation & Plinth Work', 'General', 'Concrete Vibration - Column'),
      _a(
        'Foundation & Plinth Work',
        'General',
        'Column Casting up to Plinth Beam Level',
      ),
      _a('Foundation & Plinth Work', 'General', 'Deshuttering - Column'),
      _a('Foundation & Plinth Work', 'General', 'Curing - Column'),
      _a(
        'Foundation & Plinth Work',
        'General',
        'Soil Backfilling up to Ground Level',
      ),
      _a('Foundation & Plinth Work', 'General', 'Watering & Compaction - Soil'),
      _a(
        'Foundation & Plinth Work',
        'General',
        'PCC Preparation - Plinth Beam',
      ),
      _a('Foundation & Plinth Work', 'General', 'Reinforcement - Plinth Beam'),
      _a('Foundation & Plinth Work', 'General', 'Shuttering - Plinth Beam'),
      _a(
        'Foundation & Plinth Work',
        'General',
        'Concrete Pouring - Plinth Beam',
      ),
      _a(
        'Foundation & Plinth Work',
        'General',
        'Concrete Vibration - Plinth Beam',
      ),
      _a('Foundation & Plinth Work', 'General', 'Deshuttering - Plinth Beam'),
      _a(
        'Foundation & Plinth Work',
        'General',
        'Soil Backfilling up to Plinth Level',
      ),
      _a(
        'Foundation & Plinth Work',
        'General',
        'Compaction using Earth Rammer',
      ),
    ],
  ),

  // ── 4. FLOOR CONSTRUCTION ─────────────────────────────────────────────
  ConstructionPhase(
    name: 'Floor Construction',
    activities: [
      _a('Floor Construction', 'General', 'Column Starter Preparation'),
      _a('Floor Construction', 'General', 'Reinforcement - Column'),
      _a('Floor Construction', 'General', 'Shuttering - Column'),
      _a('Floor Construction', 'General', 'Cover Block Placement - Column'),
      _a(
        'Floor Construction',
        'General',
        'Vertical Alignment Check (Plumb Bob)',
      ),
      _a('Floor Construction', 'General', 'Shuttering Oil Application'),
      _a('Floor Construction', 'General', 'Concrete Pouring - Column'),
      _a('Floor Construction', 'General', 'Concrete Vibration - Column'),
      _a('Floor Construction', 'General', 'Deshuttering - Column'),
      _a('Floor Construction', 'General', 'Curing - Column'),
      _a('Floor Construction', 'General', 'Wall Layout Marking'),
      _a('Floor Construction', 'General', 'Wall Construction'),
      _a('Floor Construction', 'General', 'Door Frame Installation'),
      _a('Floor Construction', 'General', 'Window Frame Installation'),
      _a('Floor Construction', 'General', 'Lintel Reinforcement'),
      _a('Floor Construction', 'General', 'Concrete Pouring - Lintel'),
      _a('Floor Construction', 'General', 'Beam Bottom Support using Props'),
      _a('Floor Construction', 'General', 'Shuttering - Beam'),
      _a('Floor Construction', 'General', 'Reinforcement - Beam'),
      _a('Floor Construction', 'General', 'Reinforcement - Slab'),
      _a('Floor Construction', 'General', 'Electrical Conduit Installation'),
      _a('Floor Construction', 'General', 'Plumbing Pipe Installation'),
      _a('Floor Construction', 'General', 'Slab Opening / Cutout Provision'),
      _a('Floor Construction', 'General', 'Crank Bar Preparation'),
      _a('Floor Construction', 'General', 'Cover Block Placement - Slab'),
      _a('Floor Construction', 'General', 'Concrete Pouring - Slab'),
      _a('Floor Construction', 'General', 'Concrete Vibration - Slab'),
      _a('Floor Construction', 'General', 'Levelling & Finishing - Slab'),
      _a('Floor Construction', 'General', 'Deshuttering - Slab'),
      _a('Floor Construction', 'General', 'Curing - Slab'),
    ],
  ),

  // ── 5. FINISHING WORK ─────────────────────────────────────────────────
  ConstructionPhase(
    name: 'Finishing Work',
    activities: [
      _a('Finishing Work', 'General', 'Internal Wall Plastering'),
      _a('Finishing Work', 'General', 'External Wall Plastering'),
      _a('Finishing Work', 'General', 'Ceiling Plastering'),
      _a('Finishing Work', 'General', 'Putty Application'),
      _a('Finishing Work', 'General', 'Primer Application'),
      _a('Finishing Work', 'General', 'Internal Painting'),
      _a('Finishing Work', 'General', 'External Painting'),
      _a('Finishing Work', 'General', 'Waterproofing - Bathroom'),
      _a('Finishing Work', 'General', 'Waterproofing - Terrace'),
      _a('Finishing Work', 'General', 'Tile Installation - Floor'),
      _a('Finishing Work', 'General', 'Tile Installation - Wall'),
      _a('Finishing Work', 'General', 'Granite / Marble Installation'),
      _a('Finishing Work', 'General', 'Bathroom Fittings Installation'),
      _a('Finishing Work', 'General', 'Sanitary Fittings Installation'),
      _a('Finishing Work', 'General', 'Electrical Conduit Finishing'),
      _a('Finishing Work', 'General', 'Electrical Wiring'),
      _a('Finishing Work', 'General', 'Switch & Socket Installation'),
      _a('Finishing Work', 'General', 'Light Fixture Installation'),
      _a('Finishing Work', 'General', 'Plumbing Fixture Installation'),
      _a('Finishing Work', 'General', 'Kitchen Sink Installation'),
      _a('Finishing Work', 'General', 'Door Installation'),
      _a('Finishing Work', 'General', 'Window Installation'),
      _a('Finishing Work', 'General', 'Glass Installation'),
      _a('Finishing Work', 'General', 'Railing Installation'),
      _a('Finishing Work', 'General', 'False Ceiling Installation'),
      _a('Finishing Work', 'General', 'Carpentry Work'),
      _a('Finishing Work', 'General', 'Modular Kitchen Installation'),
      _a('Finishing Work', 'General', 'Wardrobe Installation'),
      _a('Finishing Work', 'General', 'Interior Works'),
      _a('Finishing Work', 'General', 'Cleaning & Site Finishing'),
    ],
  ),

  // ── 6. EXTERNAL WORKS ─────────────────────────────────────────────────
  ConstructionPhase(
    name: 'External Works',
    activities: [
      _a('External Works', 'General', 'Compound Wall Construction'),
      _a('External Works', 'General', 'Gate Installation'),
      _a('External Works', 'General', 'Paving Work'),
      _a('External Works', 'General', 'Drainage Work'),
      _a('External Works', 'General', 'Septic Tank Construction'),
      _a('External Works', 'General', 'Sump Construction'),
      _a('External Works', 'General', 'Rainwater Harvesting'),
      _a('External Works', 'General', 'Landscaping'),
      _a('External Works', 'General', 'External Electrical Work'),
      _a('External Works', 'General', 'External Plumbing Work'),
    ],
  ),

  // ── 7. MATERIAL MASTER ────────────────────────────────────────────────
  ConstructionPhase(
    name: 'Material Master',
    activities: [
      _a('Material Master', 'General', 'Cement'),
      _a('Material Master', 'General', 'Steel'),
      _a('Material Master', 'General', 'Sand'),
      _a('Material Master', 'General', 'Aggregate'),
      _a('Material Master', 'General', 'Brick'),
      _a('Material Master', 'General', 'Blocks'),
      _a('Material Master', 'General', 'Jelly'),
      _a('Material Master', 'General', 'Tiles'),
      _a('Material Master', 'General', 'Paint'),
      _a('Material Master', 'General', 'Putty'),
      _a('Material Master', 'General', 'Primer'),
      _a('Material Master', 'General', 'Electrical Materials'),
      _a('Material Master', 'General', 'Plumbing Materials'),
      _a('Material Master', 'General', 'Pipes'),
      _a('Material Master', 'General', 'Sanitary Items'),
      _a('Material Master', 'General', 'Doors'),
      _a('Material Master', 'General', 'Windows'),
      _a('Material Master', 'General', 'Glass'),
      _a('Material Master', 'General', 'Granite'),
      _a('Material Master', 'General', 'Marble'),
      _a('Material Master', 'General', 'Waterproofing Materials'),
    ],
  ),

  // ── 8. LABOUR MASTER ──────────────────────────────────────────────────
  ConstructionPhase(
    name: 'Labour Master',
    activities: [
      _a('Labour Master', 'General', 'Mason'),
      _a('Labour Master', 'General', 'Helper'),
      _a('Labour Master', 'General', 'Carpenter'),
      _a('Labour Master', 'General', 'Bar Bender'),
      _a('Labour Master', 'General', 'Electrician'),
      _a('Labour Master', 'General', 'Plumber'),
      _a('Labour Master', 'General', 'Painter'),
      _a('Labour Master', 'General', 'Tile Worker'),
      _a('Labour Master', 'General', 'Fabricator'),
      _a('Labour Master', 'General', 'Welder'),
      _a('Labour Master', 'General', 'False Ceiling Worker'),
      _a('Labour Master', 'General', 'Interior Worker'),
    ],
  ),

  // ── 9. EQUIPMENT MASTER ───────────────────────────────────────────────
  ConstructionPhase(
    name: 'Equipment Master',
    activities: [
      _a('Equipment Master', 'General', 'JCB'),
      _a('Equipment Master', 'General', 'Tractor'),
      _a('Equipment Master', 'General', 'Concrete Mixer'),
      _a('Equipment Master', 'General', 'Vibrator'),
      _a('Equipment Master', 'General', 'Plate Compactor'),
      _a('Equipment Master', 'General', 'Monkey Rammer'),
      _a('Equipment Master', 'General', 'Scaffolding'),
      _a('Equipment Master', 'General', 'Cutting Machine'),
      _a('Equipment Master', 'General', 'Welding Machine'),
      _a('Equipment Master', 'General', 'Water Tanker'),
    ],
  ),
];
