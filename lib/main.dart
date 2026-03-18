import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DroneCommanderApp.configureSystemUI();
  runApp(const DroneCommanderApp());
}

