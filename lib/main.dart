import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/controller/nav_controller.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/controller/role_manager.dart';
import 'package:buildtrack_mobile/controller/subscription_provider.dart';
import 'package:buildtrack_mobile/screen/manual_voice_entry/add_entry.dart';
import 'package:buildtrack_mobile/screen/manual_voice_entry/add_equipment.dart';
import 'package:buildtrack_mobile/screen/manual_voice_entry/add_labour.dart';
import 'package:buildtrack_mobile/screen/manual_voice_entry/add_material.dart';
import 'package:buildtrack_mobile/screen/manual_voice_entry/assign_role.dart';
import 'package:buildtrack_mobile/pages/create_workspace.dart';
import 'package:buildtrack_mobile/screen/profile/edit_profile.dart';
import 'package:buildtrack_mobile/screen/manual_voice_entry/entry_details.dart';
import 'package:buildtrack_mobile/screen/profile/forget_password.dart';
import 'package:buildtrack_mobile/screen/dashboard/homescreen.dart';
import 'package:buildtrack_mobile/screen/inventory/inventory.dart';
import 'package:buildtrack_mobile/pages/login.dart';
import 'package:buildtrack_mobile/screen/inventory/material_history.dart';
import 'package:buildtrack_mobile/screen/dashboard/notification.dart';
import 'package:buildtrack_mobile/screen/profile/profile.dart';
import 'package:buildtrack_mobile/screen/projects/project_detail.dart';
import 'package:buildtrack_mobile/screen/projects/projectscreen.dart';
import 'package:buildtrack_mobile/screen/inventory/receipt_viewer.dart';
import 'package:buildtrack_mobile/screen/reports/report.dart';
import 'package:buildtrack_mobile/screen/reports/report_insights_screen.dart';
import 'package:buildtrack_mobile/screen/inventory/project_report_screen.dart';
import 'package:buildtrack_mobile/screen/inventory/review_equipment.dart';
import 'package:buildtrack_mobile/screen/inventory/review_labour.dart';
import 'package:buildtrack_mobile/screen/inventory/review_material.dart';
import 'package:buildtrack_mobile/screen/profile/subscription_screen.dart';
import 'package:buildtrack_mobile/screen/inventory/transaction_log.dart';
import 'package:buildtrack_mobile/screen/manual_voice_entry/updated_progress.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final projectProvider = ProjectProvider();
  await projectProvider.load();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavController()),
        ChangeNotifierProvider.value(value: projectProvider),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ],
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
      initialRoute: '/',
      routes: {
        '/':                 (_) => const LoginScreen(),
        '/login':            (_) => const LoginScreen(),
        '/forgot-password':  (_) => const ForgotPasswordScreen(),
        '/create-workspace': (_) => const CreateWorkspaceScreen(),
        '/profile':          (_) => const ProfileScreen(),
        '/edit-profile':     (_) => const EditProfileScreen(),
        '/subscription':     (_) => const SubscriptionScreen(),

        '/home':        (_) => const HomeScreen(),
        '/projects':    (_) => const ProjectsScreen(),
        '/add-entry':   (_) => const AddEntryScreen(),
        '/inventory':   (_) => const InventoryScreen(),
        '/reports':     (_) => const ReportsScreen(),
        '/assign-role': (_) => const AssignRoleScreen(),

        '/project-detail': (_) => const ProjectDetailScreen(),

        '/notifications':   (_) => const NotificationsScreen(),
        '/logs':            (_) => const TransactionLogsScreen(),
        '/entry-detail':    (_) => const EntryDetailScreen(),
        '/update-progress': (_) => const UpdateProgressScreen(),
        '/report-insights': (_) => const ReportInsightsScreen(),
        '/project-report':  (_) => const ProjectReportScreen(),
        '/cement-history':  (_) => const CementHistoryScreen(),
        '/receipt-viewer':  (_) => const ReceiptViewerScreen(),

        '/review-material':  (_) => const ReviewVoiceEntryScreen(),
        '/review-labour':    (_) => const ReviewLabourEntryScreen(),
        '/review-equipment': (_) => const ReviewEquipmentEntryScreen(),

        '/add-material':  (_) => const AddMaterialScreen(),
        '/add-labour':    (_) => const AddLabourScreen(),
        '/add-equipment': (_) => const AddEquipmentScreen(),
      },

      onGenerateRoute: (settings) {
        final name = settings.name ?? '';
        if (!RoleManager.canNavigate(name)) {
          return MaterialPageRoute(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'You do not have permission to access this feature.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: Colors.red.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                    duration: const Duration(seconds: 2),
                  ),
                );
                Navigator.pop(context);
              });
              return const Scaffold(body: SizedBox.shrink());
            },
          );
        }
        return null;
      },
    );
  }
}
