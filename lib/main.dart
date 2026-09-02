import 'package:flutter/material.dart';
import 'app.dart';
import 'src/di/di.dart' as di;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.setupGetIt();
  runApp(const App());
}
