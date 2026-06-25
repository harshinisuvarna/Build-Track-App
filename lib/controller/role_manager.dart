import 'package:buildtrack_mobile/controller/user_session.dart';

/// Single source of truth for what the current user can do.
/// Admin always passes every check.
/// Supervisor/Mason pass only if the admin granted them that permission.
class RoleManager {
  RoleManager._();

  // ── Role shortcuts ─────────────────────────────────────
  static bool get isAdmin => UserSession.isAdmin;
  static bool get isSupervisor => UserSession.isSupervisor;
  static bool get isMason => UserSession.isMason;

  // ═══════════════════════════════════════════════════════
  // PROJECT MANAGEMENT
  // ═══════════════════════════════════════════════════════

  /// Can create a new project
  static bool get canCreateProject =>
      isAdmin || UserSession.hasPermission('create_project');

  /// Can edit existing project details, budget, dates etc.
  static bool get canEditProject =>
      isAdmin || UserSession.hasPermission('edit_project');

  /// Can delete a project
  static bool get canDeleteProject =>
      isAdmin || UserSession.hasPermission('delete_project');

  /// Can see all projects in the workspace (admin view)
  static bool get canViewAllProjects =>
      isAdmin || UserSession.hasPermission('view_all_projects');

  /// Can see the project(s) they are assigned to
  static bool get canViewAssignedProject =>
      UserSession.hasPermission('view_assigned_project') ||
      UserSession.hasPermission('view_projects'); // legacy key

  /// Generic "can view projects" — true for any project visibility
  static bool get canViewProjects =>
      isAdmin || canViewAllProjects || canViewAssignedProject;

  // ═══════════════════════════════════════════════════════
  // BUILDING STRUCTURE MANAGEMENT (admin-level config)
  // ═══════════════════════════════════════════════════════

  static bool get canManageBuildingType =>
      isAdmin || UserSession.hasPermission('manage_building_type');

  static bool get canManageFloors =>
      isAdmin || UserSession.hasPermission('manage_floors');

  static bool get canManagePhases =>
      isAdmin || UserSession.hasPermission('manage_phases');

  static bool get canManageActivities =>
      isAdmin || UserSession.hasPermission('manage_activities');

  static bool get canManageChecklists =>
      isAdmin || UserSession.hasPermission('manage_checklists');

  // ═══════════════════════════════════════════════════════
  // USER & TEAM MANAGEMENT
  // ═══════════════════════════════════════════════════════

  static bool get canManageContractors =>
      isAdmin || UserSession.hasPermission('manage_contractors');

  static bool get canManageUsers =>
      isAdmin || UserSession.hasPermission('manage_users');

  static bool get canAssignRoles =>
      isAdmin || UserSession.hasPermission('assign_roles');

  static bool get canAssignProject =>
      isAdmin || UserSession.hasPermission('assign_project');

  // Legacy alias used in home_screen.dart drawer
  static bool get canAssignRole => canAssignRoles;

  /// Can manage team — legacy key used in project creation routes
  static bool get canManageTeam =>
      isAdmin || UserSession.hasPermission('manage_team');

  // ═══════════════════════════════════════════════════════
  // DAILY WORK SUBMISSION (Mason & Supervisor)
  // ═══════════════════════════════════════════════════════

  /// Can submit a daily progress update
  static bool get canSubmitDailyUpdate =>
      UserSession.hasPermission('submit_daily_update') ||
      UserSession.hasPermission('add_entries'); // legacy key

  /// Can upload before/during/after photos
  static bool get canUploadPhotos =>
      UserSession.hasPermission('upload_photos') ||
      UserSession.hasPermission('add_entries'); // legacy key

  /// Can upload videos
  static bool get canUploadVideos => UserSession.hasPermission('upload_videos');

  /// Can tick off checklist items in a submission
  static bool get canSubmitChecklist =>
      UserSession.hasPermission('submit_checklist') ||
      UserSession.hasPermission('add_entries'); // legacy key

  /// Can flag an issue on the site
  static bool get canReportIssue =>
      UserSession.hasPermission('report_issue') ||
      UserSession.hasPermission('add_entries'); // legacy key

  /// Can log a delay with reason and days
  static bool get canReportDelay =>
      UserSession.hasPermission('report_delay') ||
      UserSession.hasPermission('add_entries'); // legacy key

  /// Generic "can add entries" — covers daily updates, material, labour, equipment
  static bool get canAddEntries =>
      isAdmin ||
      canSubmitDailyUpdate ||
      UserSession.hasPermission('add_entries');

  // ═══════════════════════════════════════════════════════
  // APPROVAL / VERIFICATION (Supervisor)
  // ═══════════════════════════════════════════════════════

  /// Can approve a mason's submitted update
  static bool get canApproveUpdates =>
      isAdmin ||
      UserSession.hasPermission('approve_updates') ||
      UserSession.hasPermission('approve_payments'); // legacy key

  /// Can reject a submission with a reason/comment
  static bool get canRejectUpdates =>
      isAdmin ||
      UserSession.hasPermission('reject_updates') ||
      UserSession.hasPermission('approve_payments'); // legacy key

  /// Can add quality/site remarks to an update
  static bool get canAddSupervisorRemarks =>
      isAdmin || UserSession.hasPermission('add_supervisor_remarks');

  /// Legacy alias used in home_screen.dart
  static bool get canApprovePayments =>
      isAdmin ||
      UserSession.hasPermission('approve_payments') ||
      canApproveUpdates;

  // ═══════════════════════════════════════════════════════
  // DASHBOARDS & MONITORING
  // ═══════════════════════════════════════════════════════

  static bool get canViewProgressDashboard =>
      isAdmin ||
      UserSession.hasPermission('view_progress_dashboard') ||
      UserSession.hasPermission('view_projects'); // legacy key

  static bool get canViewIssueTracker =>
      isAdmin || UserSession.hasPermission('view_issue_tracker');

  static bool get canViewDelayTracker =>
      isAdmin || UserSession.hasPermission('view_delay_tracker');

  static bool get canViewMediaGallery =>
      isAdmin || UserSession.hasPermission('view_media_gallery');

  static bool get canViewReports =>
      isAdmin || UserSession.hasPermission('view_reports');

  // ═══════════════════════════════════════════════════════
  // EXPENSES & PAYMENTS
  // ═══════════════════════════════════════════════════════

  static bool get canManageExpenses =>
      isAdmin || UserSession.hasPermission('manage_expenses');

  static bool get canMarkPaid =>
      isAdmin || UserSession.hasPermission('mark_paid');

  static bool get canViewPaymentReports =>
      isAdmin ||
      UserSession.hasPermission('view_payment_reports') ||
      UserSession.hasPermission('view_reports');

  // ═══════════════════════════════════════════════════════
  // DOCUMENTS
  // ═══════════════════════════════════════════════════════

  static bool get canUploadDocuments =>
      isAdmin || UserSession.hasPermission('upload_documents');

  static bool get canViewDocuments =>
      isAdmin || UserSession.hasPermission('view_documents');

  // ═══════════════════════════════════════════════════════
  // MASTER DATA
  // ═══════════════════════════════════════════════════════

  static bool get canManageMaterialMaster =>
      isAdmin || UserSession.hasPermission('manage_material_master');

  static bool get canManageLabourMaster =>
      isAdmin || UserSession.hasPermission('manage_labour_master');

  static bool get canManageEquipmentMaster =>
      isAdmin || UserSession.hasPermission('manage_equipment_master');

  /// Legacy alias — covers material/labour/equipment master
  static bool get canManageInventory =>
      isAdmin ||
      canManageMaterialMaster ||
      canManageLabourMaster ||
      canManageEquipmentMaster;

  // ═══════════════════════════════════════════════════════
  // CONTRACTOR PERFORMANCE
  // ═══════════════════════════════════════════════════════

  static bool get canViewContractorPerformance =>
      isAdmin || UserSession.hasPermission('view_contractor_performance');

  // ═══════════════════════════════════════════════════════
  // ALWAYS-ON PERMISSIONS
  // ═══════════════════════════════════════════════════════

  static bool get canViewNotifications => true;
  static bool get canEditProfile => true;

  // ═══════════════════════════════════════════════════════
  // COMPOUND CONVENIENCE GETTERS (used in home_screen etc.)
  // ═══════════════════════════════════════════════════════

  static bool get canDeleteEntries => isAdmin || canApprovePayments;
  static bool get canApproveEntries => isAdmin || canApprovePayments;
  static bool get canUpdateProgress => canAddEntries;
  static bool get canViewTeamAccess => isAdmin;

  // ═══════════════════════════════════════════════════════
  // ROUTE GUARD
  // ═══════════════════════════════════════════════════════

  static const _restrictedRoutes = <String, bool Function()>{
    '/assign-role': _checkAssignRole,
    '/reports': _checkReports,
    '/create-workspace': _checkAdmin,
    '/logs': _checkLogs,
  };

  static bool _checkAssignRole() => canAssignRoles;
  static bool _checkReports() => canViewReports;
  static bool _checkAdmin() => isAdmin;
  static bool _checkLogs() => isAdmin || canViewReports;

  static bool canNavigate(String route) {
    final check = _restrictedRoutes[route];
    if (check == null) return true;
    return check();
  }
}
