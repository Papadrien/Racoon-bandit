import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  imageCache.maximumSize = 200;
  imageCache.maximumSizeBytes = 150 << 20;

  runApp(const RaccoonBanditApp());
}
