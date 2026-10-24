import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/theme.dart';
import 'app/routes.dart';

void main() {
  runApp(
    // ProviderScope é obrigatório para o Riverpod funcionar
    const ProviderScope(
      child: FarmaciaFacilApp(),
    ),
  );
}

class FarmaciaFacilApp extends StatelessWidget {
  const FarmaciaFacilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Farmácia Fácil',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
