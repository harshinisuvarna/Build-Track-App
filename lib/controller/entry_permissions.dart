import 'package:buildtrack_mobile/controller/entry_model.dart';
import 'package:buildtrack_mobile/controller/user_session.dart';

/// Centralised permission checks for entries.
///
/// Usage:
///   if (EntryPermissions.canEdit(status: 'pending', createdBy: 'u1', projectId: 'p1')) { ... }
class EntryPermissions {
  EntryPermissions._();

  /// Whether the current user may edit this entry.
  ///
  /// Rules (in priority order):
  /// 1. Approved entries → NO ONE can edit.
  /// 2. Admin → can edit ANY non-approved entry.
  /// 3. Supervisor → only if entry.projectId matches their project.
  /// 4. Mason → only if they created the entry.
  static bool canEdit({
    required String status,
    required String createdBy,
    required String projectId,
  }) {
    // Rule 1: approved → locked
    if (status == 'approved') return false;

    // Rule 2: Admin → full access
    if (UserSession.isAdmin) return true;

    // Rule 3: Supervisor → same project only
    if (UserSession.isSupervisor) {
      return projectId == UserSession.projectId;
    }

    // Rule 4: Mason → own entries only
    if (UserSession.isMason) {
      return createdBy == UserSession.userId;
    }

    return false;
  }

  /// Whether the current user may delete this entry.
  /// Same rules as edit for now.
  static bool canDelete({
    required String status,
    required String createdBy,
    required String projectId,
  }) {
    return canEdit(
      status: status,
      createdBy: createdBy,
      projectId: projectId,
    );
  }

  /// Whether the current user may approve/reject this entry.
  static bool canApprove() {
    return UserSession.isAdmin || UserSession.isSupervisor;
  }

  // ── Visibility / Filtering ──────────────────────────────────────────────

  /// Whether the current user may see this entry.
  ///
  /// Rules:
  /// 1. Admin → sees everything.
  /// 2. Supervisor → same projectId only.
  /// 3. Mason → own entries only.
  static bool canView({
    required String createdBy,
    required String projectId,
  }) {
    if (UserSession.isAdmin) return true;
    if (UserSession.isSupervisor) return projectId == UserSession.projectId;
    if (UserSession.isMason) return createdBy == UserSession.userId;
    return false;
  }

  /// Filters a list of [Entry] objects by role-based visibility.
  static List<Entry> filterEntries(List<Entry> entries) {
    if (UserSession.isAdmin) return entries;
    return entries.where((e) => canView(
      createdBy: e.createdBy,
      projectId: e.projectId,
    )).toList();
  }

  /// Filters a list of Maps (used by screens that pass raw maps as args).
  static List<Map<String, dynamic>> filterMaps(List<Map<String, dynamic>> entries) {
    if (UserSession.isAdmin) return entries;
    return entries.where((e) => canView(
      createdBy: e['createdBy'] as String? ?? '',
      projectId: e['projectId'] as String? ?? '',
    )).toList();
  }
}
