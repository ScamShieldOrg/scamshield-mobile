import 'package:flutter/widgets.dart';
import 'package:scamshield_mobile/app/app.dart';
import 'package:scamshield_mobile/core/config/api_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.load();
  runApp(const ScamShieldApp());
}
