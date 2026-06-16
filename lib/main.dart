import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/controller/nav_controller.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/controller/role_manager.dart';
import 'package:buildtrack_mobile/controller/subscription_provider.dart';
import 'package:buildtrack_mobile/controller/inventory_provider.dart';
import 'package:buildtrack_mobile/screen/manual_voice_entry/add_entry.dart';
import 'package:buildtrack_mobile/screen/manual_voice_entry/add_equipment.dart';
import 'package:buildtrack_mobile/screen/manual_voice_entry/add_labour.dart';
import 'package:buildtrack_mobile/screen/manual_voice_entry/add_material.dart';
import 'package:buildtrack_mobile/screen/profile/assign_role.dart';
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
import 'package:buildtrack_mobile/screen/reports/ai_chat_report_screen.dart';
import 'package:buildtrack_mobile/screen/inventory/project_report_screen.dart';
import 'package:buildtrack_mobile/screen/inventory/review_equipment.dart';
import 'package:buildtrack_mobile/screen/inventory/review_labour.dart';
import 'package:buildtrack_mobile/screen/inventory/review_material.dart';
import 'package:buildtrack_mobile/screen/profile/subscription_screen.dart';
import 'package:buildtrack_mobile/screen/inventory/transaction_log.dart';
import 'package:buildtrack_mobile/screen/manual_voice_entry/updated_progress.dart';
import 'dart:async';
import 'package:buildtrack_mobile/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildtrack_mobile/controller/user_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buildtrack_mobile/controller/subscription_provider.dart';
import 'package:buildtrack_mobile/screen/profile/payment_webview_screen.dart';

void main() {
  runZonedGuarded(() async {
    debugPrint('App Started');

    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('Flutter Initialized');

    // Load session first so UserSession singleton is populated
    await UserSession.loadFromPrefs();

    // Check if already logged in
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final isLoggedIn = token != null && token.isNotEmpty;

    final projectProvider = ProjectProvider();

    // Only load projects if already logged in (token exists)
    if (isLoggedIn) {
      debugPrint('API Initialized: Endpoint is ${ApiService.baseUrl}');
      await projectProvider.load().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('[main] projectProvider.load timed out after 10s');
        },
      );
    } else {
      debugPrint('API Initialized: Endpoint is ${ApiService.baseUrl} (not logged in)');
    }

    debugPrint('Providers Initialized');

    runApp(
      MultiProvider(
        providers: [
          // ✅ KEY FIX: Register UserSession as a ChangeNotifierProvider
          // so context.watch<UserSession>() works throughout the app.
          // Using .value because UserSession is a singleton — we pass the
          // same instance that loadFromPrefs() already called notifyListeners() on.
          ChangeNotifierProvider<UserSession>.value(value: UserSession()),

          ChangeNotifierProvider(create: (_) => NavController()),
          ChangeNotifierProvider.value(value: projectProvider),
          ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
          ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ],
        child: MyApp(isLoggedIn: isLoggedIn),
      ),
    );
  }, (error, stack) {
    debugPrint('[Uncaught Exception] Error: $error\n$stack');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.isLoggedIn});

  final bool isLoggedIn;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BuildTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Go to home if already logged in, login otherwise
      initialRoute: isLoggedIn ? '/home' : '/',
      onGenerateInitialRoutes: (initialRouteName) {
        debugPrint('Navigation Started');
        return [
          MaterialPageRoute(
            settings: RouteSettings(name: initialRouteName),
            builder: (context) {
              if (initialRouteName == '/home') {
                return const HomeScreen();
              }
              return const LoginScreen();
            },
          ),
        ];
      },
      routes: {
        '/':                 (_) => const LoginScreen(),
        '/login':            (_) => const LoginScreen(),
        '/forgot-password':  (_) => const ForgotPasswordScreen(),
        '/create-workspace': (_) => const CreateWorkspaceScreen(),
        '/profile':          (_) => const ProfileScreen(),
        '/edit-profile':     (_) => const EditProfileScreen(),
        '/subscription':     (_) => const SubscriptionScreen(),
        '/payment-webview': (context) => const PaymentWebViewScreen(paymentParams: const {}),
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
        '/ai-chat':         (_) => const AiChatReportScreen(),
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