import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/controller/nav_controller.dart';
import 'package:buildtrack_mobile/screen/add_entry.dart';
import 'package:buildtrack_mobile/screen/add_equipment.dart';
import 'package:buildtrack_mobile/screen/add_labour.dart';
import 'package:buildtrack_mobile/screen/add_material.dart';
import 'package:buildtrack_mobile/screen/create_workspace.dart';
import 'package:buildtrack_mobile/screen/edit_profile.dart';
import 'package:buildtrack_mobile/screen/entry_details.dart';
import 'package:buildtrack_mobile/screen/forget_password.dart';
import 'package:buildtrack_mobile/screen/homescreen.dart';
import 'package:buildtrack_mobile/screen/inventory.dart';
import 'package:buildtrack_mobile/screen/login.dart';
import 'package:buildtrack_mobile/screen/material_history.dart';
import 'package:buildtrack_mobile/screen/notification.dart';
import 'package:buildtrack_mobile/screen/profile.dart';
import 'package:buildtrack_mobile/screen/projectscreen.dart';
import 'package:buildtrack_mobile/screen/receipt_viewer.dart';
import 'package:buildtrack_mobile/screen/report.dart';
import 'package:buildtrack_mobile/screen/review_equipment.dart';
import 'package:buildtrack_mobile/screen/review_labour.dart';
import 'package:buildtrack_mobile/screen/review_material.dart';
import 'package:buildtrack_mobile/screen/transaction_log.dart';
import 'package:buildtrack_mobile/screen/updated_progress.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    // ── Single ChangeNotifierProvider for NavController ──────────────────
    ChangeNotifierProvider(
      create: (_) => NavController(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BuildTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // ── Initial screen ────────────────────────────────────────────────
      initialRoute: '/',

      // ── Named route table ─────────────────────────────────────────────
      routes: {
        // ── Auth flow ────────────────────────────────────────────────────
        '/':                 (_) => const LoginScreen(),
        '/login':            (_) => const LoginScreen(),
        '/forgot-password':  (_) => const ForgotPasswordScreen(),
        '/create-workspace': (_) => const CreateWorkspaceScreen(),
        '/profile':          (_) => const ProfileScreen(),
        '/edit-profile':     (_) => const EditProfileScreen(),

        // ── Main tabs ────────────────────────────────────────────────────
        '/home':      (_) => const HomeScreen(),
        '/projects':  (_) => const ProjectsScreen(),
        '/add-entry': (_) => const AddEntryScreen(),
        '/inventory': (_) => const InventoryScreen(),
        '/reports':   (_) => const ReportsScreen(),

        // ── Sub-screens ──────────────────────────────────────────────────
        '/notifications':   (_) => const NotificationsScreen(),
        '/logs':            (_) => const TransactionLogsScreen(),
        '/entry-detail':    (_) => const EntryDetailScreen(),
        '/update-progress': (_) => const UpdateProgressScreen(),
        '/cement-history':  (_) => const CementHistoryScreen(),
        '/receipt-viewer':  (_) => const ReceiptViewerScreen(),

        // ── Voice review screens ──────────────────────────────────────────
        '/review-material':  (_) => const ReviewVoiceEntryScreen(),
        '/review-labour':    (_) => const ReviewLabourEntryScreen(),
        '/review-equipment': (_) => const ReviewEquipmentEntryScreen(),

        // ── Manual entry forms ────────────────────────────────────────────
        '/add-material':  (_) => const AddMaterialScreen(),
        '/add-labour':    (_) => const AddLabourScreen(),
        '/add-equipment': (_) => const AddEquipmentScreen(),
      },
    );
  }
}
