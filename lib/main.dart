import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/storage_provider.dart';
import 'providers/history_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize providers
  final themeProvider = ThemeProvider();
  await themeProvider.initialize();
  
  final storageProvider = StorageProvider();
  await storageProvider.initialize();
  
  final historyProvider = HistoryProvider();
  await historyProvider.loadHistory();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: storageProvider),
        ChangeNotifierProvider.value(value: historyProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'ToolBox Pro',
      debugShowCheckedModeBanner: false,
      
      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      
      // Main app
      home: const App(),
    );
  }
}
