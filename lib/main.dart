import 'package:flutter/material.dart';

import 'app/app.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService().init();
  runApp(LogisticsApp());
}
