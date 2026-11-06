import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/services/cloud_sync_service.dart';
import 'core/services/tracker_service.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set dark status bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF161512),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize persistent tracker & cloud sync services
  await TrackerService.instance.init();
  await CloudSyncService.instance.init();

  runApp(const VaibhavAcademicApp());
}

class VaibhavAcademicApp extends StatelessWidget {
  const VaibhavAcademicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IIT JAM & CUET-PG Academic Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainShell(),
    );
  }
}
