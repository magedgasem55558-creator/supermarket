import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/auth_providers.dart';
import 'features/auth/presentation/login_page.dart';
import 'services/database_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  final database = container.read(databaseProvider);

  final initializer = DatabaseInitializer(
    database: database,
    passwordService: container.read(passwordServiceProvider),
  );

  await initializer.initialize();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SupermarketApp(),
    ),
  );
}

class SupermarketApp extends StatelessWidget {
  const SupermarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Supermarket',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}