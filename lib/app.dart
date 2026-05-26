import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/clip_provider.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';

class ClippedApp extends StatelessWidget {
  const ClippedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClipProvider()..initialize(),
      child: MaterialApp(
        title: 'Clipped',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const Scaffold(
          backgroundColor: Colors.transparent,
          body: MainScreen(),
        ),
      ),
    );
  }
}
