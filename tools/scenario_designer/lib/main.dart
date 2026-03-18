import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'service_locator.dart';
import 'services/database_service.dart';
import 'screens/designer/designer_tool_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize FFI for macOS desktop (direct disk DB access)
  if (!kIsWeb) {
    DatabaseService.initFfi();
  }
  setupServiceLocator();
  runApp(const ScenarioEditorApp());
}

class ScenarioEditorApp extends StatelessWidget {
  const ScenarioEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OB3 Scenario Editor',
      theme: ThemeData.dark(),
      home: const DesignerToolScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
